import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/repositories/map_repository.dart';
import 'package:tattoo/services/map/campus_map_service.dart';

class MockCampusMapService implements CampusMapService {
  int buildingFetchCount = 0;
  int roomFetchCount = 0;

  @override
  Future<List<FeatureDto>> getBuildingGeometries() async {
    buildingFetchCount++;
    return [
      (
        id: 'bldg1',
        properties: {'name': 'Mock Building'},
        polygons: [
          [(x: 0.0, y: 0.0), (x: 10.0, y: 0.0), (x: 10.0, y: 10.0)],
        ],
      ),
    ];
  }

  @override
  Future<List<FeatureDto>> getRoomGeometries(List<String> layerNames) async {
    roomFetchCount++;
    return layerNames
        .map(
          (l) => (
            id: 'room_$l',
            properties: {'room_name': 'Mock $l'},
            polygons: [
              [(x: 1.0, y: 1.0), (x: 2.0, y: 1.0)],
            ],
          ),
        )
        .toList();
  }

  @override
  Future<List<int>> getBasemapTileBytes(int z, int tx, int ty) async {
    return [1, 2, 3];
  }
}

void main() {
  late AppDatabase db;
  late MockCampusMapService mockService;
  late CampusMapRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    mockService = MockCampusMapService();
    repository = CampusMapRepository(mockService, db);
  });

  tearDown(() async {
    await db.close();
  });

  group('CampusMapRepository caching and persistence', () {
    test('prefetchAll loads from service and saves to disk isolates', () async {
      await repository.init();

      expect(repository.getBuildingsSync(), isNull);

      await repository.prefetchAll();
      await repository.getBuildings();

      expect(mockService.buildingFetchCount, 1);
      expect(mockService.roomFetchCount, 1);

      final bldgs = repository.getBuildingsSync();
      expect(bldgs, isNotNull);
      expect(bldgs!.length, 1);
      expect(bldgs.first.id, 'bldg1');

      // Wait for the asynchronous background _saveToDisk() write to SQLite to complete
      await Future.delayed(const Duration(milliseconds: 150));

      // Create new instance to test disk read on init
      final repo2 = CampusMapRepository(mockService, db);
      await repo2.init();

      expect(mockService.buildingFetchCount, 1); // No new fetch

      final bldgs2 = repo2.getBuildingsSync();
      expect(bldgs2, isNotNull);
      expect(bldgs2!.length, 1);
      expect(bldgs2.first.id, 'bldg1');

      // gis_room:A1T_1F exists in the static _allLayers of MapRepository
      final rooms2 = await repo2.getRoomsForFloor('1F');
      expect(rooms2.length, greaterThan(0));
    });

    test('getRoomsForFloor coalesces in-flight requests', () async {
      await repository.init();

      expect(repository.getRoomsSync('1F'), isNull);

      final r1 = repository.getRoomsForFloor('1F');
      final r2 = repository.getRoomsForFloor('1F');

      final results = await Future.wait([r1, r2]);

      expect(mockService.roomFetchCount, 1);
      expect(results[0], equals(results[1]));

      expect(repository.getRoomsSync('1F'), isNotNull);

      final r3 = await repository.getRoomsForFloor('1F');
      expect(mockService.roomFetchCount, 1);
      expect(r3, equals(results[0]));
    });
  });
}
