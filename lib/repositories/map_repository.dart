import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/services/map/campus_map_service.dart';

typedef CampusMapState = ({
  List<FeatureDto> buildings,
  Map<String, List<FeatureDto>> roomsByFloor,
  String selectedFloor,
});

final campusMapRepositoryProvider = Provider<CampusMapRepository>((ref) {
  return CampusMapRepository(
    ref.watch(campusMapServiceProvider),
    ref.watch(databaseProvider),
  );
});

class CampusMapRepository {
  CampusMapRepository(this._service, this._db);

  final CampusMapService _service;
  final AppDatabase _db;

  final Map<String, List<FeatureDto>> _roomCache = {};
  List<FeatureDto>? _buildingCache;
  bool _allRoomsFetched = false;
  bool get allRoomsFetched => _allRoomsFetched;

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    await _loadFromDisk();
    _isInitialized = true;
    print('[MapRepo] Cache initialized. AllRoomsFetched: $_allRoomsFetched, Buildings: ${_buildingCache != null}');
  }

  static const _cacheKey = 'campus_map_data_v2';

  static const floorOrder = [
    "B5",
    "B4",
    "B3",
    "B2",
    "B1",
    "1F",
    "2F",
    "3F",
    "4F",
    "5F",
    "6F",
    "7F",
    "8F",
    "9F",
    "10F",
    "11F",
    "12F",
    "13F",
    "14F",
    "15F",
    "16F",
    "RF",
  ];

  static const _allLayers = [
    "gis_room:A1T_1F",
    "gis_room:A1T_2F",
    "gis_room:A1T_3F",
    "gis_room:A2T_1F",
    "gis_room:A2T_2F",
    "gis_room:A2T_3F",
    "gis_room:A3T_1F",
    "gis_room:A3T_2F",
    "gis_room:A3T_3F",
    "gis_room:A3T_4F",
    "gis_room:A3T_5F",
    "gis_room:A3T_B1",
    "gis_room:A4T_1F",
    "gis_room:A4T_2F",
    "gis_room:A4T_3F",
    "gis_room:A4T_RF",
    "gis_room:A5T_1F",
    "gis_room:A5T_2F",
    "gis_room:A5T_3F",
    "gis_room:A5T_4F",
    "gis_room:A5T_5F",
    "gis_room:A5T_6F",
    "gis_room:A5T_7F",
    "gis_room:A5T_B1",
    "gis_room:A5T_R1",
    "gis_room:A5T_R2",
    "gis_room:A6T_1F",
    "gis_room:A6T_1M",
    "gis_room:A6T_2F",
    "gis_room:A6T_3F",
    "gis_room:A6T_4F",
    "gis_room:A6T_5F",
    "gis_room:A6T_6F",
    "gis_room:A6T_7F",
    "gis_room:A6T_8F",
    "gis_room:A6T_B1",
    "gis_room:A6T_B2",
    "gis_room:A6T_B3",
    "gis_room:A6T_B4",
    "gis_room:A6T_B5",
    "gis_room:AC_1F",
    "gis_room:AD_10F",
    "gis_room:AD_11F",
    "gis_room:AD_1F",
    "gis_room:AD_2F",
    "gis_room:AD_3F",
    "gis_room:AD_4F",
    "gis_room:AD_5F",
    "gis_room:AD_6F",
    "gis_room:AD_7F",
    "gis_room:AD_8F",
    "gis_room:AD_9F",
    "gis_room:AD_B1",
    "gis_room:AD_RF",
    "gis_room:AM_10F",
    "gis_room:AM_11F",
    "gis_room:AM_12F",
    "gis_room:AM_13F",
    "gis_room:AM_14F",
    "gis_room:AM_1F",
    "gis_room:AM_2F",
    "gis_room:AM_3F",
    "gis_room:AM_4F",
    "gis_room:AM_5F",
    "gis_room:AM_6F",
    "gis_room:AM_7F",
    "gis_room:AM_8F",
    "gis_room:AM_9F",
    "gis_room:AM_B1",
    "gis_room:AM_B2",
    "gis_room:AM_B3",
    "gis_room:AM_B4",
    "gis_room:AM_R1",
    "gis_room:AM_R2",
    "gis_room:AM_R3",
    "gis_room:B1D_10F",
    "gis_room:B1D_1F",
    "gis_room:B1D_2F",
    "gis_room:B1D_3F",
    "gis_room:B1D_4F",
    "gis_room:B1D_5F",
    "gis_room:B1D_6F",
    "gis_room:B1D_7F",
    "gis_room:B1D_8F",
    "gis_room:B1D_9F",
    "gis_room:B1D_B1",
    "gis_room:B1D_R1",
    "gis_room:B1D_R2",
    "gis_room:B2D_10F",
    "gis_room:B2D_11F",
    "gis_room:B2D_12F",
    "gis_room:B2D_1F",
    "gis_room:B2D_2F",
    "gis_room:B2D_3F",
    "gis_room:B2D_4F",
    "gis_room:B2D_5F",
    "gis_room:B2D_6F",
    "gis_room:B2D_7F",
    "gis_room:B2D_8F",
    "gis_room:B2D_9F",
    "gis_room:B2D_B1",
    "gis_room:B2D_R1",
    "gis_room:CB_1F",
    "gis_room:CB_2F",
    "gis_room:CB_3F",
    "gis_room:CB_4F",
    "gis_room:CB_5F",
    "gis_room:CB_6F",
    "gis_room:CB_7F",
    "gis_room:CB_8F",
    "gis_room:CB_B1",
    "gis_room:CB_B1M",
    "gis_room:CE_1F",
    "gis_room:CE_2F",
    "gis_room:CE_3F",
    "gis_room:CE_4F",
    "gis_room:CE_5F",
    "gis_room:CE_B1",
    "gis_room:CH_1F",
    "gis_room:CH_2F",
    "gis_room:CH_3F",
    "gis_room:CK_1F",
    "gis_room:CK_2F",
    "gis_room:CK_3F",
    "gis_room:CK_4F",
    "gis_room:CK_5F",
    "gis_room:CK_6F",
    "gis_room:CK_7F",
    "gis_room:CK_B1",
    "gis_room:CK_B2",
    "gis_room:CK_RF",
    "gis_room:CM_1F",
    "gis_room:CM_2F",
    "gis_room:CM_3F",
    "gis_room:CM_4F",
    "gis_room:DB_1F",
    "gis_room:DB_2F",
    "gis_room:DB_3F",
    "gis_room:DB_4F",
    "gis_room:DB_5F",
    "gis_room:DB_6F",
    "gis_room:DB_7F",
    "gis_room:DB_8F",
    "gis_room:DB_9F",
    "gis_room:DB_B1",
    "gis_room:DB_RF",
    "gis_room:EL_10F",
    "gis_room:EL_11F",
    "gis_room:EL_12F",
    "gis_room:EL_13F",
    "gis_room:EL_1F",
    "gis_room:EL_2F",
    "gis_room:EL_3F",
    "gis_room:EL_4F",
    "gis_room:EL_5F",
    "gis_room:EL_6F",
    "gis_room:EL_7F",
    "gis_room:EL_8F",
    "gis_room:EL_9F",
    "gis_room:EL_B1",
    "gis_room:EL_B2",
    "gis_room:EL_B3",
    "gis_room:EL_R1",
    "gis_room:EL_R2",
    "gis_room:EL_RF",
    "gis_room:GB_1F",
    "gis_room:GB_2F",
    "gis_room:GB_3F",
    "gis_room:GB_4F",
    "gis_room:GB_5F",
    "gis_room:GB_6F",
    "gis_room:GB_7F",
    "gis_room:GB_8F",
    "gis_room:GB_9F",
    "gis_room:GB_B1",
    "gis_room:GB_RF",
    "gis_room:GH_1F",
    "gis_room:GH_2F",
    "gis_room:GH_3F",
    "gis_room:GH_4F",
    "gis_room:GH_5F",
    "gis_room:GR_1F",
    "gis_room:GR_2F",
    "gis_room:HR_10F",
    "gis_room:HR_11F",
    "gis_room:HR_12F",
    "gis_room:HR_13F",
    "gis_room:HR_14F",
    "gis_room:HR_15F",
    "gis_room:HR_16F",
    "gis_room:HR_1F",
    "gis_room:HR_2F",
    "gis_room:HR_3F",
    "gis_room:HR_4F",
    "gis_room:HR_5F",
    "gis_room:HR_6F",
    "gis_room:HR_7F",
    "gis_room:HR_8F",
    "gis_room:HR_9F",
    "gis_room:HR_B1",
    "gis_room:HR_B2",
    "gis_room:HR_B3",
    "gis_room:HR_B4",
    "gis_room:HR_B5",
    "gis_room:LB_1F",
    "gis_room:LB_2F",
    "gis_room:LB_3F",
    "gis_room:LB_4F",
    "gis_room:LB_B1",
    "gis_room:LY_10F",
    "gis_room:LY_11F",
    "gis_room:LY_1F",
    "gis_room:LY_2F",
    "gis_room:LY_3F",
    "gis_room:LY_4F",
    "gis_room:LY_5F",
    "gis_room:LY_6F",
    "gis_room:LY_7F",
    "gis_room:LY_8F",
    "gis_room:LY_9F",
    "gis_room:LY_R1",
    "gis_room:LY_RF",
    "gis_room:ME_1F",
    "gis_room:ME_2F",
    "gis_room:ME_3F",
    "gis_room:ME_4F",
    "gis_room:ME_5F",
    "gis_room:ME_B1",
    "gis_room:MR_1F",
    "gis_room:MR_2F",
    "gis_room:MR_3F",
    "gis_room:MR_4F",
    "gis_room:MR_5F",
    "gis_room:MR_B1",
    "gis_room:PK_B2",
    "gis_room:PK_B3",
    "gis_room:PK_B5",
    "gis_room:RB_1F",
    "gis_room:RB_2F",
    "gis_room:SE_1F",
    "gis_room:SS_1F",
    "gis_room:SY_1F",
    "gis_room:SY_2F",
    "gis_room:SY_3F",
    "gis_room:SY_4F",
  ];

  Future<List<FeatureDto>> getBuildings() async {
    if (_buildingCache != null) return _buildingCache!;
    _buildingCache = await _service.getBuildingGeometries();
    _saveToDisk().catchError((_) {});
    return _buildingCache!;
  }

  List<FeatureDto>? getBuildingsSync() => _buildingCache;

  Future<void> prefetchAll() async {
    if (_allRoomsFetched) return;

    final allRooms = await _service.getRoomGeometries(_allLayers);

    // Clear and redistribute into cache
    _roomCache.clear();
    for (final room in allRooms) {
      // room.id looks like "gis_room:A5T_1F.1"
      final parts = room.id.split(':');
      if (parts.length < 2) continue;
      final layerAndId = parts[1];
      final layerName = layerAndId.split('.').first;
      final floorSuffix = layerName.split('_').last;

      // Handle special mapping (R1, R2, R3 -> RF) like in _getLayersForFloor
      final String floor;
      if (['R1', 'R2', 'R3', 'RF'].contains(floorSuffix)) {
        floor = 'RF';
      } else {
        floor = floorSuffix;
      }

      _roomCache.putIfAbsent(floor, () => []).add(room);
    }

    _allRoomsFetched = true;
    _saveToDisk().catchError((_) {});
  }

  Future<void> _saveToDisk() async {
    final data = {
      'buildings': _buildingCache?.map(_featureToMap).toList(),
      'rooms': _roomCache.map(
        (k, v) => MapEntry(k, v.map(_featureToMap).toList()),
      ),
      'allRoomsFetched': _allRoomsFetched,
    };

    final json = jsonEncode(data);
    await _db
        .into(_db.mapCache)
        .insertOnConflictUpdate(
          MapCacheData(key: _cacheKey, value: json),
        );
  }

  Future<void> _loadFromDisk() async {
    final entry = await (_db.select(
      _db.mapCache,
    )..where((t) => t.key.equals(_cacheKey))).getSingleOrNull();
    if (entry == null) return;

    final data = jsonDecode(entry.value) as Map<String, dynamic>;

    if (data['buildings'] != null) {
      _buildingCache = (data['buildings'] as List)
          .map((f) => _featureFromMap(f as Map<String, dynamic>))
          .toList();
    }

    if (data['rooms'] != null) {
      final rooms = data['rooms'] as Map<String, dynamic>;
      rooms.forEach((k, v) {
        _roomCache[k] = (v as List)
            .map((f) => _featureFromMap(f as Map<String, dynamic>))
            .toList();
      });
    }

    _allRoomsFetched = data['allRoomsFetched'] ?? false;
  }

  Map<String, dynamic> _featureToMap(FeatureDto f) => {
    'id': f.id,
    'properties': f.properties,
    'polygons': f.polygons
        .map((poly) => poly.map((p) => [p.x, p.y]).toList())
        .toList(),
  };

  FeatureDto _featureFromMap(Map<String, dynamic> m) => (
    id: m['id'] as String,
    properties: m['properties'] as Map<String, dynamic>,
    polygons: (m['polygons'] as List)
        .map(
          (poly) => (poly as List).map((p) {
            final pt = p as List;
            return (
              x: (pt[0] as num).toDouble(),
              y: (pt[1] as num).toDouble(),
            );
          }).toList(),
        )
        .toList(),
  );

  Future<List<FeatureDto>> getRoomsForFloor(String floor) async {
    if (_allRoomsFetched && _roomCache.containsKey(floor)) {
      return _roomCache[floor]!;
    }

    if (_roomCache.containsKey(floor)) return _roomCache[floor]!;

    final layers = _getLayersForFloor(floor);
    if (layers.isEmpty) return [];

    final rooms = await _service.getRoomGeometries(layers);
    _roomCache[floor] = rooms;
    return rooms;
  }

  List<FeatureDto>? getRoomsSync(String floor) => _roomCache[floor];

  List<String> _getLayersForFloor(String floor) {
    return _allLayers.where((l) {
      final suffix = l.split('_').last;
      if (floor == 'RF') {
        return ['R1', 'R2', 'R3', 'RF'].contains(suffix);
      }
      return suffix == floor;
    }).toList();
  }
}
