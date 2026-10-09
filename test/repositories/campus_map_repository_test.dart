import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/models/campus_map.dart';
import 'package:tattoo/repositories/campus_map_repository.dart';
import 'package:tattoo/screens/main/map/campus_map_geometry.dart';
import 'package:tattoo/services/map/campus_map_service.dart';

const _layerA = 'gis_room:A1T_1F';
const _layerA2 = 'gis_room:A1T_2F';
const _layerB = 'gis_room:B2_1F';

void main() {
  group('CampusMapRepository', () {
    late AppDatabase database;
    late _FakeCampusMapService service;
    late CampusMapRepository repository;
    var clock = DateTime.utc(2026, 10, 9);

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      service = _FakeCampusMapService();
      repository = _repository(service, database, () => clock);
    });

    tearDown(() => database.close());

    test(
      'building overview discovers floors without fetching room geometry',
      () async {
        final buildings = await repository.watchBuildings().first.timeout(
          const Duration(seconds: 5),
        );

        expect(buildings.map((building) => building.code), ['A1T', 'B2']);
        expect(buildings.first.floors.map((floor) => floor.layerName), [
          _layerA,
        ]);
        expect(service.buildingCalls, 1);
        expect(service.layerCalls, 1);
        expect(service.roomCalls, isEmpty);
      },
    );

    test('refreshes geometry for only the requested building floor', () async {
      await repository.refreshBuildings();
      service.roomsByLayer[_layerA] = [_room(_layerA, '101')];

      await repository.refreshFloor(_layerA);

      expect(service.roomCalls, [_layerA]);
      expect(
        (await _floorData(repository, _layerA)).rooms.single.number,
        '101',
      );
    });

    test(
      'cached A6T and missing HR outlines resolve to distinct first-floor footprints',
      () async {
        final combined = (
          id: 'combined',
          code: 'A6T',
          name: '宏裕科技大樓/第六教學大樓',
          polygons: _geometry(121.5336, 25.0436),
        );
        service.buildings = [combined, _outline('A1T', 'Alpha Hall')];
        service.layers = [
          (name: 'gis_room:A6T_1F', buildingCode: 'A6T', floor: '1F'),
          (name: 'gis_room:HR_1F', buildingCode: 'HR', floor: '1F'),
          (name: _layerA, buildingCode: 'A1T', floor: '1F'),
        ];
        await repository.refreshBuildings();
        final source = await database.select(database.campusMapBuildings).get();
        final calls = service.buildingCalls;

        // Simulate reopening with a fresh catalog cached by an older app.
        repository = _repository(service, database, () => clock);
        final buildings = await repository.watchBuildings().first;
        final sixth = buildings.singleWhere(
          (building) => building.code == 'A6T',
        );
        final hongYu = buildings.singleWhere(
          (building) => building.code == 'HR',
        );
        expect(sixth.name, '第六教學大樓');
        expect(hongYu.name, '宏裕科技大樓');
        expect(sixth.floors.single.layerName, 'gis_room:A6T_1F');
        expect(hongYu.floors.single.layerName, 'gis_room:HR_1F');
        expect(
          buildings.singleWhere((building) => building.code == 'A1T').polygons,
          isEmpty,
        );

        List<String> hits(CampusMapPoint point) => [
          for (final building in buildings)
            if (building.polygons.any(
              (polygon) => campusMapContainsPoint(polygon, point),
            ))
              building.code,
        ];

        expect(hits((longitude: 121.5339, latitude: 25.0441)), ['HR']);
        // A point where the two upstream first-floor geometries overlap.
        expect(
          hits((longitude: 121.53393870, latitude: 25.04392151)),
          ['HR'],
        );
        expect(hits((longitude: 121.53376, latitude: 25.04385)), ['A6T']);
        expect(hits((longitude: 121.53406, latitude: 25.04377)), ['A6T']);
        expect(hits((longitude: 121.5343, latitude: 25.0441)), isEmpty);
        expect(service.buildingCalls, calls);
        expect(service.roomCalls, isEmpty);
        expect(
          await database.select(database.campusMapBuildings).get(),
          source,
        );
      },
    );

    test(
      'corrected building names also apply to search and room location',
      () async {
        service.buildings = [_outline('A6T', '宏裕科技大樓/第六教學大樓')];
        service.layers = [
          (name: 'gis_room:A6T_1F', buildingCode: 'A6T', floor: '1F'),
          (name: 'gis_room:HR_1F', buildingCode: 'HR', floor: '1F'),
        ];
        service.index = [
          _room('gis_room:A6T_1F', '101', withGeometry: false),
          _room('gis_room:HR_1F', '101', withGeometry: false),
        ];
        service.roomsByLayer['gis_room:HR_1F'] = [
          _room('gis_room:HR_1F', '101'),
        ];
        await repository.refreshBuildings();

        final hongYu = (await repository.searchRooms('宏裕科技大樓101')).single;
        final sixth = (await repository.searchRooms('第六教學大樓101')).single;
        expect(hongYu.buildingCode, 'HR');
        expect(hongYu.buildingName, '宏裕科技大樓');
        expect(sixth.buildingCode, 'A6T');
        expect(sixth.buildingName, '第六教學大樓');
        expect((await repository.locateRoom(hongYu))!.buildingName, '宏裕科技大樓');
        expect(service.roomCalls, ['gis_room:HR_1F']);
      },
    );

    test('caches a successful empty floor as fetched', () async {
      await repository.refreshBuildings();
      await repository.refreshFloor(_layerA);

      final floor = await _floorData(repository, _layerA);
      expect(floor.rooms, isEmpty);
      expect(floor.hasCache, isTrue);
      expect(service.roomCalls, [_layerA]);
      await repository.watchFloor(_layerA).first;
      expect(service.roomCalls, [_layerA]);
    });

    test(
      'visible floor stream ignores another floor update but emits its own',
      () async {
        service.layers = [
          (name: _layerA, buildingCode: 'A1T', floor: '1F'),
          (name: _layerA2, buildingCode: 'A1T', floor: '2F'),
        ];
        await repository.refreshBuildings();
        service.roomsByLayer[_layerA] = [_room(_layerA, '101')];
        await repository.refreshFloor(_layerA);
        final emissions = <CampusMapFloorData>[];
        final firstEmission = Completer<void>();
        final changedEmission = Completer<void>();
        final subscription = repository.watchFloor(_layerA).listen((floor) {
          emissions.add(floor);
          if (!firstEmission.isCompleted) firstEmission.complete();
          if (emissions.length == 2 && !changedEmission.isCompleted) {
            changedEmission.complete();
          }
        });
        await firstEmission.future.timeout(const Duration(seconds: 5));

        await repository.refreshFloor(_layerA2);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(emissions, hasLength(1));

        service.roomsByLayer[_layerA] = [_room(_layerA, '102')];
        await repository
            .refreshFloor(_layerA)
            .timeout(const Duration(seconds: 5));
        await changedEmission.future.timeout(const Duration(seconds: 5));
        expect(emissions.last.rooms.single.number, '102');
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await subscription.cancel().timeout(
          const Duration(seconds: 5),
          onTimeout: () =>
              throw StateError('idle watchFloor cancellation timed out'),
        );
      },
    );

    test(
      'watchFloor stays cached before 14 days and refreshes at the boundary',
      () async {
        await repository.refreshBuildings();
        service.roomsByLayer[_layerA] = [_room(_layerA, '101')];
        await repository.refreshFloor(_layerA);
        clock = clock.add(const Duration(days: 13, hours: 23, minutes: 59));

        await _floorData(repository, _layerA);
        expect(service.roomCalls, [_layerA]);

        clock = clock.add(const Duration(minutes: 1));
        service.roomsByLayer[_layerA] = [_room(_layerA, '102')];
        final refreshed = Completer<void>();
        final subscription = repository.watchFloor(_layerA).listen((floor) {
          if (floor.rooms.any((room) => room.number == '102') &&
              !refreshed.isCompleted) {
            refreshed.complete();
          }
        });
        await refreshed.future.timeout(const Duration(seconds: 5));

        expect(service.roomCalls, [_layerA, _layerA]);
        expect(
          (await _floorData(repository, _layerA)).rooms.single.number,
          '102',
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await subscription.cancel().timeout(const Duration(seconds: 5));
      },
    );

    test('coalesces concurrent refreshes for the same layer', () async {
      await repository.refreshBuildings();
      final started = Completer<void>();
      final gate = Completer<List<CampusMapRoomDto>>();
      service.roomsHandler = (layer) {
        if (!started.isCompleted) started.complete();
        return gate.future;
      };

      final first = repository.refreshFloor(_layerA);
      final second = repository.refreshFloor(_layerA);
      await started.future.timeout(const Duration(seconds: 5));
      expect(service.roomCalls, [_layerA]);
      gate.complete([_room(_layerA, '101')]);
      await Future.wait([first, second]);

      expect(
        (await _floorData(repository, _layerA)).rooms.single.number,
        '101',
      );
    });

    test(
      'a failed floor refresh leaves cache intact and permits retry',
      () async {
        await repository.refreshBuildings();
        service.roomsByLayer[_layerA] = [_room(_layerA, '101')];
        await repository.refreshFloor(_layerA);
        final cached = (await _floorData(repository, _layerA)).rooms.single;
        var fail = true;
        service.roomsHandler = (layer) {
          if (fail) {
            fail = false;
            return Future.error(_networkError());
          }
          return Future.value([_room(layer, '102')]);
        };

        await expectLater(
          repository.refreshFloor(_layerA),
          throwsA(isA<DioException>()),
        );
        expect(
          (await _floorData(repository, _layerA)).rooms.single.number,
          cached.number,
        );
        await repository.refreshFloor(_layerA);
        expect(
          (await _floorData(repository, _layerA)).rooms.single.number,
          '102',
        );
        expect(service.roomCalls, [_layerA, _layerA, _layerA]);
      },
    );

    test(
      'cached buildings and floor geometry survive repository reconstruction',
      () async {
        await repository.refreshBuildings();
        service.roomsByLayer[_layerA] = [_room(_layerA, '101')];
        await repository.refreshFloor(_layerA);
        final replacementService = _FakeCampusMapService();
        final replacement = _repository(
          replacementService,
          database,
          () => clock,
        );

        final buildings = await replacement.watchBuildings().first;
        final floor = await _floorData(replacement, _layerA);

        expect(buildings.map((building) => building.code), ['A1T', 'B2']);
        expect(floor.rooms.single.number, '101');
        expect(replacementService.buildingCalls, 0);
        expect(replacementService.roomCalls, isEmpty);
      },
    );

    test(
      'refreshes floors independently without replacing another floor cache',
      () async {
        await repository.refreshBuildings();
        service.roomsByLayer[_layerA] = [_room(_layerA, '101')];
        service.roomsByLayer[_layerB] = [_room(_layerB, '201')];

        await repository.refreshFloor(_layerA);
        await repository.refreshFloor(_layerB);

        expect(service.roomCalls, [_layerA, _layerB]);
        expect(
          (await _floorData(repository, _layerA)).rooms.single.number,
          '101',
        );
        expect(
          (await _floorData(repository, _layerB)).rooms.single.number,
          '201',
        );
      },
    );

    test('search matches Chinese and English names, room numbers, and fullwidth input', () async {
      service.index = [
        _room(_layerA, '101', nameZh: '材料實驗室', nameEn: 'Materials Lab'),
        _room(_layerB, '２０２', nameZh: '設計教室', nameEn: 'Design Studio'),
      ];

      expect((await repository.searchRooms('材料實驗室')).single.number, '101');
      expect((await repository.searchRooms('materials')).single.number, '101');
      expect((await repository.searchRooms('２０２')).single.nameZh, '設計教室');
      expect(service.indexCalls, 1);
    });

    test('exact matches take precedence over partial matches', () async {
      service.index = [
        _room(_layerA, '101', nameZh: '101教室'),
        _room(_layerB, '101A', nameZh: '會議室'),
      ];

      final results = await repository.searchRooms('101');

      expect(results.map((room) => room.id), ['A1T_1F.101']);
    });

    test(
      'building-qualified exact queries select the matching building',
      () async {
        service.index = [
          _room(_layerA, '101', nameZh: '一般教室'),
          _room(_layerB, '101', nameZh: '一般教室'),
        ];

        final results = await repository.searchRooms('B2 101');

        expect(results.map((room) => room.id), ['B2_1F.101']);
      },
    );

    test('duplicate exact values remain multiple search results', () async {
      service.index = [
        _room(_layerA, '101', nameZh: '教室甲'),
        _room(_layerB, '101', nameZh: '教室乙'),
      ];

      final results = await repository.searchRooms('101');

      expect(results, hasLength(2));
      expect(results.map((room) => room.number), ['101', '101']);
    });

    test('an incomplete local index cannot return a seemingly unique offline match', () async {
      await repository.refreshBuildings();
      await database
          .into(database.campusMapRooms)
          .insert(
            _roomCompanion(_room(_layerA, '101', nameZh: '教室甲')),
          );
      service.indexHandler = (_) => Future.error(_networkError());

      await expectLater(
        repository.searchRooms('101'),
        throwsA(isA<DioException>()),
      );
    });

    test(
      'stale geometry remains available when the refresh request fails',
      () async {
        await repository.refreshBuildings();
        service.roomsByLayer[_layerA] = [_room(_layerA, '101')];
        await repository.refreshFloor(_layerA);
        clock = clock.add(const Duration(days: 15));
        final refreshStarted = Completer<void>();
        service.roomsHandler = (_) {
          refreshStarted.complete();
          return Future.error(_networkError());
        };

        final refresh = repository.refreshFloor(_layerA);
        await refreshStarted.future.timeout(const Duration(seconds: 5));
        await expectLater(refresh, throwsA(isA<DioException>()));

        final floor = await _floorData(repository, _layerA);
        expect(floor.hasCache, isTrue);
        expect(floor.rooms.single.number, '101');
        expect(service.roomCalls, [_layerA, _layerA]);
      },
    );

    test('stale search index remains usable when its refresh fails', () async {
      service.index = [_room(_layerA, '101', nameZh: '教室甲')];
      expect((await repository.searchRooms('教室甲')).single.number, '101');
      clock = clock.add(const Duration(days: 15));
      service.indexHandler = (_) => Future.error(_networkError());

      final results = await repository.searchRooms('101');
      expect(results.single.nameZh, '教室甲');
      expect(service.indexCalls, 2);
    });

    test('same-timestamp index response racing a floor download keeps new room geometry and membership', () async {
      await repository.refreshBuildings();
      service.roomsByLayer[_layerA] = [_room(_layerA, '101')];
      await repository.refreshFloor(_layerA);
      // Prime the floor timestamp before the metadata request. The fixed clock
      // then makes both responses share a timestamp, exercising revision guards.
      await repository.refreshFloor(_layerA);
      final indexStarted = Completer<void>();
      final indexGate = Completer<List<CampusMapRoomDto>>();
      service.indexHandler = (_) {
        indexStarted.complete();
        return indexGate.future;
      };
      final search = repository.searchRooms('教室');
      await indexStarted.future.timeout(const Duration(seconds: 5));

      final downloaded = [
        _room(_layerA, '101', nameZh: '更新教室'),
        _room(_layerA, '102', nameZh: '新增教室'),
      ];
      service.roomsByLayer[_layerA] = downloaded;
      await repository.refreshFloor(_layerA);
      indexGate.complete([_room(_layerA, '101', nameZh: '舊索引教室')]);
      await search;

      final floor = await _floorData(repository, _layerA);
      expect(floor.rooms.map((room) => room.number), ['101', '102']);
      expect(floor.rooms.every((room) => room.polygons.isNotEmpty), isTrue);
      expect(floor.rooms.first.nameZh, '更新教室');
    });

    test('locating a new indexed room fetches geometry despite a cached floor timestamp', () async {
      await repository.refreshBuildings();
      service.roomsByLayer[_layerA] = [_room(_layerA, '101')];
      await repository.refreshFloor(_layerA);
      service.index = [
        _room(_layerA, '101', withGeometry: false),
        _room(_layerA, '102', withGeometry: false, nameZh: '新教室'),
      ];
      final result = (await repository.searchRooms('102')).single;
      service.roomsByLayer[_layerA] = [
        _room(_layerA, '101'),
        _room(_layerA, '102', nameZh: '新教室'),
      ];

      final located = await repository.locateRoom(result);

      expect(located?.number, '102');
      expect(located?.polygons, isNotEmpty);
      expect(service.roomCalls, [_layerA, _layerA]);
    });

    test(
      'locateRoom returns cached geometry when stale-floor refresh is offline',
      () async {
        await repository.refreshBuildings();
        service.roomsByLayer[_layerA] = [_room(_layerA, '101')];
        await repository.refreshFloor(_layerA);
        final result = CampusMapRoom(
          id: 'A1T_1F.101',
          buildingCode: 'A1T',
          buildingName: 'Alpha Hall',
          floor: const CampusMapFloor(layerName: _layerA, code: '1F'),
          nameZh: 'Room 101',
          nameEn: 'Room 101',
          number: '101',
        );
        clock = clock.add(const Duration(days: 15));
        service.roomsHandler = (_) => Future.error(_networkError());

        final located = await repository.locateRoom(result);

        expect(located?.number, '101');
        expect(located?.polygons, isNotEmpty);
        expect(service.roomCalls, [_layerA, _layerA]);
      },
    );

    test(
      'catalog refresh is atomic when the layer catalog request fails',
      () async {
        await repository.refreshBuildings();
        final beforeBuildings = await database
            .select(database.campusMapBuildings)
            .get();
        final beforeFloors = await database
            .select(database.campusMapFloors)
            .get();
        final beforeSync = await database
            .select(database.campusMapSyncs)
            .getSingle();
        service.buildings = [_outline('C3', 'Replacement Hall')];
        service.layersHandler = () => Future.error(_networkError());

        await expectLater(
          repository.refreshBuildings(),
          throwsA(isA<DioException>()),
        );

        expect(
          await database.select(database.campusMapBuildings).get(),
          beforeBuildings,
        );
        expect(
          await database.select(database.campusMapFloors).get(),
          beforeFloors,
        );
        expect(await database.select(database.campusMapSyncs).get(), [
          beforeSync,
        ]);
      },
    );
  });
}

