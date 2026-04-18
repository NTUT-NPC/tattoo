import 'dart:async';
import 'dart:developer';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tattoo/services/feature_flag_service.dart';
import 'package:tattoo/services/firebase_service.dart';
import 'package:tattoo/utils/shared_preferences.dart';

/// Defines the origin of a feature flag value.
enum FeatureFlagSource {
  /// Default value defined in the local JSON configuration.
  local,

  /// Value provided by Firebase Remote Config.
  remote,

  /// Value manually set by the user via the debug/profile UI.
  override,

  /// Value forced by the server, ignoring any local overrides.
  forced,
}

/// A model representing a feature flag with its state and source information.
class FeatureFlag {
  /// The unique identifier for the feature flag.
  final String key;

  /// The fallback value if no remote or local override exists.
  final dynamic defaultValue;

  /// The locally stored value that overrides the default or remote value.
  final dynamic overrideValue;

  /// Optional list of permitted values for this flag (e.g., for selection UI).
  final List<dynamic>? options;

  /// Whether this flag is currently forced by a remote configuration,
  /// preventing local overrides.
  final bool isForced;

  /// Whether the current effective value (if not overridden) comes from a remote source.
  final bool isRemote;

  const FeatureFlag({
    required this.key,
    required this.defaultValue,
    this.overrideValue,
    this.options,
    this.isForced = false,
    this.isRemote = false,
  });

  /// The effective value of the feature flag, prioritizing local overrides.
  dynamic get value => overrideValue ?? defaultValue;

  /// The runtime type of the flag's value.
  Type get type => defaultValue.runtimeType;

  /// Determines the source of the current effective value.
  FeatureFlagSource get source {
    if (isForced) return FeatureFlagSource.forced;
    if (overrideValue != null) return FeatureFlagSource.override;
    if (isRemote) return FeatureFlagSource.remote;
    return FeatureFlagSource.local;
  }

  @override
  String toString() => '$key: $value (${source.name})';
}

/// Provides the [FeatureFlagRepository] instance.
final featureFlagRepositoryProvider = Provider<FeatureFlagRepository>((ref) {
  return FeatureFlagRepository(
    service: ref.watch(featureFlagServiceProvider),
    prefs: ref.watch(sharedPreferencesProvider),
  );
});

/// Manages the lifecycle, storage, and retrieval of feature flags.
///
/// This repository coordinates between local defaults, remote configurations,
/// and persistent user overrides.
class FeatureFlagRepository {
  final FeatureFlagService _service;
  final SharedPreferencesAsync _prefs;
  final _updateController = StreamController<void>.broadcast();
  Map<String, FeatureFlagData>? _defaultsCache;
  List<FeatureFlag>? _flagsCache;

  FeatureFlagRepository({
    required FeatureFlagService service,
    required SharedPreferencesAsync prefs,
  }) : _service = service,
       _prefs = prefs;

  /// A stream that emits whenever feature flags are updated from a remote source.
  Stream<void> get onUpdated => _updateController.stream;

  /// Fetches default values, utilizing an in-memory cache.
  Future<Map<String, FeatureFlagData>> _getDefaults({
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) _defaultsCache = null;
    return _defaultsCache ??= await _service.fetchDefaultFlags();
  }

  /// Initializes the repository by loading local defaults into Remote Config
  /// and warming up the flag cache.
  Future<void> init() async {
    // Initialize Remote Config with local defaults
    try {
      final localJson = await _service.loadLocalJson();
      await firebaseService.init(defaults: {'feature_flags': localJson});

      // Listen for remote updates
      firebaseService.onConfigUpdated.listen((_) {
        log(
          'Remote Config updated, invalidating feature flag cache',
          name: 'FeatureFlagRepository',
        );
        _defaultsCache = null;
        _flagsCache = null;
        _updateController.add(null);
      });
    } catch (e) {
      log(
        'Failed to initialize Remote Config defaults: $e',
        name: 'FeatureFlagRepository',
      );
    }

    await getAllFlags();
    log('FeatureFlagRepository initialized', name: 'FeatureFlagRepository');
  }

  /// Retrieves all available feature flags, merging defaults with user overrides.
  ///
  /// If [forceRefresh] is true, it triggers a fetch from the remote server.
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

    final flagKeys = result.map((f) => f.key).toList()..sort();
    firebaseService.log(
      'Feature flags loaded: count=${result.length}, keys=$flagKeys',
    );

    return _flagsCache = result;
  }

  /// Parses the set of flags that are forced by the remote configuration.
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

  /// Creates a [FeatureFlag] instance for a specific key by checking for overrides.
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

  /// Retrieves a persistent local override for a given flag.
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

  /// Persistently overrides a feature flag value.
  ///
  /// Passing `null` as the [value] will remove the override.
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

  /// Resets a feature flag to its default or remote value by removing any local override.
  Future<void> resetFlag(String key) async {
    log('Feature flag "$key" reset to default', name: 'FeatureFlagRepository');
    firebaseService.log('Feature flag "$key" reset to default');
    await _prefs.remove('ff_$key');
    _flagsCache = null;
  }
}
