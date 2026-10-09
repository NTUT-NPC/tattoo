import 'dart:async';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/models/campus_map.dart';
import 'package:tattoo/repositories/campus_map_building_overrides.dart';
import 'package:tattoo/services/demo_mode.dart';
import 'package:tattoo/services/map/campus_map_service.dart';

/// Provides the app-scoped public map cache, isolated from local demo data.
final campusMapRepositoryProvider = Provider<CampusMapRepository>((ref) {
  final isDemo = ref.watch(isDemoProvider);
  final database = isDemo
      ? AppDatabase(NativeDatabase.memory())
      : ref.watch(databaseProvider);
  if (isDemo) ref.onDispose(database.close);
  return CampusMapRepository(
    service: ref.watch(campusMapServiceProvider),
    database: database,
  );
});

/// Caches building outlines, indoor floors, and a metadata-only search index.
///
/// A geometry request fetches exactly one building-floor layer. Search loads
/// names and numbers across published layers only when first used, preserving
/// previously downloaded polygons. All dataset changes commit atomically.
class CampusMapRepository {
  /// Creates a repository with framework-independent [service] and [database].
  CampusMapRepository({
    required this._service,
    required AppDatabase database,
    DateTime Function()? now,
  }) : _db = database,
       _now = now ?? DateTime.now;

  final CampusMapService _service;
  final AppDatabase _db;
  final DateTime Function() _now;
  final Map<String, Future<void>> _inFlight = {};
  final Map<String, int> _floorRevisions = {};
  static const _namespace = 'campus';
  static const _cacheTtl = Duration(days: 14);

  Future<MapSyncRecord?> _sync() => (_db.select(
    _db.campusMapSyncs,
  )..where((table) => table.namespace.equals(_namespace))).getSingleOrNull();

  /// Watches building outlines with their own available floors from Drift.
  ///
  /// Cached data emits immediately. A missing or 14-day-old catalog refreshes
  /// once per subscription; failures retain stale data or emit an empty catalog
  /// for the screen's retry state.
  /// A6T and HR use bundled first-floor outline corrections, including when
  /// reading a catalog cached before these corrections were introduced.
  Stream<List<CampusMapBuilding>> watchBuildings() async* {
    var attempted = false;
    final query = _db.select(_db.campusMapBuildings).join([
      leftOuterJoin(
        _db.campusMapFloors,
        _db.campusMapFloors.building.equalsExp(_db.campusMapBuildings.code),
      ),
    ]);
    await for (final rows in query.watch()) {
      final stamp = (await _sync())?.catalogFetchedAt;
      if (stamp == null && !attempted) {
        attempted = true;
        try {
          await refreshBuildings();
          continue;
        } catch (_) {
          // An empty snapshot exposes the cold-load retry UI.
        }
      }
      final floors = <String, List<CampusMapFloor>>{};
      final buildings = <String, MapBuildingRecord>{};
      for (final row in rows) {
        final building = row.readTable(_db.campusMapBuildings);
        buildings[building.code] = building;
        if (row.readTableOrNull(_db.campusMapFloors) case final floor?) {
          floors
              .putIfAbsent(building.code, () => [])
              .add(
                CampusMapFloor(layerName: floor.layerName, code: floor.code),
              );
        }
      }
      yield [
        for (final building in buildings.values)
          CampusMapBuilding(
            code: building.code,
            name:
                campusMapBuildingOverrides[building.code]?.name ??
                building.name,
            polygons: decodeCampusMapGeometry(
              campusMapBuildingOverrides[building.code]?.geometry ??
                  building.geometry,
            ),
            floors: (floors[building.code] ?? [])
              ..sort((a, b) => a.order.compareTo(b.order)),
          ),
      ]..sort((a, b) => a.name.compareTo(b.name));
      if (!attempted &&
          (stamp == null || _now().difference(stamp) >= _cacheTtl)) {
        attempted = true;
        try {
          await refreshBuildings();
        } catch (_) {
          // Keep the catalog already emitted above.
        }
      }
    }
  }

