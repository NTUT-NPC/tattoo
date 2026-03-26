import 'dart:async';
import 'dart:developer';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tattoo/services/feature_flag/feature_flag_service.dart';
import 'package:tattoo/services/firebase_service.dart';

enum FeatureFlagSource {
  local,
  remote,
  override,
  forced,
}

/// The model for a UI-consumable feature flag.
class FeatureFlag {
  final String key;
  final dynamic defaultValue;
  final dynamic overrideValue;
  final List<dynamic>? options;
  final bool isForced;
  final bool isRemote;

  const FeatureFlag({
    required this.key,
    required this.defaultValue,
    this.overrideValue,
    this.options,
    this.isForced = false,
    this.isRemote = false,
  });

  dynamic get value => overrideValue ?? defaultValue;
  Type get type => defaultValue.runtimeType;

  FeatureFlagSource get source {
    if (isForced) return FeatureFlagSource.forced;
    if (overrideValue != null) return FeatureFlagSource.override;
    if (isRemote) return FeatureFlagSource.remote;
    return FeatureFlagSource.local;
  }

  // Type-safe getters
  bool get asBool => value as bool;
  int get asInt => value as int;
  double get asDouble => value as double;
  String get asString => value as String;

  @override
  String toString() => '$key: $value (${source.name})';
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
  Map<String, FeatureFlagData>? _defaultsCache;
  List<FeatureFlag>? _flagsCache;

  FeatureFlagRepository({
    required FeatureFlagService service,
    required SharedPreferencesAsync prefs,
  }) : _service = service,
       _prefs = prefs;

  Future<Map<String, FeatureFlagData>> _getDefaults({
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) _defaultsCache = null;
    return _defaultsCache ??= await _service.fetchDefaultFlags();
  }

  /// Initializes the repository by warming up the cache.
  Future<void> init() async {
    await getAllFlags();
    log('FeatureFlagRepository initialized', name: 'FeatureFlagRepository');
  }

  Future<List<FeatureFlag>> getAllFlags({bool forceRefresh = false}) async {
    if (forceRefresh) {
      log('Forcing fresh load of feature flags', name: 'FeatureFlagRepository');
      _defaultsCache = null;
      _flagsCache = null;
      await firebaseService.fetch();
    }

    if (_flagsCache != null) return _flagsCache!;

    final defaults = await _getDefaults(forceRefresh: forceRefresh);
    final forceOverrides = _parseForceOverrides(defaults);

    final futures = defaults.entries
        .where((e) => e.key != '_force_override_flags')
        .map(
          (entry) => _createFeatureFlag(entry.key, entry.value, forceOverrides),
        );

    final result = await Future.wait(futures);
    final logMap = {for (final f in result) f.key: f.value};

    log('Feature flags loaded: $logMap', name: 'FeatureFlagRepository');
    firebaseService.log('Feature flags loaded: $logMap');

    return _flagsCache = result;
  }

  Set<String> _parseForceOverrides(Map<String, FeatureFlagData> defaults) {
    final forceOverrideString =
        defaults['_force_override_flags']?.value as String?;
    return forceOverrideString
            ?.split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toSet() ??
        const <String>{};
  }

  Future<FeatureFlag> _createFeatureFlag(
    String key,
    FeatureFlagData data,
    Set<String> forceOverrides,
  ) async {
    dynamic defVal = data.value;
    final isRemote = data.isRemote;
    List<dynamic>? options;

    if (defVal is Map<String, dynamic> &&
        defVal.containsKey('value') &&
        defVal.containsKey('options')) {
      options = defVal['options'] as List;
      defVal = defVal['value'];
    }

    final isForced = forceOverrides.contains(key);
    dynamic overrideVal;

    if (!isForced) {
      overrideVal = await _getOverrideValue(key, defVal);
    }

    return FeatureFlag(
      key: key,
      defaultValue: defVal,
      overrideValue: overrideVal,
      options: options,
      isForced: isForced,
      isRemote: isRemote,
    );
  }

  Future<dynamic> _getOverrideValue(String key, dynamic defVal) async {
    final prefKey = 'ff_$key';
    return switch (defVal) {
      bool _ => await _prefs.getBool(prefKey),
      int _ => await _prefs.getInt(prefKey),
      double _ => await _prefs.getDouble(prefKey),
      String _ => await _prefs.getString(prefKey),
      _ => null,
    };
  }

  Future<void> setFlag(String key, dynamic value) async {
    final prefKey = 'ff_$key';
    if (value == null) {
      log(
        'Feature flag "$key" reset to default',
        name: 'FeatureFlagRepository',
      );
      firebaseService.log('Feature flag "$key" reset to default');
      await _prefs.remove(prefKey);
      return;
    }

    log(
      'Feature flag "$key" changed to: $value',
      name: 'FeatureFlagRepository',
    );
    firebaseService.log('Feature flag "$key" changed to: $value');

    await (switch (value) {
      bool v => _prefs.setBool(prefKey, v),
      int v => _prefs.setInt(prefKey, v),
      double v => _prefs.setDouble(prefKey, v),
      String v => _prefs.setString(prefKey, v),
      _ => throw ArgumentError('Unsupported flag type: ${value.runtimeType}'),
    });

    _flagsCache = null;
  }

  Future<void> resetFlag(String key) async {
    log('Feature flag "$key" reset to default', name: 'FeatureFlagRepository');
    firebaseService.log('Feature flag "$key" reset to default');
    await _prefs.remove('ff_$key');
    _flagsCache = null;
  }
}
