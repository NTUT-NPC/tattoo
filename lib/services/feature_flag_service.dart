import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tattoo/services/firebase_service.dart';

/// Represents a raw feature flag value and its remote status.
typedef FeatureFlagData = ({dynamic value, bool isRemote});

/// Provides the [FeatureFlagService] instance.
final featureFlagServiceProvider = Provider<FeatureFlagService>((ref) {
  return FeatureFlagService();
});

/// A service responsible for loading feature flag definitions from local assets
/// and merging them with Firebase Remote Config overrides.
class FeatureFlagService {
  /// Loads the base feature flag configuration from `assets/feature_flags.json`.
  Future<String> loadLocalJson() async {
    return await rootBundle.loadString('assets/feature_flags.json');
  }

  /// Fetches and merges feature flags from local defaults and Remote Config.
  ///
  /// Local defaults from `assets/feature_flags.json` serve as the baseline.
  /// If Remote Config is available and contains a key present in the defaults,
  /// the remote value takes precedence. Any keys present only in Remote Config
  /// are also included.
  Future<Map<String, FeatureFlagData>> fetchDefaultFlags() async {
    final jsonString = await loadLocalJson();
    final localDefaults = jsonDecode(jsonString) as Map<String, dynamic>;

    final finalFlags = <String, FeatureFlagData>{};

    for (final entry in localDefaults.entries) {
      final key = entry.key;
      final localValue = entry.value;

      dynamic defaultValueToMatch = localValue;
      if (localValue is Map && localValue['_type'] == 'option') {
        defaultValueToMatch = localValue['value'];
      }

      final result = firebaseService.getRemoteConfigValue(
        key,
        defaultValueToMatch,
      );
      finalFlags[key] = (value: result.value, isRemote: result.isRemote);
    }

    // Add any keys that are ONLY in remote
    final allRemote = firebaseService.getAllRemoteConfigValues();
    for (final entry in allRemote.entries) {
      if (!finalFlags.containsKey(entry.key) && entry.value.isRemote) {
        finalFlags[entry.key] = entry.value;
      }
    }

    return finalFlags;
  }
}
