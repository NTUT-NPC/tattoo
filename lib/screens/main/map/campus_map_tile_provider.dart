import 'dart:io';

import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart';
import 'package:native_dio_adapter/native_dio_adapter.dart';

/// Loads visible OSM tiles with HTTP caching and the campus-compatible TLS stack.
///
/// Owns its HTTP client for the lifetime of a map viewport. Native clients also
/// support aborting tiles that leave the viewport during a pan or zoom.
/// Failed tiles stay transparent so cached campus outlines remain usable.
class CampusMapTileProvider extends NetworkTileProvider {
  /// Creates a native mobile or standard desktop client with a bounded cache.
  CampusMapTileProvider() : this._(_createClient());

  CampusMapTileProvider._(Client client)
    : _client = client,
      super(
        httpClient: client,
        silenceExceptions: true,
        cachingProvider: BuiltInMapCachingProvider.getOrCreateInstance(
          maxCacheSize: 64 * 1024 * 1024,
        ),
      );

  final Client _client;

  static Client _createClient() {
    if (Platform.isAndroid) return CronetClient.defaultCronetEngine();
    if (Platform.isIOS) return CupertinoClient.defaultSessionConfiguration();
    return Client();
  }

  @override
  Future<void> dispose() async {
    _client.close();
    await super.dispose();
  }
}
