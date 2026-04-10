import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef MapManifestDto = ({
  String basemap,
  Map<String, String> floors,
});

abstract interface class MapService {
  Future<MapManifestDto> getManifest();
}

class NtutMapService implements MapService {
  NtutMapService(this._dio);

  final Dio _dio;
  static const _baseUrl = 'https://ntut-map.ntut.club/map/';

  @override
  Future<MapManifestDto> getManifest() async {
    final response = await _dio.get('${_baseUrl}manifest.json');
    final data = response.data as Map<String, dynamic>;

    return (
      basemap: data['basemap'] as String,
      floors: Map<String, String>.from(data['floors'] as Map),
    );
  }
}

final mapServiceProvider = Provider<MapService>((ref) {
  // Use a fresh Dio instance for external assets to avoid interfering with NTUT cookie jar if needed,
  // but here we can just use a simple one.
  return NtutMapService(Dio());
});
