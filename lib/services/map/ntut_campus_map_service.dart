import 'dart:io';
import 'dart:math';

import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:tattoo/services/map/campus_map_parser.dart';
import 'package:tattoo/services/map/campus_map_service.dart';
import 'package:tattoo/utils/http.dart';
import 'package:xml/xml.dart';

/// The NTUT GeoServer WFS client.
class NtutCampusMapService implements CampusMapService {
  /// Creates a client, optionally using an injected [dio] for protocol tests.
  ///
  /// The caller owns an injected client. The default client uses Dart's TLS
  /// stack on every platform and accepts an invalid certificate only for the
  /// GeoServer host, whose server-side TLS setup is unreliable (it omits the
  /// intermediate certificate from its chain). Other hosts are still validated.
  NtutCampusMapService({Dio? dio})
    : _dio = dio ?? _createDio(),
      _ownsDio = dio == null;

  final Dio _dio;
  final bool _ownsDio;

  static const _endpoint = 'https://geoserver.oga.ntut.edu.tw/ows';
  static const _endpointHost = 'geoserver.oga.ntut.edu.tw';

  static Dio _createDio() => createDio()
    ..options.connectTimeout = const Duration(seconds: 15)
    ..options.receiveTimeout = const Duration(seconds: 30)
    ..httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () =>
          HttpClient()
            ..badCertificateCallback = (_, host, _) => host == _endpointHost,
    );

  Future<String> _request(
    String request, [
    Map<String, String>? parameters,
  ]) async {
    final response = await _dio.get<String>(
      _endpoint,
      queryParameters: {
        'service': 'WFS',
        'version': '1.1.0',
        'request': request,
        ...?parameters,
      },
      options: Options(responseType: .plain),
    );
    return response.data ?? '';
  }

  Future<String> _features(
    List<String> layers, {
    bool metadataOnly = false,
  }) async {
    final response = await _request('GetFeature', {
      'typeName': layers.join(','),
      'outputFormat': 'application/json',
      'SRSNAME': 'EPSG:4326',
      if (metadataOnly) 'propertyName': 'room_name,room_name_en,class_num',
    });
    if (response.trimLeft().startsWith('<')) {
      final document = XmlDocument.parse(response);
      for (final element in document.descendants.whereType<XmlElement>()) {
        if (element.name.local != 'ExceptionText') continue;
        // GeoServer advertises a few layers whose backing table is absent.
        // Only this explicit absence is safe to treat as an empty layer;
        // a timeout or another server exception must fail the entire search.
        final missing = RegExp(r"Schema '([^']+)' does not exist\.")
            .firstMatch(element.innerText);
        if (missing == null) continue;
        final name = layers
            .where((name) => name.split(':').last == missing[1])
            .firstOrNull;
        if (name != null) throw _UnavailableLayer(name);
      }
    }
    return response;
  }

  @override
  Future<List<CampusMapBuildingDto>> getBuildings() async => compute(
    parseCampusMapBuildings,
    await _features(['gis:gis_building_geom']),
  );

  @override
  Future<List<CampusMapLayerDto>> getLayers() async => compute(
    parseCampusMapLayers,
    await _request('GetCapabilities'),
  );

  @override
  Future<List<CampusMapRoomDto>> getRooms(String layerName) async {
    _validateLayer(layerName);
    try {
      return await compute(parseCampusMapRooms, await _features([layerName]));
    } on _UnavailableLayer {
      return [];
    }
  }

  @override
  Future<List<CampusMapRoomDto>> getRoomIndex(List<String> layerNames) async {
    for (final layer in layerNames) {
      _validateLayer(layer);
    }
    final rooms = <CampusMapRoomDto>[];
    const batchSize = 25;
    for (var start = 0; start < layerNames.length; start += batchSize) {
      final batch = layerNames.sublist(
        start,
        min(start + batchSize, layerNames.length),
      );
      final remaining = List<String>.of(batch);
      while (remaining.isNotEmpty) {
        try {
          rooms.addAll(
            await compute(
              parseCampusMapRooms,
              await _features(remaining, metadataOnly: true),
            ),
          );
          break;
        } on _UnavailableLayer catch (error) {
          remaining.remove(error.name);
        }
      }
    }
    return rooms;
  }

  void _validateLayer(String name) {
    if (!campusMapLayerPattern.hasMatch(name)) {
      throw ArgumentError.value(name, 'layerName', 'Not an indoor WFS layer');
    }
  }

  /// Releases the default HTTP client; injected clients remain caller-owned.
  void close() {
    if (_ownsDio) _dio.close(force: true);
  }
}

class _UnavailableLayer implements Exception {
  const _UnavailableLayer(this.name);
  final String name;
}
