import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
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
  Future<List<int>> getBasemapTileBytes(int z, int tx, int ty);
}

final campusMapServiceProvider = Provider<CampusMapService>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) =>
          host == 'geoserver.oga.ntut.edu.tw';
      return client;
    },
  );

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
    return _fetchLayers(['gis:gis_building_geom']);
  }

  @override
  Future<List<FeatureDto>> getRoomGeometries(List<String> layerNames) async {
    if (layerNames.isEmpty) return [];

    final allResults = <FeatureDto>[];
    // Process in batches of 50 to avoid any URL length limits while minimizing HTTP requests
    for (int i = 0; i < layerNames.length; i += 50) {
      final batch = layerNames.sublist(i, min(i + 50, layerNames.length));
      final results = await _fetchLayers(batch, isRoom: true);
      allResults.addAll(results);
    }
    return allResults;
  }

  @override
  Future<List<int>> getBasemapTileBytes(int z, int tx, int ty) async {
    final response = await _dio.get<List<int>>(
      'https://a.basemaps.cartocdn.com/rastertiles/voyager/$z/$tx/$ty@2x.png',
      options: Options(
        responseType: ResponseType.bytes,
        validateStatus: (s) => s == 200,
      ),
    );
    return response.data!;
  }

  Future<List<FeatureDto>> _fetchLayers(
    List<String> layerNames, {
    bool isRoom = false,
  }) async {
    final response = await _dio.get<String>(
      _wfsBase,
      queryParameters: {
        'service': 'WFS',
        'version': '1.1.0',
        'request': 'GetFeature',
        'typeName': layerNames.join(','),
        'outputFormat': 'application/json',
        'SRSNAME': _wfsSrs,
      },
      options: Options(responseType: ResponseType.plain),
    );

    return await compute(_parseFeaturesWorker, {
      'payload': response.data ?? '{}',
      'isRoom': isRoom,
      'excludeKeywords': _excludeKeywords,
    });
  }
}

List<FeatureDto> _parseFeaturesWorker(Map<String, dynamic> args) {
  final payload = args['payload'] as String;
  final isRoom = args['isRoom'] as bool;
  final excludeKeywords = args['excludeKeywords'] as List<String>;

  final data = jsonDecode(payload) as Map<String, dynamic>;
  final featuresList = (data['features'] as List<dynamic>?) ?? [];

  return featuresList
      .map((f) {
        final feat = f as Map<String, dynamic>;
        final geometry = feat['geometry'] as Map<String, dynamic>?;
        final properties =
            feat['properties'] as Map<String, dynamic>? ?? <String, dynamic>{};
        final id = feat['id'] as String? ?? '';

        if (isRoom) {
          final name = properties['room_name'] ?? '';
          final use = properties['use'] ?? '';
          final keyword = properties['keyword'] ?? '';
          final combined = '$name$use$keyword';
          if (excludeKeywords.any((k) => combined.contains(k))) {
            return null;
          }
        }

        final polygons = <List<VectorPoint>>[];
        if (geometry != null) {
          final type = geometry['type'] as String;
          final coords = geometry['coordinates'] as List<dynamic>;

          if (type == 'Polygon') {
            polygons.add(_parsePolygonStatic(coords));
          } else if (type == 'MultiPolygon') {
            for (final polyCoords in coords) {
              polygons.add(_parsePolygonStatic(polyCoords as List<dynamic>));
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
}

List<VectorPoint> _parsePolygonStatic(List<dynamic> rings) {
  if (rings.isEmpty) return [];
  final exteriorRing = rings[0] as List<dynamic>;
  return exteriorRing
      .map((c) => (x: (c[0] as num).toDouble(), y: (c[1] as num).toDouble()))
      .toList();
}
