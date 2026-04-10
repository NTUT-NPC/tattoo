import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tattoo/services/map/map_service.dart';

class MapRepository {
  MapRepository(this._service);

  final MapService _service;
  static const baseUrl = 'https://ntut-map.ntut.club/map/';

  Future<MapManifestDto> getManifest() => _service.getManifest();

  /// Background precache all images to disk.
  void precacheAll(MapManifestDto manifest) {
    final urls = [
      '$baseUrl${manifest.basemap}',
      ...manifest.floors.values.map((f) => '$baseUrl$f'),
    ];

    for (final url in urls) {
      // ignore: unawaited_futures
      DefaultCacheManager().downloadFile(url);
    }
  }
}

final mapRepositoryProvider = Provider<MapRepository>((ref) {
  final service = ref.watch(mapServiceProvider);
  return MapRepository(service);
});

final mapManifestProvider = FutureProvider<MapManifestDto>((ref) {
  final repository = ref.watch(mapRepositoryProvider);
  return repository.getManifest();
});

class SelectedFloorNotifier extends Notifier<String?> {
  @override
  String? build() => '1F';

  void set(String? value) => state = value;
}

final selectedFloorProvider = NotifierProvider<SelectedFloorNotifier, String?>(
  SelectedFloorNotifier.new,
);
