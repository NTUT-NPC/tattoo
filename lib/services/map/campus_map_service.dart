import 'dart:math';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef VectorPoint = ({double x, double y});

typedef FeatureDto = ({
  String id,
  Map<String, dynamic> properties,
  List<List<VectorPoint>> polygons,
});

abstract interface class CampusMapService {
  Future<List<FeatureDto>> getBuildingGeometries();
  Future<List<FeatureDto>> getRoomGeometries(List<String> layerNames);
}

final campusMapServiceProvider = Provider<CampusMapService>((ref) {
  final dio = Dio(
    BaseOptions(
      validateStatus: (status) => true,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  (dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate = (client) {
    client.badCertificateCallback = (cert, host, port) => true;
    return client;
  };

  return NtutCampusMapService(dio);
});

class NtutCampusMapService implements CampusMapService {
  NtutCampusMapService(this._dio);

  final Dio _dio;
  static const _wfsBase = 'https://geoserver.oga.ntut.edu.tw/ows';
  static const _wfsSrs = 'EPSG:3857';

  static const _excludeKeywords = [
    "柱子",
    "走廊",
    "走道",
    "梯廳",
    "管道間",
    "未命名",
    "委外空間",
    "排煙",
    "機房",
    "採光",
    "消防",
    "茶水間",
    "電氣室",
    "大廳",
    "挑空",
    "管道",
  ];

  @override
  Future<List<FeatureDto>> getBuildingGeometries() async {
    return _fetchSingleLayer('gis:gis_building_geom');
  }

  @override
  Future<List<FeatureDto>> getRoomGeometries(List<String> layerNames) async {
    if (layerNames.isEmpty) return [];

    final allResults = <FeatureDto>[];
    // Process in batches of 16 to avoid overwhelming the network/server
    for (int i = 0; i < layerNames.length; i += 16) {
      final batch = layerNames.sublist(i, min(i + 16, layerNames.length));
      final results = await Future.wait(
        batch.map((l) => _fetchSingleLayer(l, isRoom: true)),
      );
      allResults.addAll(results.expand((x) => x));
    }
    return allResults;
  }

  Future<List<FeatureDto>> _fetchSingleLayer(
    String layerName, {
    bool isRoom = false,
  }) async {
    try {
      final response = await _dio.get(
        _wfsBase,
        queryParameters: {
          'service': 'WFS',
          'version': '2.0.0',
          'request': 'GetFeature',
          'typeNames': layerName,
          'outputFormat': 'application/json',
          'SRSNAME': _wfsSrs,
        },
      );

      if (response.statusCode != 200) return [];

      final data = response.data as Map<String, dynamic>;
      final features = data['features'] as List<dynamic>? ?? [];

      return features
          .map((f) {
            final feat = f as Map<String, dynamic>;
            final geometry = feat['geometry'] as Map<String, dynamic>?;
            final properties = feat['properties'] as Map<String, dynamic>;
            final id = feat['id'] as String? ?? '';

            if (isRoom) {
              final name = properties['room_name'] ?? '';
              final use = properties['use'] ?? '';
              final keyword = properties['keyword'] ?? '';
              final combined = '$name$use$keyword';
              if (_excludeKeywords.any((k) => combined.contains(k))) {
                return null;
              }
            }

            final polygons = <List<VectorPoint>>[];
            if (geometry != null) {
              final type = geometry['type'] as String;
              final coords = geometry['coordinates'] as List<dynamic>;

              if (type == 'Polygon') {
                polygons.add(_parsePolygon(coords));
              } else if (type == 'MultiPolygon') {
                for (final polyCoords in coords) {
                  polygons.add(_parsePolygon(polyCoords as List<dynamic>));
                }
              }
            }

            return (
              id: id,
              properties: properties,
              polygons: polygons,
            );
          })
          .whereType<FeatureDto>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  List<VectorPoint> _parsePolygon(List<dynamic> rings) {
    if (rings.isEmpty) return [];
    final exteriorRing = rings[0] as List<dynamic>;
    return exteriorRing
        .map((c) => (x: (c[0] as num).toDouble(), y: (c[1] as num).toDouble()))
        .toList();
  }
}