  /// Fetches building and layer catalogs atomically without deleting room cache.
  ///
  /// Layers removed upstream are deleted with their dependent rooms. A changed
  /// layer catalog invalidates search completeness until the next search.
  /// Network errors propagate and leave the previous catalog intact.
  Future<void> refreshBuildings() => _coalesce('catalog', () async {
    final outlines = await _service.getBuildings();
    final layers = await _service.getLayers();
    if (outlines.isEmpty || layers.isEmpty) {
      throw const FormatException('Empty campus map catalog');
    }
    final previous = await _db.select(_db.campusMapFloors).get();
    final before = previous.map((floor) => floor.layerName).toSet();
    final after = layers.map((layer) => layer.name).toSet();
    final catalogChanged =
        before.length != after.length || !before.containsAll(after);
    final buildings = <String, CampusMapBuildingsCompanion>{};
    for (final outline in outlines) {
      final code = outline.code.isEmpty ? outline.id : outline.code;
      buildings[code] = CampusMapBuildingsCompanion.insert(
        code: code,
        name: outline.name.isEmpty ? code : outline.name,
        geometry: encodeCampusMapGeometry(_polygons(outline.polygons)),
      );
    }
    // Some published layers belong to buildings absent from the outline layer.
    // They stay selectable and searchable instead of silently disappearing.
    for (final layer in layers) {
      buildings.putIfAbsent(
        layer.buildingCode,
        () => CampusMapBuildingsCompanion.insert(
          code: layer.buildingCode,
          name: layer.buildingCode,
          geometry: '[]',
        ),
      );
    }
    await _db.transaction(() async {
      await _db.batch((batch) {
        batch.insertAllOnConflictUpdate(
          _db.campusMapBuildings,
          buildings.values.toList(),
        );
        batch.insertAllOnConflictUpdate(_db.campusMapFloors, [
          for (final layer in layers)
            CampusMapFloorsCompanion.insert(
              layerName: layer.name,
              building: layer.buildingCode,
              code: layer.floor,
            ),
        ]);
      });
      await (_db.delete(
        _db.campusMapFloors,
      )..where((floor) => floor.layerName.isNotIn(after))).go();
      await (_db.delete(
        _db.campusMapBuildings,
      )..where((building) => building.code.isNotIn(buildings.keys))).go();
      await _db
          .into(_db.campusMapSyncs)
          .insertOnConflictUpdate(
            CampusMapSyncsCompanion.insert(
              namespace: _namespace,
              catalogFetchedAt: Value(_now()),
              indexFetchedAt: catalogChanged
                  ? const Value(null)
                  : const Value.absent(),
            ),
          );
    });
  });

  /// Watches cached geometry for one published [layerName].
  ///
  /// A missing or 14-day-old floor refreshes once per subscription. Errors retain
  /// cached spaces; [CampusMapFloorData.hasCache] distinguishes an empty floor
  /// from a failed first load. Other buildings and floors are never fetched.
  Stream<CampusMapFloorData> watchFloor(String layerName) {
    var attempted = false;
    final query = _db.select(_db.campusMapFloors).join([
      innerJoin(
        _db.campusMapBuildings,
        _db.campusMapBuildings.code.equalsExp(_db.campusMapFloors.building),
      ),
      leftOuterJoin(
        _db.campusMapRooms,
        _db.campusMapRooms.layerName.equalsExp(_db.campusMapFloors.layerName),
      ),
    ])..where(_db.campusMapFloors.layerName.equals(layerName));
    List<(MapFloorRecord, MapBuildingRecord, MapRoomRecord?)> snapshot(
      List<TypedResult> rows,
    ) => [
      for (final row in rows)
        (
          row.readTable(_db.campusMapFloors),
          row.readTable(_db.campusMapBuildings),
          row.readTableOrNull(_db.campusMapRooms),
        ),
    ];
    // Stream transforms propagate cancellation to Drift even while idle.
    // Filtering inside async* would leave an idle await-for waiting forever
    // after an unrelated-floor update was discarded.
    return query
        .watch()
        .asyncMap((rows) async {
          final floor = rows.firstOrNull?.readTable(_db.campusMapFloors);
          if (floor?.fetchedAt == null && !attempted) {
            attempted = true;
            try {
              await refreshFloor(layerName);
              return await query.get();
            } catch (_) {
              // Retain hasCache=false so the screen offers a retry.
            }
          }
          final stamp = floor?.fetchedAt;
          if (!attempted &&
              (stamp == null || _now().difference(stamp) >= _cacheTtl)) {
            attempted = true;
            unawaited(
              refreshFloor(layerName).catchError((Object _) {
                // Retain stale geometry already in this snapshot.
              }),
            );
          }
          return rows;
        })
        .distinct(
          (previous, next) =>
              const ListEquality().equals(snapshot(previous), snapshot(next)),
        )
        .map(
          (rows) => CampusMapFloorData(
            rooms: [
              for (final row in rows)
                if (row.readTableOrNull(_db.campusMapRooms)?.geometry != null)
                  _room(row),
            ],
            hasCache:
                rows.firstOrNull?.readTable(_db.campusMapFloors).fetchedAt !=
                null,
          ),
        );
  }

