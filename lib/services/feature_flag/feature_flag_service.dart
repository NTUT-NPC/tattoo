import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tattoo/services/firebase_service.dart';

typedef FeatureFlagData = ({dynamic value, bool isRemote});

/// Provides the [FeatureFlagService] instance.
final featureFlagServiceProvider = Provider<FeatureFlagService>((ref) {
  return FeatureFlagService();
});

/// Service for fetching default feature flags from the local JSON config.
/// Extended with Firebase Remote Config to allow remote overrides.
class FeatureFlagService {
  Future<Map<String, FeatureFlagData>> fetchDefaultFlags() async {
    final jsonString = await rootBundle.loadString('assets/feature_flags.json');
    final localDefaults = jsonDecode(jsonString) as Map<String, dynamic>;

    final result = await firebaseService.fetchRemoteConfigString(
      'feature_flags',
      defaults: {'feature_flags': jsonString},
    );

    final finalFlags = <String, FeatureFlagData>{};

    Map<String, dynamic> remoteJson = {};
    if (result.value != null && result.value!.isNotEmpty) {
      try {
        remoteJson = jsonDecode(result.value!) as Map<String, dynamic>;
      } catch (e) {
        firebaseService.log('Failed to decode feature_flags remote config: $e');
      }
    }

    for (final entry in localDefaults.entries) {
      final key = entry.key;
      final localValue = entry.value;

      if (result.isRemote && remoteJson.containsKey(key)) {
        finalFlags[key] = (value: remoteJson[key], isRemote: true);
      } else {
        finalFlags[key] = (value: localValue, isRemote: false);
      }
    }

    // Add any keys that are ONLY in remote
    if (result.isRemote) {
      for (final entry in remoteJson.entries) {
        if (!finalFlags.containsKey(entry.key)) {
          finalFlags[entry.key] = (value: entry.value, isRemote: true);
        }
      }
    }

    return finalFlags;
  }
}
