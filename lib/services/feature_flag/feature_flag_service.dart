import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tattoo/services/firebase_service.dart';

/// Provides the [FeatureFlagService] instance.
final featureFlagServiceProvider = Provider<FeatureFlagService>((ref) {
  return FeatureFlagService();
});

/// Service for fetching default feature flags from the local JSON config.
/// Extended with Firebase Remote Config to allow remote overrides.
class FeatureFlagService {
  Future<Map<String, dynamic>> fetchDefaultFlags() async {
    final jsonString = await rootBundle.loadString('assets/feature_flags.json');
    final localDefaults = jsonDecode(jsonString) as Map<String, dynamic>;

    final remoteJsonString = await firebaseService.fetchRemoteConfigString('feature_flags');
    if (remoteJsonString != null && remoteJsonString.isNotEmpty) {
      try {
        final remoteJson = jsonDecode(remoteJsonString) as Map<String, dynamic>;
        localDefaults.addAll(remoteJson);
      } catch (e) {
        firebaseService.log('Failed to decode feature_flags remote config: $e');
      }
    }

    return localDefaults;
  }
}