  /// Fetches and replaces geometry for only [layerName] in one transaction.
  ///
  /// Concurrent requests for the same layer share a future, including searches
  /// that navigate to that floor. Successful empty responses are cached.
  Future<void> refreshFloor(
    String layerName,
  ) => _coalesce('floor:$layerName', () async {
    final floor = await (_db.select(
      _db.campusMapFloors,
    )..where((floor) => floor.layerName.equals(layerName))).getSingleOrNull();
    if (floor == null) {
      throw ArgumentError.value(layerName, 'layerName', 'Unknown floor');
    }
    final rooms = await _service.getRooms(layerName);
    if (rooms.any((room) => room.layerName != layerName)) {
      throw const FormatException('Response contains rooms from another floor');
    }
    await _db.transaction(() async {
      await (_db.delete(
        _db.campusMapRooms,
      )..where((room) => room.layerName.equals(layerName))).go();
      await _db.batch(
        (batch) => batch.insertAll(_db.campusMapRooms, [
          for (final room in rooms) _companion(room, includeGeometry: true),
        ]),
      );
      await (_db.update(
        _db.campusMapFloors,
      )..where((floor) => floor.layerName.equals(layerName))).write(
        CampusMapFloorsCompanion(fetchedAt: Value(_now())),
      );
      _floorRevisions.update(
        layerName,
        (revision) => revision + 1,
        ifAbsent: () => 1,
      );
    });
  });

  JoinedSelectStatement _roomQuery() => _db.select(_db.campusMapRooms).join([
    innerJoin(
      _db.campusMapFloors,
      _db.campusMapFloors.layerName.equalsExp(_db.campusMapRooms.layerName),
    ),
    innerJoin(
      _db.campusMapBuildings,
      _db.campusMapBuildings.code.equalsExp(_db.campusMapFloors.building),
    ),
  ]);

  CampusMapRoom _room(TypedResult result) {
    final room = result.readTable(_db.campusMapRooms);
    final floor = result.readTable(_db.campusMapFloors);
    final building = result.readTable(_db.campusMapBuildings);
    return CampusMapRoom(
      id: room.id,
      buildingCode: building.code,
      buildingName:
          campusMapBuildingOverrides[building.code]?.name ?? building.name,
      floor: CampusMapFloor(layerName: floor.layerName, code: floor.code),
      nameZh: room.nameZh,
      nameEn: room.nameEn,
      number: room.number,
      polygons: room.geometry == null
          ? const []
          : decodeCampusMapGeometry(room.geometry!),
    );
  }

  /// Searches room names, numbers, and building-qualified classroom references.
  ///
  /// The complete metadata index loads on first search and expires after 14 days.
  /// Existing complete data remains usable offline. Without a complete index,
  /// network failure propagates so a partial match cannot cause a wrong unique
  /// navigation. Exact matches take precedence over substring matches.
  Future<List<CampusMapRoom>> searchRooms(String query) async {
    final normalized = normalizeCampusMapQuery(query);
    if (normalized.isEmpty) return [];
    var stamp = (await _sync())?.indexFetchedAt;
    if (stamp == null || _now().difference(stamp) >= _cacheTtl) {
      try {
        await _refreshRoomIndex();
      } catch (_) {
        stamp = (await _sync())?.indexFetchedAt;
        if (stamp == null) rethrow;
      }
    }
    // Do not select geometry when searching thousands of lightweight rows.
    final table = _db.campusMapRooms;
    final floors = _db.campusMapFloors;
    final buildings = _db.campusMapBuildings;
    final searchQuery = _db.selectOnly(table)
      ..addColumns([
        table.id,
        table.layerName,
        table.nameZh,
        table.nameEn,
        table.number,
        floors.code,
        floors.building,
        buildings.name,
      ])
      ..join([
        innerJoin(floors, floors.layerName.equalsExp(table.layerName)),
        innerJoin(buildings, buildings.code.equalsExp(floors.building)),
      ]);
    final exact = <CampusMapRoom>[];
    final partial = <CampusMapRoom>[];
    for (final row in await searchQuery.get()) {
      final room = CampusMapRoom(
        id: row.read(table.id)!,
        buildingCode: row.read(floors.building)!,
        buildingName:
            campusMapBuildingOverrides[row.read(floors.building)!]?.name ??
            row.read(buildings.name)!,
        floor: CampusMapFloor(
          layerName: row.read(table.layerName)!,
          code: row.read(floors.code)!,
        ),
        nameZh: row.read(table.nameZh)!,
        nameEn: row.read(table.nameEn)!,
        number: row.read(table.number)!,
      );
      final candidates = [
        room.nameZh,
        room.nameEn,
        room.number,
        '${room.buildingCode}${room.number}',
        '${room.buildingName}${room.number}',
        '${room.buildingName}${room.nameZh}',
      ].where((value) => value.isNotEmpty).map(normalizeCampusMapQuery);
      if (candidates.contains(normalized)) {
        exact.add(room);
      } else if (candidates.any((value) => value.contains(normalized))) {
        partial.add(room);
      }
    }
    final matches = exact.isNotEmpty ? exact : partial;
    return matches..sort((a, b) {
      final byBuilding = a.buildingName.compareTo(b.buildingName);
      if (byBuilding != 0) return byBuilding;
      final byFloor = a.floor.order.compareTo(b.floor.order);
      return byFloor == 0 ? a.number.compareTo(b.number) : byFloor;
    });
  }

