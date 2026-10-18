import 'package:riverpod/riverpod.dart';
import 'package:tattoo/services/demo_mode.dart';
import 'package:tattoo/services/map/mock_campus_map_service.dart';
import 'package:tattoo/services/map/ntut_campus_map_service.dart';

/// A WGS84 position, encoded as longitude and latitude in degrees.
typedef CampusMapPointDto = ({double longitude, double latitude});

/// GeoJSON polygons containing exterior rings and all interior holes.
typedef CampusMapGeometryDto = List<List<List<CampusMapPointDto>>>;

/// A building outline as published by the NTUT GeoServer.
typedef CampusMapBuildingDto = ({
  /// The original GeoJSON feature ID, including its layer prefix.
  String id,

  /// The server's building code, or an empty string for uncoded outlines.
  String code,

  /// The building name, or an empty string when absent upstream.
  String name,

  /// The outline's polygons, including all interior holes.
  CampusMapGeometryDto polygons,
});

/// A published indoor layer; floor suffixes retain mezzanine and roof levels.
typedef CampusMapLayerDto = ({
  /// The fully qualified WFS name, such as `gis_room:A1T_1F`.
  String name,

  /// The building code parsed from the layer name.
  String buildingCode,

  /// The original floor suffix; distinct mezzanines and roofs are not merged.
  String floor,
});

/// A room's searchable metadata and optional geometry from one indoor layer.
///
/// `CampusMapRoomDto.polygons` is empty in metadata-only search index requests.
typedef CampusMapRoomDto = ({
  /// The feature ID qualified by its floor layer, without the workspace prefix.
  String id,

  /// The fully qualified WFS layer that owns this space.
  String layerName,

  /// The Chinese space name, or an empty string when absent.
  String nameZh,

  /// The English space name, or an empty string when absent.
  String nameEn,

  /// The classroom or space number, or an empty string when absent.
  String number,

  /// The room polygons, or an empty list for a metadata-only request.
  CampusMapGeometryDto polygons,
});

/// Provides the public campus map client or a local demo implementation.
final campusMapServiceProvider = Provider<CampusMapService>((ref) {
  if (ref.watch(isDemoProvider)) return MockCampusMapService();
  final service = NtutCampusMapService();
  ref.onDispose(service.close);
  return service;
});

/// Reads public building and indoor data from NTUT's WFS service.
///
/// Requests require no portal session. Methods propagate network and format
/// errors, allowing the repository to retain its last successful cache.
abstract interface class CampusMapService {
  /// Fetches building outlines with their names and building codes.
  Future<List<CampusMapBuildingDto>> getBuildings();

  /// Discovers available building-floor layers from WFS capabilities.
  Future<List<CampusMapLayerDto>> getLayers();

  /// Fetches geometry and metadata for exactly one published [layerName].
  ///
  /// Returns an empty list if GeoServer explicitly reports that the advertised
  /// layer's backing schema does not exist. Other server errors propagate.
  Future<List<CampusMapRoomDto>> getRooms(String layerName);

  /// Fetches searchable room metadata without requesting polygon coordinates.
  ///
  /// [layerNames] must come from [getLayers]. Requests are batched and completed
  /// sequentially to bound URL length and pressure on the campus server.
  /// Layers explicitly reported to have no backing schema contribute no rooms;
  /// failed or malformed responses from all other layers abort the index.
  Future<List<CampusMapRoomDto>> getRoomIndex(List<String> layerNames);
}