CampusMapRepository _repository(
  CampusMapService service,
  AppDatabase database,
  DateTime Function() now,
) => CampusMapRepository(service: service, database: database, now: now);

Future<CampusMapFloorData> _floorData(
  CampusMapRepository repository,
  String layer,
) => repository.watchFloor(layer).first.timeout(const Duration(seconds: 5));

CampusMapBuildingDto _outline(String code, String name) => (
  id: code,
  code: code,
  name: name,
  polygons: const [],
);

CampusMapRoomDto _room(
  String layer,
  String number, {
  String? nameZh,
  String? nameEn,
  bool withGeometry = true,
}) => (
  id: '${layer.split(':').last}.$number',
  layerName: layer,
  nameZh: nameZh ?? 'Room $number',
  nameEn: nameEn ?? 'Room $number',
  number: number,
  polygons: withGeometry ? _geometry(121.5, 25.0) : const [],
);

CampusMapGeometryDto _geometry(double longitude, double latitude) => [
  [
    [
      (longitude: longitude, latitude: latitude),
      (longitude: longitude + 0.001, latitude: latitude),
      (longitude: longitude + 0.001, latitude: latitude + 0.001),
      (longitude: longitude, latitude: latitude + 0.001),
      (longitude: longitude, latitude: latitude),
    ],
  ],
];

