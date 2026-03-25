import 'dart:async';
import 'dart:developer';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tattoo/services/feature_flag/feature_flag_service.dart';
import 'package:tattoo/services/firebase_service.dart';

/// The model for a UI-consumable feature flag.
class FeatureFlag {
  final String key;
  final dynamic defaultValue;
  final dynamic overrideValue;
  final List<dynamic>? options;
  final bool isForced;

  const FeatureFlag({
    required this.key,
    required this.defaultValue,
    this.overrideValue,
    this.options,
    this.isForced = false,
  });

  dynamic get value => overrideValue ?? defaultValue;
  Type get type => defaultValue.runtimeType;

  // Type-safe getters
  bool get asBool => value as bool;
  int get asInt => value as int;
  double get asDouble => value as double;
  String get asString => value as String;
}

/// Provides the [FeatureFlagRepository] instance.
final featureFlagRepositoryProvider = Provider<FeatureFlagRepository>((ref) {
  return FeatureFlagRepository(
    service: ref.watch(featureFlagServiceProvider),
    prefs: SharedPreferencesAsync(),
  );
});

class FeatureFlagRepository {
  final FeatureFlagService _service;
  final SharedPreferencesAsync _prefs;
  Map<String, dynamic>? _defaultsCache;

  FeatureFlagRepository({
    required FeatureFlagService service,
    required SharedPreferencesAsync prefs,
  }) : _service = service,
       _prefs = prefs;

  Future<Map<String, dynamic>> _getDefaults({bool forceRefresh = false}) async {
    if (forceRefresh) _defaultsCache = null;
    return _defaultsCache ??= await _service.fetchDefaultFlags();
  }

  Future<List<FeatureFlag>> getAllFlags({bool forceRefresh = false}) async {
    final defaults = await _getDefaults(forceRefresh: forceRefresh);
    final list = <FeatureFlag>[];

    final forceOverrideString = defaults['_force_override_flags'] as String?;
    final forceOverrides =
        forceOverrideString
            ?.split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toSet() ??
        const <String>{};

    for (final entry in defaults.entries) {
      final key = entry.key;
      if (key == '_force_override_flags') continue;

      dynamic defVal = entry.value;
      List<dynamic>? options;

      if (defVal is Map<String, dynamic> &&
          defVal.containsKey('value') &&
          defVal.containsKey('options')) {
        options = defVal['options'] as List;
        defVal = defVal['value'];
      }

      dynamic overrideVal;

      final isForced = forceOverrides.contains(key);

      if (!isForced) {
        switch (defVal) {
          case bool _:
            overrideVal = await _prefs.getBool('ff_$key');
          case int _:
            overrideVal = await _prefs.getInt('ff_$key');
          case double _:
            overrideVal = await _prefs.getDouble('ff_$key');
          case String _:
            overrideVal = await _prefs.getString('ff_$key');
        }
      }

      list.add(
        FeatureFlag(
          key: key,
          defaultValue: defVal,
          overrideValue: overrideVal,
          options: options,
          isForced: isForced,
        ),
      );
    }
    return list;
  }

  Future<void> setFlag(String key, dynamic value) async {
    if (value == null) {
      log(
        'Feature flag "$key" reset to default',
        name: 'FeatureFlagRepository',
      );
      firebaseService.log('Feature flag "$key" reset to default');
      await _prefs.remove('ff_$key');
      return;
    }

    log(
      'Feature flag "$key" changed to: $value',
      name: 'FeatureFlagRepository',
    );
    firebaseService.log('Feature flag "$key" changed to: $value');

    switch (value) {
      case bool v:
        await _prefs.setBool('ff_$key', v);
      case int v:
        await _prefs.setInt('ff_$key', v);
      case double v:
        await _prefs.setDouble('ff_$key', v);
      case String v:
        await _prefs.setString('ff_$key', v);
      default:
        throw ArgumentError('Unsupported flag type: ${value.runtimeType}');
    }
  }

  Future<void> resetFlag(String key) async {
    log('Feature flag "$key" reset to default', name: 'FeatureFlagRepository');
    firebaseService.log('Feature flag "$key" reset to default');
    await _prefs.remove('ff_$key');
  }
}
