import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/models/campus_map.dart';
import 'package:tattoo/repositories/campus_map_first_floor_outlines.dart';
import 'package:tattoo/screens/main/map/campus_map_geometry.dart';
import 'package:tattoo/services/map/mock_campus_map_service.dart';

void main() {
  test('previously missing or combined buildings have distinct selectable footprints', () {
    final outlines = {
      for (final entry in campusMapFirstFloorOutlines.entries)
        entry.key: decodeCampusMapGeometry(entry.value.geometry),
    };
    const points = <String, CampusMapPoint>{
      'AC': (longitude: 121.53400486, latitude: 25.04294772),
      'AD': (longitude: 121.53511847, latitude: 25.04272152),
      'B2D': (longitude: 121.53793782, latitude: 25.04355570),
      'GR': (longitude: 121.53401019, latitude: 25.04245476),
      'LY': (longitude: 121.52380243, latitude: 25.04563920),
      'LB': (longitude: 121.53489920, latitude: 25.04287829),
      'B1D': (longitude: 121.53745951, latitude: 25.04353391),
    };
    for (final entry in points.entries) {
      final hits = [
        for (final building in outlines.entries)
          if (building.value.any(
            (polygon) => campusMapContainsPoint(polygon, entry.value),
          ))
            building.key,
      ];
      expect(hits, [entry.key], reason: entry.key);
    }
    expect(outlines, isNot(contains('PK')));
    expect(
      outlines.keys.any((code) => code.startsWith('gis_building_geom.')),
      isFalse,
    );
  });

  test('bundled outlines decode as closed nonempty WGS84 polygon rings', () {
    for (final entry in campusMapFirstFloorOutlines.entries) {
      final polygons = decodeCampusMapGeometry(entry.value.geometry);
      expect(polygons, isNotEmpty, reason: entry.key);
      for (final polygon in polygons) {
        expect(polygon.rings, isNotEmpty, reason: entry.key);
        for (final ring in polygon.rings) {
          expect(ring.length, greaterThanOrEqualTo(4), reason: entry.key);
          expect(ring.first, ring.last, reason: entry.key);
          for (final point in ring) {
            expect(point.longitude, inInclusiveRange(-180, 180));
            expect(point.latitude, inInclusiveRange(-90, 90));
          }
        }
      }
    }
  });

  test('demo building outline also comes from its local first floor', () async {
    final service = MockCampusMapService();
    final building = (await service.getBuildings()).single;
    final rooms = await service.getRooms('gis_room:A1T_1F');
    expect(building.polygons, [for (final room in rooms) ...room.polygons]);
  });
}
