import 'dart:async';
import 'dart:developer';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tattoo/services/feature_flag/feature_flag_service.dart';

/// The model for a UI-consumable feature flag.
class FeatureFlag {
  final String key;
  final dynamic defaultValue;
  final dynamic overrideValue;
  final List<dynamic>? options;

  const FeatureFlag({
    required this.key,
    required this.defaultValue,
    this.overrideValue,
    this.options,
  });

  dynamic get value => overrideValue ?? defaultValue;
  Type get type => defaultValue is num ? num : defaultValue.runtimeType;

  // Type-safe getters
  bool get asBool => value as bool;
  int get asInt => (value as num).toInt();
  double get asDouble => (value as num).toDouble();
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

  Future<Map<String, dynamic>> _getDefaults() async {
    return _defaultsCache ??= await _service.fetchDefaultFlags();
  }

  Future<List<FeatureFlag>> getAllFlags() async {
    final defaults = await _getDefaults();
    final list = <FeatureFlag>[];

    for (final entry in defaults.entries) {
      final key = entry.key;
      dynamic defVal = entry.value;
      List<dynamic>? options;

      if (defVal is Map<String, dynamic> &&
          defVal.containsKey('value') &&
          defVal.containsKey('options')) {
        options = defVal['options'] as List;
        defVal = defVal['value'];
      }

      dynamic overrideVal;
      switch (defVal) {
        case bool _:
          overrideVal = await _prefs.getBool('ff_$key');
        case num _:
          try {
            overrideVal = await _prefs.getDouble('ff_$key');
          } catch (_) {}
          overrideVal ??= (await _prefs.getInt('ff_$key'))?.toDouble();
        case String _:
          overrideVal = await _prefs.getString('ff_$key');
      }

      list.add(
        FeatureFlag(
          key: key,
          defaultValue: defVal,
          overrideValue: overrideVal,
          options: options,
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
      await _prefs.remove('ff_$key');
      return;
    }

    log(
      'Feature flag "$key" changed to: $value',
      name: 'FeatureFlagRepository',
    );

    switch (value) {
      case bool v:
        await _prefs.setBool('ff_$key', v);
      case num v:
        await _prefs.setDouble('ff_$key', v.toDouble());
      case String v:
        await _prefs.setString('ff_$key', v);
      default:
        throw ArgumentError('Unsupported flag type: ${value.runtimeType}');
    }
  }

  Future<void> resetFlag(String key) async {
    log('Feature flag "$key" reset to default', name: 'FeatureFlagRepository');
    await _prefs.remove('ff_$key');
  }
}
