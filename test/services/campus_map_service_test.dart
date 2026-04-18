import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/services/map/campus_map_service.dart';

void main() {
  late NtutCampusMapService service;

  setUpAll(() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) =>
            host == 'geoserver.oga.ntut.edu.tw';
        return client;
      },
    );
    service = NtutCampusMapService(dio);
  });

  group('NtutCampusMapService Integration', () {
    test('getBuildingGeometries fetches and parses polygons', () async {
      final buildings = await service.getBuildingGeometries();

      expect(buildings.isNotEmpty, true);
      final first = buildings.first;
      expect(first.id, isNotEmpty);
      expect(first.polygons, isNotEmpty);
      expect(first.polygons.first, isNotEmpty);
    });

    test(
      'getRoomGeometries fetches, parses, and applies keyword exclusion',
      () async {
        // Test a known layer to ensure exclusions logic and polygon parsing run
        final rooms = await service.getRoomGeometries(['gis_room:A1T_1F']);

        expect(rooms.isNotEmpty, true);

        // Verify exclusions worked (no room should contain keywords)
        for (final room in rooms) {
          final name = room.properties['room_name'] ?? '';
          final use = room.properties['use'] ?? '';
          final keyword = room.properties['keyword'] ?? '';
          final combined = '$name$use$keyword';

          expect(combined.contains('柱子'), false);
          expect(combined.contains('走廊'), false);
          expect(combined.contains('管道'), false);

          expect(room.polygons, isNotEmpty);
        }
      },
    );

    test('getBasemapTileBytes fetches bytes without errors', () async {
      final bytes = await service.getBasemapTileBytes(17, 109312, 56345);
      expect(bytes.isNotEmpty, true);
    });
  });
}
