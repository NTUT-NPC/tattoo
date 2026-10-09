import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/models/campus_map.dart';

void main() {
  group('CampusMapFloor.order', () {
    test('orders mezzanine floors after their matching numbered floor', () {
      final floors = [
        _floor('2F'),
        _floor('1M'),
        _floor('B1'),
        _floor('1F'),
        _floor('2M'),
        _floor('R1'),
      ]..sort((a, b) => a.order.compareTo(b.order));

      expect(floors.map((floor) => floor.code), [
        'B1',
        '1F',
        '1M',
        '2F',
        '2M',
        'R1',
      ]);
      expect(_floor('1M').order, 1.5);
    });
  });

  test('normalizes full-width query text and common separators', () {
    expect(normalizeCampusMapQuery('Ａ１Ｔ（１０１）'), 'a1t101');
    expect(normalizeCampusMapQuery('Ａ１Ｔ　－　１０１'), 'a1t101');
  });

  test('round-trips polygons, multiple parts, and interior holes', () {
    final polygons = [
      CampusMapPolygon([
        _ring(121, 25),
        _ring(121.1, 25.1),
      ]),
      CampusMapPolygon([_ring(122, 26)]),
    ];

    final restored = decodeCampusMapGeometry(encodeCampusMapGeometry(polygons));

    expect(restored, hasLength(2));
    expect(restored[0].rings, hasLength(2));
    expect(restored[0].rings[1], polygons[0].rings[1]);
    expect(restored[1].rings, hasLength(1));
    expect(restored[0].rings.first.first, (longitude: 121.0, latitude: 25.0));
  });
}

CampusMapFloor _floor(String code) => CampusMapFloor(
  layerName: 'gis_room:A1T_$code',
  code: code,
);

List<CampusMapPoint> _ring(double longitude, double latitude) => [
  (longitude: longitude, latitude: latitude),
  (longitude: longitude + 0.001, latitude: latitude),
  (longitude: longitude + 0.001, latitude: latitude + 0.001),
  (longitude: longitude, latitude: latitude + 0.001),
  (longitude: longitude, latitude: latitude),
];
