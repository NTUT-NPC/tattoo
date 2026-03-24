import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:riverpod/riverpod.dart';

/// Provides the [FeatureFlagService] instance.
final featureFlagServiceProvider = Provider<FeatureFlagService>((ref) {
  return FeatureFlagService();
});

/// Service for fetching default feature flags from the local JSON config.
/// Designed for future extension with Firebase Remote Config.
class FeatureFlagService {
  Future<Map<String, dynamic>> fetchDefaultFlags() async {
    final jsonString = await rootBundle.loadString('assets/feature_flags.json');
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }
}
