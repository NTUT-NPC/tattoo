import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:riverpod/riverpod.dart';

/// Provides the [FeatureFlagService] instance.
final featureFlagServiceProvider = Provider<FeatureFlagService>((ref) {
  return LocalFeatureFlagService();
});

/// Abstract interface for fetching feature flags.
abstract interface class FeatureFlagService {
  /// Fetches the default feature flags.
  /// This returns a map constructed from JSON config,
  /// suitable for extension with Firebase Remote Config later.
  Future<Map<String, dynamic>> fetchDefaultFlags();
}

/// Implementation reading flags from the local `assets/feature_flags.json`.
class LocalFeatureFlagService implements FeatureFlagService {
  @override
  Future<Map<String, dynamic>> fetchDefaultFlags() async {
    final jsonString = await rootBundle.loadString('assets/feature_flags.json');
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }
}
