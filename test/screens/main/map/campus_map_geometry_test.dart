import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/models/campus_map.dart';
import 'package:tattoo/screens/main/map/campus_map_geometry.dart';

void main() {
  // The map selects the building under the camera center with this check, so
  // a point inside an interior courtyard must not count as inside the building.
  test('geographic point containment excludes polygon holes', () {
    final polygon = CampusMapPolygon([
      _geoRing(const [
        (longitude: 0, latitude: 0),
        (longitude: 10, latitude: 0),
        (longitude: 10, latitude: 10),
        (longitude: 0, latitude: 10),
      ]),
      _geoRing(const [
        (longitude: 4, latitude: 4),
        (longitude: 6, latitude: 4),
        (longitude: 6, latitude: 6),
        (longitude: 4, latitude: 6),
      ]),
    ]);

    expect(
      campusMapContainsPoint(polygon, (longitude: 2, latitude: 2)),
      isTrue,
    );
    expect(
      campusMapContainsPoint(polygon, (longitude: 5, latitude: 5)),
      isFalse,
    );
  });
}

List<CampusMapPoint> _geoRing(List<CampusMapPoint> points) => [
  ...points,
  points.first,
];