CampusMapRoomsCompanion _roomCompanion(CampusMapRoomDto room) =>
    CampusMapRoomsCompanion.insert(
      id: room.id,
      layerName: room.layerName,
      nameZh: room.nameZh,
      nameEn: room.nameEn,
      number: room.number,
      geometry: const Value(null),
    );

DioException _networkError() => DioException(
  requestOptions: RequestOptions(path: '/campus-map'),
  type: DioExceptionType.connectionError,
);

class _FakeCampusMapService implements CampusMapService {
  List<CampusMapBuildingDto> buildings = [
    _outline('A1T', 'Alpha Hall'),
    _outline('B2', 'Beta Hall'),
  ];
  List<CampusMapLayerDto> layers = [
    (name: _layerA, buildingCode: 'A1T', floor: '1F'),
    (name: _layerB, buildingCode: 'B2', floor: '1F'),
  ];
  List<CampusMapRoomDto> index = [];
  final roomsByLayer = <String, List<CampusMapRoomDto>>{};
  final roomCalls = <String>[];
  int buildingCalls = 0;
  int layerCalls = 0;
  int indexCalls = 0;
  Future<List<CampusMapLayerDto>> Function()? layersHandler;
  Future<List<CampusMapRoomDto>> Function(String layer)? roomsHandler;
  Future<List<CampusMapRoomDto>> Function(List<String> layers)? indexHandler;

  @override
  Future<List<CampusMapBuildingDto>> getBuildings() async {
    buildingCalls++;
    return buildings;
  }

  @override
  Future<List<CampusMapLayerDto>> getLayers() {
    layerCalls++;
    return layersHandler?.call() ?? Future.value(layers);
  }

  @override
  Future<List<CampusMapRoomDto>> getRooms(String layerName) {
    roomCalls.add(layerName);
    return roomsHandler?.call(layerName) ??
        Future.value(roomsByLayer[layerName] ?? []);
  }

  @override
  Future<List<CampusMapRoomDto>> getRoomIndex(List<String> layerNames) {
    indexCalls++;
    return indexHandler?.call(layerNames) ?? Future.value(index);
  }
}
