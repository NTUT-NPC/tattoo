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

/// Finds an unambiguous new building under the camera center.
///
/// Downloaded geometry for the visible floor takes precedence over first-floor
/// building outlines: upper floors can extend into a neighbouring footprint.
/// Polygon holes remain outside, so courtyards do not trap the selection.
CampusMapBuilding? campusMapBuildingAt({
  required CampusMapPoint point,
  required List<CampusMapBuilding> buildings,
  required String? selectedBuildingCode,
  required List<CampusMapRoom> visibleRooms,
}) {
  if (selectedBuildingCode != null &&
      visibleRooms.any(
        (room) =>
            room.buildingCode == selectedBuildingCode &&
            room.polygons.any(
              (polygon) => campusMapContainsPoint(polygon, point),
            ),
      )) {
    return null;
  }
  final matches = buildings
      .where(
        (building) => building.polygons.any(
          (polygon) => campusMapContainsPoint(polygon, point),
        ),
      )
      .toList();
  if (matches.length != 1 || matches.single.code == selectedBuildingCode) {
    return null;
  }
  return matches.single;
}
