import 'dart:convert';

import 'package:tattoo/services/map/campus_map_service.dart';
import 'package:xml/xml.dart';

/// The supported building and floor naming convention in the WFS catalog.
final campusMapLayerPattern = RegExp(
  r'^gis_room:([A-Z0-9]+)_((?:B?\d+[FM]?)|(?:R\d*F?))$',
);

/// Parses indoor layers from a WFS capabilities document, independent of prefix.
///
/// Throws [FormatException] if the server returned an exception document or no
/// indoor layers. Unrelated GIS layers are ignored.
List<CampusMapLayerDto> parseCampusMapLayers(String source) {
  final document = XmlDocument.parse(source);
  final layers = <CampusMapLayerDto>[];
  for (final element in document.descendants.whereType<XmlElement>()) {
    if (element.name.local != 'FeatureType') continue;
    final name = element.childElements
        .where((child) => child.name.local == 'Name')
        .firstOrNull
        ?.innerText
        .trim();
    if (name == null) continue;
    if (campusMapLayerPattern.firstMatch(name) case final match?) {
      layers.add((name: name, buildingCode: match[1]!, floor: match[2]!));
    }
  }
  if (layers.isEmpty) throw const FormatException('No indoor WFS layers');
  return layers;
}

List<Map<String, dynamic>> _features(String source) {
  final data = jsonDecode(source);
  if (data is! Map<String, dynamic> ||
      data['type'] != 'FeatureCollection' ||
      data['features'] is! List) {
    throw const FormatException('Expected a GeoJSON FeatureCollection');
  }
  return (data['features'] as List).cast<Map<String, dynamic>>();
}

String _text(Map<String, dynamic> properties, String key) =>
    properties[key]?.toString().trim() ?? '';

/// Parses building names, codes, and all GeoJSON polygon rings.
///
/// Outlines with missing codes are retained by feature ID. Features without
/// polygon geometry are ignored. Malformed supported geometry throws
/// [FormatException] rather than replacing a valid cache with partial data.
List<CampusMapBuildingDto> parseCampusMapBuildings(String source) => [
  for (final feature in _features(source))
    if (_geometry(feature['geometry']) case final polygons
        when polygons.isNotEmpty)
      (
        id: feature['id'] as String,
        code: _text(feature['properties'] as Map<String, dynamic>, 'build_id'),
        name: _text(
          feature['properties'] as Map<String, dynamic>,
          'build_name',
        ),
        polygons: polygons,
      ),
];

/// Parses room metadata and geometry while preserving names and indoor holes.
///
/// Feature IDs may omit the workspace prefix, as NTUT's GeoServer does. No
/// keyword filter removes named spaces. Metadata-only features with `null`
/// geometry are valid; unrelated feature IDs cause [FormatException].
List<CampusMapRoomDto> parseCampusMapRooms(String source) => [
  for (final feature in _features(source)) _room(feature),
];

CampusMapRoomDto _room(Map<String, dynamic> feature) {
  final id = feature['id'] as String;
  final layer =
      'gis_room:${id.replaceFirst(RegExp(r'^gis_room:'), '').split('.').first}';
  if (!campusMapLayerPattern.hasMatch(layer)) {
    throw FormatException('Unknown indoor feature ID: $id');
  }
  final properties = feature['properties'] as Map<String, dynamic>;
  return (
    id: id.replaceFirst(RegExp(r'^gis_room:'), ''),
    layerName: layer,
    nameZh: _text(properties, 'room_name'),
    nameEn: _text(properties, 'room_name_en'),
    number: _text(properties, 'class_num'),
    polygons: _geometry(feature['geometry']),
  );
}

CampusMapGeometryDto _geometry(dynamic geometry) {
  if (geometry == null) return [];
  if (geometry is! Map) {
    throw const FormatException('Invalid GeoJSON geometry');
  }
  final coordinates = geometry['coordinates'];
  final List polygons = switch (geometry['type']) {
    'Polygon' => [coordinates],
    'MultiPolygon' => coordinates as List,
    _ => [],
  };
  return [
    for (final polygon in polygons) _polygon(polygon),
  ];
}

List<List<CampusMapPointDto>> _polygon(dynamic coordinates) {
  if (coordinates is! List || coordinates.isEmpty) {
    throw const FormatException('Expected a polygon exterior ring');
  }
  return [
    for (final ring in coordinates)
      if (ring is List)
        _ring(ring)
      else
        throw const FormatException('Invalid polygon ring'),
  ];
}

List<CampusMapPointDto> _ring(List coordinates) {
  final points = <CampusMapPointDto>[];
  for (final coordinate in coordinates) {
    if (coordinate case [num longitude, num latitude, ...]) {
      final lon = longitude.toDouble();
      final lat = latitude.toDouble();
      if (!lon.isFinite || !lat.isFinite || lon.abs() > 180 || lat.abs() > 90) {
        throw const FormatException('Invalid WGS84 position');
      }
      points.add((longitude: lon, latitude: lat));
    } else {
      throw const FormatException('Invalid GeoJSON position');
    }
  }
  if (points.length < 4 || points.first != points.last) {
    throw const FormatException('Expected a closed polygon ring');
  }
  return points;
}