  Future<void> _refreshRoomIndex() => _coalesce('index', () async {
    if ((await _sync())?.catalogFetchedAt == null) await refreshBuildings();
    final layers = await _db.select(_db.campusMapFloors).get();
    final names = layers.map((floor) => floor.layerName).toSet();
    final revisions = Map<String, int>.of(_floorRevisions);
    final rooms = await _service.getRoomIndex(names.toList());
    if (rooms.any((room) => !names.contains(room.layerName))) {
      throw const FormatException('Search response contains an unknown floor');
    }
    await _db.transaction(() async {
      final currentFloors = await _db.select(_db.campusMapFloors).get();
      final current = currentFloors.map((floor) => floor.layerName).toSet();
      if (current.length != names.length || !current.containsAll(names)) {
        throw StateError(
          'Campus map catalog changed during search index fetch',
        );
      }
      // A floor downloaded while the metadata request was running has newer
      // room membership. Keep that complete floor instead of merging an older
      // index response over it or deleting newly discovered geometry.
      final stamps = {
        for (final floor in layers) floor.layerName: floor.fetchedAt,
      };
      final changed = {
        for (final floor in currentFloors)
          if (floor.fetchedAt != stamps[floor.layerName] ||
              _floorRevisions[floor.layerName] != revisions[floor.layerName])
            floor.layerName,
      };
      await _db.batch(
        (batch) => batch.insertAllOnConflictUpdate(_db.campusMapRooms, [
          for (final room in rooms)
            if (!changed.contains(room.layerName))
              _companion(room, includeGeometry: false),
        ]),
      );
      final idsByLayer = <String, List<String>>{};
      for (final room in rooms) {
        idsByLayer.putIfAbsent(room.layerName, () => []).add(room.id);
      }
      await _db.batch((batch) {
        for (final name in names.difference(changed)) {
          batch.deleteWhere(
            _db.campusMapRooms,
            (room) =>
                room.layerName.equals(name) &
                room.id.isNotIn(idsByLayer[name] ?? const []),
          );
        }
      });
      await _db
          .into(_db.campusMapSyncs)
          .insertOnConflictUpdate(
            CampusMapSyncsCompanion.insert(
              namespace: _namespace,
              indexFetchedAt: Value(_now()),
            ),
          );
    });
  });

  /// Fetches the owning floor if needed and resolves a search result's geometry.
  ///
  /// Returns `null` if the space disappeared upstream or has no drawable outline.
  Future<CampusMapRoom?> locateRoom(CampusMapRoom result) async {
    Future<CampusMapRoom?> cachedRoom() async {
      final row =
          await (_roomQuery()..where(_db.campusMapRooms.id.equals(result.id)))
              .getSingleOrNull();
      if (row == null) return null;
      final room = _room(row);
      return room.polygons.isEmpty ? null : room;
    }

    final cached = await cachedRoom();
    final floor =
        await (_db.select(
              _db.campusMapFloors,
            )..where((floor) => floor.layerName.equals(result.floor.layerName)))
            .getSingleOrNull();
    final stamp = floor?.fetchedAt;
    if (cached == null ||
        stamp == null ||
        _now().difference(stamp) >= _cacheTtl) {
      try {
        await refreshFloor(result.floor.layerName);
      } catch (_) {
        if (cached == null) rethrow;
        return cached;
      }
    }
    return cachedRoom();
  }

  CampusMapRoomsCompanion _companion(
    CampusMapRoomDto room, {
    required bool includeGeometry,
  }) => CampusMapRoomsCompanion.insert(
    id: room.id,
    layerName: room.layerName,
    nameZh: room.nameZh,
    nameEn: room.nameEn,
    number: room.number,
    geometry: includeGeometry
        ? Value(encodeCampusMapGeometry(_polygons(room.polygons)))
        : const Value.absent(),
  );

  List<CampusMapPolygon> _polygons(CampusMapGeometryDto geometry) => [
    for (final rings in geometry)
      CampusMapPolygon([
        for (final ring in rings)
          [
            for (final point in ring)
              (latitude: point.latitude, longitude: point.longitude),
          ],
      ]),
  ];

  Future<void> _coalesce(String key, Future<void> Function() action) {
    if (_inFlight[key] case final existing?) return existing;
    final future = Future<void>.sync(action).whenComplete(() {
      _inFlight.remove(key);
    });
    _inFlight[key] = future;
    return future;
  }
}
