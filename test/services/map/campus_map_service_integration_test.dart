import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/services/map/campus_map_service.dart';
import 'package:tattoo/services/map/ntut_campus_map_service.dart';

const _runCampusMapIntegration = bool.fromEnvironment('TEST_CAMPUS_MAP');
const _campusMapTimeout = Timeout(Duration(minutes: 3));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'validated public GeoServer supports catalog, floor, and metadata index requests',
    () async {
      await HttpOverrides.runWithHttpOverrides(() async {
        final service = NtutCampusMapService();
        try {
          final buildings = await service.getBuildings();
          final layers = await service.getLayers();
          final target = layers.where(
            (layer) => layer.name == 'gis_room:A5T_1F',
          );
          expect(
            buildings.isNotEmpty,
            isTrue,
            reason: 'building catalog is empty',
          );
          expect(layers.isNotEmpty, isTrue, reason: 'floor catalog is empty');
          expect(target.length, 1, reason: 'expected floor A5T_1F was absent');
          // ignore: avoid_print
          print(
            'Campus map catalog counts: buildings=${buildings.length}, '
            'layers=${layers.length}',
          );

          final rooms = await service.getRooms(target.single.name);
          // ignore: avoid_print
          print('Campus map A5T_1F room count: ${rooms.length}');
          expect(rooms.isNotEmpty, isTrue, reason: 'A5T_1F returned no rooms');
          expect(
            rooms.any((room) => room.polygons.isNotEmpty),
            isTrue,
            reason: 'A5T_1F returned no room geometry',
          );

          final names = layers.map((layer) => layer.name).toList();
          final index = <CampusMapRoomDto>[];
          for (var start = 0; start < names.length; start += 25) {
            final batchNumber = start ~/ 25 + 1;
            final end = start + 25 < names.length ? start + 25 : names.length;
            try {
              index.addAll(
                await service.getRoomIndex(names.sublist(start, end)),
              );
            } on FormatException {
              throw FormatException(
                'GeoServer returned a non-GeoJSON metadata response for batch $batchNumber',
              );
            }
          }
          expect(index.isNotEmpty, isTrue, reason: 'metadata index is empty');
          expect(
            index.every((room) => room.polygons.isEmpty),
            isTrue,
            reason: 'metadata-only index unexpectedly included geometry',
          );

          // Keep public response content private; only aggregate counts appear.
          // ignore: avoid_print
          print(
            'Campus map integration counts: buildings=${buildings.length}, '
            'layers=${layers.length}, A5T_1F rooms=${rooms.length}, '
            'indexed rooms=${index.length}',
          );
        } finally {
          service.close();
        }
      }, _RealHttpOverrides());
    },
    skip: !_runCampusMapIntegration,
    timeout: _campusMapTimeout,
  );
}

class _RealHttpOverrides extends HttpOverrides {}
