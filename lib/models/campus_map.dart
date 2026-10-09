import 'dart:convert';

/// A geographic coordinate in degrees, independent of the map renderer.
typedef CampusMapPoint = ({double latitude, double longitude});

/// A polygon with an exterior ring followed by any interior holes.
class CampusMapPolygon {
  /// Creates a polygon from closed geographic [rings].
  CampusMapPolygon(List<List<CampusMapPoint>> rings)
    : rings = List.unmodifiable(rings.map(List<CampusMapPoint>.unmodifiable));

  /// The exterior ring at index zero and interior holes at subsequent indices.
  final List<List<CampusMapPoint>> rings;
}

/// Serializes polygons for a single building or room in the local database.
String encodeCampusMapGeometry(List<CampusMapPolygon> polygons) => jsonEncode([
  for (final polygon in polygons)
    [
      for (final ring in polygon.rings)
        [
          for (final point in ring) [point.longitude, point.latitude],
        ],
    ],
]);

/// Restores polygons stored by [encodeCampusMapGeometry].
List<CampusMapPolygon> decodeCampusMapGeometry(String source) => [
  for (final polygon in jsonDecode(source) as List)
    CampusMapPolygon([
      for (final ring in polygon as List)
        [
          for (final point in ring as List)
            (
              longitude: (point[0] as num).toDouble(),
              latitude: (point[1] as num).toDouble(),
            ),
        ],
    ]),
];

/// A campus building with its outline and available indoor floors.
class CampusMapBuilding {
  /// Creates a building assembled from the outline and layer catalogs.
  const CampusMapBuilding({
    required this.code,
    required this.name,
    required this.polygons,
    required this.floors,
  });

  /// The GeoServer building code, or a feature ID for uncoded outlines.
  final String code;

  /// The server's building name, falling back to [code] when unnamed.
  final String name;

  /// The outline, including holes; empty for buildings absent from that layer.
  final List<CampusMapPolygon> polygons;

  /// The building's available floors in ascending physical order.
  final List<CampusMapFloor> floors;
}

/// One published indoor layer belonging to a building.
class CampusMapFloor {
  /// Creates a floor without merging mezzanines or different roof levels.
  const CampusMapFloor({required this.layerName, required this.code});

  /// The fully qualified WFS layer name used as the cache key.
  final String layerName;

  /// The server's floor suffix, such as `B1`, `1M`, or `R2`.
  final String code;

  /// The physical order, with mezzanines after their corresponding floor.
  double get order {
    if (code.startsWith('R')) {
      return 100 + (int.tryParse(code.substring(1)) ?? 0).toDouble();
    }
    final number = int.tryParse(code.replaceAll(RegExp('[^0-9]'), '')) ?? 0;
    final base = code.startsWith('B') ? -number.toDouble() : number.toDouble();
    return base + (code.endsWith('M') ? 0.5 : 0);
  }
}

/// A searchable indoor space, optionally containing downloaded geometry.
class CampusMapRoom {
  /// Creates a room from a normalized database query.
  const CampusMapRoom({
    required this.id,
    required this.buildingCode,
    required this.buildingName,
    required this.floor,
    required this.nameZh,
    required this.nameEn,
    required this.number,
    this.polygons = const [],
  });

  /// The layer-qualified feature identifier.
  final String id;

  /// The owning building's code.
  final String buildingCode;

  /// The owning building's display name.
  final String buildingName;

  /// The owning layer and its actual floor suffix.
  final CampusMapFloor floor;

  /// The Chinese space name, which may be empty.
  final String nameZh;

  /// The English space name, which may be empty.
  final String nameEn;

  /// The classroom or space number, which may be empty.
  final String number;

  /// The polygons for a downloaded floor; empty in search-only results.
  final List<CampusMapPolygon> polygons;
}

/// A floor's cached spaces and whether a complete geometry fetch succeeded.
class CampusMapFloorData {
  /// Creates a snapshot, distinguishing an empty floor from a failed cold load.
  const CampusMapFloorData({required this.rooms, required this.hasCache});

  /// The spaces whose geometry has been downloaded for this floor.
  final List<CampusMapRoom> rooms;

  /// Whether this floor has a successful fetch timestamp, even if empty.
  final bool hasCache;
}

/// Normalizes classroom queries, including full-width ASCII and separators.
String normalizeCampusMapQuery(String value) => String.fromCharCodes(
  value.runes.map(
    (rune) => switch (rune) {
      >= 0xff01 && <= 0xff5e => rune - 0xfee0,
      0x3000 => 0x20,
      _ => rune,
    },
  ),
).toLowerCase().replaceAll(RegExp(r'[\s_\-()（）/]+'), '');
