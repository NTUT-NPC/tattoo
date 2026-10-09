import 'package:tattoo/models/campus_map.dart';

/// Tests whether [point] lies inside the exterior and outside all polygon holes.
bool campusMapContainsPoint(CampusMapPolygon polygon, CampusMapPoint point) {
  bool contains(List<CampusMapPoint> ring) {
    var inside = false;
    for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      final a = ring[i];
      final b = ring[j];
      if ((a.latitude > point.latitude) != (b.latitude > point.latitude) &&
          point.longitude <
              (b.longitude - a.longitude) *
                      (point.latitude - a.latitude) /
                      (b.latitude - a.latitude) +
                  a.longitude) {
        inside = !inside;
      }
    }
    return inside;
  }

  return polygon.rings.isNotEmpty &&
      contains(polygon.rings.first) &&
      !polygon.rings.skip(1).any(contains);
}
