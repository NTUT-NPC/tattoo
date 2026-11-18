import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/models/campus_map.dart';
import 'package:tattoo/repositories/campus_map_first_floor_outlines.dart';
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
        repository = _repository(service, database, () => clock, bundled: true);
        final buildings = await repository.watchBuildings().first;
        final sixth = buildings.singleWhere(
          (building) => building.code == 'A6T',
        );
        final hongYu = buildings.singleWhere(
          (building) => building.code == 'HR',
        );
        expect(sixth.name, '第六教學大樓');
        expect(hongYu.name, '宏裕科技研究大樓');
        expect(sixth.floors.single.layerName, 'gis_room:A6T_1F');
        expect(hongYu.floors.single.layerName, 'gis_room:HR_1F');
        expect(
          buildings.singleWhere((building) => building.code == 'A1T').polygons,
          isNotEmpty,
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
      'original and localized building names both locate the same room',
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

        repository = _repository(service, database, () => clock, bundled: true);

        final hongYu = (await repository.searchPlaces('宏裕科技研究大樓101'))
            .uniqueExactMatch!
            .room!;
        final sixth = (await repository.searchPlaces('第六教學大樓101'))
            .uniqueExactMatch!
            .room!;
        expect(hongYu.buildingCode, 'HR');
        expect(hongYu.buildingName, '宏裕科技研究大樓');
        expect(sixth.buildingCode, 'A6T');
        expect(sixth.buildingName, '第六教學大樓');
        expect((await repository.locateRoom(hongYu))!.buildingName, '宏裕科技研究大樓');
        final originalLocale = LocaleSettings.currentLocale;
        addTearDown(() => LocaleSettings.setLocale(originalLocale));
        for (final locale in AppLocale.values) {
          await LocaleSettings.setLocale(locale);
          for (final query in [
            'Hong-Yue Technology Research101', // en-US i18n
            '宏裕科技大樓101', // zh-TW i18n
            '宏裕科技研究大樓101', // Bundled name
            'Hong-Yue Technology Research Building101',
            'HYTRB_101',
            '科研101',
            'STRB_101',
          ]) {
            final result = await repository.searchPlaces(query);
            expect(result.uniqueExactMatch?.room?.id, hongYu.id, reason: query);
          }
        }
        final sourceName = await repository.searchPlaces('宏裕科技大樓/第六教學大樓101');
        expect(sourceName.uniqueExactMatch?.room?.id, sixth.id);
        expect(service.indexCalls, 1);
        expect(service.roomCalls, ['gis_room:HR_1F']);
      },
    );

    test(
      'all first-floor outlines replace cached combined or uncoded outlines',
      () async {
        final codes = ['AC', 'AD', 'B2D', 'GR', 'LY', 'LB', 'B1D'];
        service.buildings = [
          _outline('gis_building_geom.13', '迴廊'),
          _outline('gis_building_geom.17', 'Wrong outline'),
          _outline('LB', '圖書館/行政大樓'),
          _outline('B1D', '學生宿舍'),
          _outline('PK', 'Parking'),
        ];
        service.layers = [
          for (final code in codes)
            (name: 'gis_room:${code}_1F', buildingCode: code, floor: '1F'),
          (name: 'gis_room:PK_B1', buildingCode: 'PK', floor: 'B1'),
        ];
        service.index = [_room('gis_room:PK_B1', 'P001', withGeometry: false)];
        await repository.refreshBuildings();
        final source = await database.select(database.campusMapBuildings).get();
        repository = _repository(service, database, () => clock, bundled: true);

        final catalog = await repository.watchBuildings().first;
        final buildings = catalog.where((building) => building.shownOnMap);
        expect(
          buildings.map((building) => building.code),
          unorderedEquals(codes),
        );
        expect(
          catalog
              .where((building) => !building.shownOnMap)
              .map((building) => building.code),
          unorderedEquals([
            'gis_building_geom.13',
            'gis_building_geom.17',
            'PK',
          ]),
        );
        for (final building in buildings) {
          expect(building.polygons, isNotEmpty, reason: building.code);
          expect(
            building.name,
            campusMapFirstFloorOutlines[building.code]!.name,
          );
        }
        expect((await repository.searchPlaces('P001')).matches, isEmpty);
        expect(service.roomCalls, isEmpty);
        expect(
          await database.select(database.campusMapBuildings).get(),
          source,
        );
      },
    );

    test(
      'a known building without an advertised first floor is hidden',
      () async {
        service.buildings = [_outline('A1T', 'Alpha Hall')];
        service.layers = [
          (name: _layerA2, buildingCode: 'A1T', floor: '2F'),
        ];
        await repository.refreshBuildings();
        repository = _repository(service, database, () => clock, bundled: true);

        final building = (await repository.watchBuildings().first).single;
        expect(building.code, 'A1T');
        expect(building.shownOnMap, isFalse);
        expect(building.floors.single.layerName, _layerA2);
        expect(service.roomCalls, isEmpty);
      },
    );

    for (final bundled in [false, true]) {
      test(
        'search skips hidden buildings but retains upper-floor matches (bundled: $bundled)',
        () async {
          service.buildings = [
            _outline('A1T', 'Alpha Hall'),
            _outline('AD', 'Administration'),
          ];
          service.layers = [
            (name: _layerA2, buildingCode: 'A1T', floor: '2F'),
            (name: 'gis_room:AD_1F', buildingCode: 'AD', floor: '1F'),
            (name: 'gis_room:AD_2F', buildingCode: 'AD', floor: '2F'),
          ];
          service.index = [
            _room(_layerA2, '201', withGeometry: false),
            _room('gis_room:AD_2F', '201A', withGeometry: false),
          ];
          repository = _repository(
            service,
            database,
            () => clock,
            bundled: bundled,
          );

          expect(
            (await repository.watchBuildings().first)
                .where((building) => building.shownOnMap)
                .map((building) => building.code),
            ['AD'],
          );
          final results = await repository.searchPlaces('201A');
          expect(results.matches.map((match) => match.room?.id), [
            'AD_2F.201A',
          ]);
          expect((await repository.searchPlaces('201')).matches, isEmpty);
          expect(service.roomCalls, isEmpty);
        },
      );
    }

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

      expect(
        (await repository.searchPlaces('材料實驗室')).uniqueExactMatch?.room?.number,
        '101',
      );
      final suggestion = await repository.searchPlaces('materials');
      expect(suggestion.matches.single.room?.number, '101');
      expect(suggestion.uniqueExactMatch, isNull);
      expect(
        (await repository.searchPlaces('２０２')).uniqueExactMatch?.room?.nameZh,
        '設計教室',
      );
      expect(service.indexCalls, 1);
    });

    test('exact matches take precedence over partial matches', () async {
      service.index = [
        _room(_layerA, '101', nameZh: '101教室'),
        _room(_layerB, '101A', nameZh: '會議室'),
      ];

      final results = await repository.searchPlaces('101');

      expect(results.uniqueExactMatch?.room?.id, 'A1T_1F.101');
    });

    test(
      'building-qualified exact queries select the matching building',
      () async {
        service.index = [
          _room(_layerA, '101', nameZh: '一般教室'),
          _room(_layerB, '101', nameZh: '一般教室'),
        ];

        final results = await repository.searchPlaces('B2 101');

        expect(results.uniqueExactMatch?.room?.id, 'B2_1F.101');
      },
    );

    test('duplicate exact values remain multiple search results', () async {
      service.index = [
        _room(_layerA, '101', nameZh: '教室甲'),
        _room(_layerB, '101', nameZh: '教室乙'),
      ];

      final results = await repository.searchPlaces('101');

      expect(results.isExact, isTrue);
      expect(results.matches.map((match) => match.room?.number), [
        '101',
        '101',
      ]);
    });

    test('search includes browsable buildings without indexed rooms', () async {
      service.index = [_room(_layerB, '101')];

      final result = await repository.searchPlaces('一教');

      expect(result.uniqueExactMatch?.buildingCode, 'A1T');
      expect(result.matches.single.room, isNull);
      expect(service.roomCalls, isEmpty);
    });

    test(
      'verified room aliases are tied to their building, floor and number',
      () async {
        const adFirst = 'gis_room:AD_1F';
        const adFifth = 'gis_room:AD_5F';
        const adSixth = 'gis_room:AD_6F';
        const cbFirst = 'gis_room:CB_1F';
        const cbSixth = 'gis_room:CB_6F';
        service.layers = [
          (name: adFirst, buildingCode: 'AD', floor: '1F'),
          (name: adFifth, buildingCode: 'AD', floor: '5F'),
          (name: adSixth, buildingCode: 'AD', floor: '6F'),
          (name: cbFirst, buildingCode: 'CB', floor: '1F'),
          (name: cbSixth, buildingCode: 'CB', floor: '6F'),
        ];
        service.index = [
          _room(cbSixth, '602'),
          _room(adFifth, '602'),
          _room(adSixth, '601'),
          _room(adSixth, '602', nameZh: '研發處辦公室'),
        ];

        for (final query in ['研發處', '行政大樓研發處', '研發處 行政大樓']) {
          final result = await repository.searchPlaces(query);
          expect(result.uniqueExactMatch?.room?.id, 'AD_6F.602', reason: query);
        }
      },
    );

    test(
      'teacher-name fragments remain suggestions without a room alias',
      () async {
        const cbFirst = 'gis_room:CB_1F';
        const cbThird = 'gis_room:CB_3F';
        service.layers = [
          (name: cbFirst, buildingCode: 'CB', floor: '1F'),
          (name: cbThird, buildingCode: 'CB', floor: '3F'),
        ];
        service.index = [
          _room(cbFirst, '107-1', nameZh: '研究生綜合專題實驗室【高立人】'),
          _room(cbThird, '302', nameZh: '高立人老師研究室'),
        ];

        for (final query in ['高立人', '粽科高立人', '高立人 粽科']) {
          final result = await repository.searchPlaces(query);
          expect(result.isExact, isFalse, reason: query);
          expect(result.uniqueExactMatch, isNull, reason: query);
          expect(result.matches.map((match) => match.room?.id), [
            'CB_1F.107-1',
            'CB_3F.302',
          ], reason: query);
        }
      },
    );

    test('粽科207-3 selects only the full hyphenated room number', () async {
      const cbFirst = 'gis_room:CB_1F';
      const cbSecond = 'gis_room:CB_2F';
      service.layers = [
        (name: cbFirst, buildingCode: 'CB', floor: '1F'),
        (name: cbSecond, buildingCode: 'CB', floor: '2F'),
      ];
      service.index = [
        _room(cbSecond, '207-2'),
        _room(cbSecond, '207-3'),
        _room(cbSecond, '207-4'),
        _room(cbSecond, '2073'),
      ];

      for (final query in ['粽科207-3', '粽科（２０７－３）', 'CB-207-3']) {
        final result = await repository.searchPlaces(query);
        expect(result.uniqueExactMatch?.room?.id, 'CB_2F.207-3', reason: query);
      }
      expect((await repository.searchPlaces('粽科207')).matches, isEmpty);
      expect(
        (await repository.searchPlaces('粽科2073'))
            .uniqueExactMatch
            ?.room
            ?.number,
        '2073',
      );
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
        repository.searchPlaces('101'),
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
      expect(
        (await repository.searchPlaces('教室甲')).uniqueExactMatch?.room?.number,
        '101',
      );
      clock = clock.add(const Duration(days: 15));
      service.indexHandler = (_) => Future.error(_networkError());

      final results = await repository.searchPlaces('101');
      expect(results.uniqueExactMatch?.room?.nameZh, '教室甲');
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
      final search = repository.searchPlaces('教室');
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
      final result = (await repository.searchPlaces('102'))
          .uniqueExactMatch!
          .room!;
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
  DateTime Function() now, {
  bool bundled = false,
}) => CampusMapRepository(
  service: service,
  database: database,
  now: now,
  firstFloorOutlines: bundled ? campusMapFirstFloorOutlines : null,
);

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
