import 'dart:async';
import 'dart:convert';
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

/// SharedPreferences and Remote Config value type.
enum FeatureFlagType { boolean, integer, double, string }

// dart format off
/// Typed feature flag keys with defaults.
enum FeatureFlagKey<T> {
  /// Toggle for a dummy feature.
  enableDummyFeature<bool>('enable_dummy_feature', .boolean, true),

  /// Toggle for showing the Crowdin button on the about page.
  showCrowdinButton<bool>('show_crowdin_button', .boolean, false),

  /// A dummy string flag.
  dummyString<String>('dummy_string', .string, 'Config from remote'),

  /// A dummy integer flag that is forced by default in assets.
  dummyNumLock<int>('dummy_num_lock', .integer, 114514),

  /// A dummy string flag with predefined options.
  dummyOption<String>(
    'dummy_option',
    .string,
    'system',
    options: ['light', 'dark', 'system'],
  );

  const FeatureFlagKey(
    this.name,
    this.type,
    this.defaultValue, {
    this.options,
  });

  final String name;
  final FeatureFlagType type;
  final T defaultValue;
  final List<T>? options;

  /// Retrieves the key associated with a raw string name, if it exists.
  static FeatureFlagKey? fromName(String name) {
    try {
      return values.firstWhere((e) => e.name == name);
    } catch (_) {
      return null;
    }
  }
}
// dart format on

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

  /// Forces a fresh fetch of feature flags from the remote server.
  Future<void> refreshFlags() async {
    await getAllFlags(forceRefresh: true);
    _updateController.add(null);
  }

  /// Gets a feature flag value, returning the key's default if not set.
  Future<T> get<T>(FeatureFlagKey<T> key) async {
    final flags = await getAllFlags();
    for (final flag in flags) {
      if (flag.key == key.name) return flag.value as T;
    }
    return key.defaultValue;
  }

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
      final localDefaults = jsonDecode(localJson) as Map<String, dynamic>;

      // Stringify complex values (Maps/Lists) for Remote Config defaults,
      // but extract raw values from 'option' structures to keep flags unbundled.
      final defaults = localDefaults.map((key, value) {
        if (value is Map && value['_type'] == 'option') {
          return MapEntry(key, value['value']);
        }
        if (value is Map || value is List) {
          return MapEntry(key, jsonEncode(value));
        }
        return MapEntry(key, value);
      });

      await firebaseService.init(defaults: defaults);

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
    log(
      'Raw defaults from service: ${defaults.map((k, v) => MapEntry(k, v.value))}',
      name: 'FeatureFlagRepository',
    );

    final forceOverrides = _parseForceOverrides(defaults);
    log(
      'Force overrides parsed: $forceOverrides',
      name: 'FeatureFlagRepository',
    );

    // Load local defaults once for option extraction
    Map<String, dynamic> localDefaults = {};
    try {
      final localJson = await _service.loadLocalJson();
      localDefaults = jsonDecode(localJson) as Map<String, dynamic>;
    } catch (e) {
      log('Failed to load local defaults: $e', name: 'FeatureFlagRepository');
    }

    final futures = defaults.entries
        .where((e) => e.key != '_force_override_flags')
        .map((entry) {
          final key = entry.key;
          final data = entry.value;

          dynamic defVal = data.value;
          final isRemote = data.isRemote;
          List<dynamic>? options;

          final knownKey = FeatureFlagKey.fromName(key);
          if (knownKey != null) {
            options = knownKey.options;
          }

          // Try to extract options from local configuration if it's an 'option' structure
          final localValue = localDefaults[key];
          if (localValue is Map && localValue['_type'] == 'option') {
            options ??= localValue['options'] as List?;
          }

          // Unbundle values and extract options if it's an 'option' structure.
          // This handles cases where Remote Config might return the full Map.
          if (defVal is Map<String, dynamic>) {
            if (defVal['_type'] == 'option' ||
                (defVal.containsKey('value') &&
                    defVal.containsKey('options'))) {
              options ??= defVal['options'] as List?;
              defVal = defVal['value'];
            }
          }

          final isForced = forceOverrides.contains(key);

          return () async {
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
          }();
        });

    final result = await Future.wait(futures);
    final logMap = {for (final f in result) f.key: f.value};
    logMap['_force_override_flags'] = forceOverrides.toList();

    log('Feature flags loaded: $logMap', name: 'FeatureFlagRepository');

    final flagKeys = result.map((f) => f.key).toList()..sort();
    firebaseService.log(
      'Feature flags loaded: count=${result.length}, keys=$flagKeys',
    );

    return _flagsCache = result;
  }

  /// Parses the set of flags that are forced by the remote configuration.
  Set<String> _parseForceOverrides(Map<String, FeatureFlagData> defaults) {
    var val = defaults['_force_override_flags']?.value;

    // Handle Map-wrapped values (Riley's old format or accidental nesting)
    if (val is Map && val.containsKey('value')) {
      val = val['value'];
    }

    if (val is List) {
      return val.map((e) => e.toString()).toSet();
    }
    if (val is String) {
      return val
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toSet();
    }
    return const <String>{};
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
    final flags = await getAllFlags();
    final isForced = flags.any((f) => f.key == key && f.isForced);
    if (isForced) {
      log(
        'Feature flag "$key" is forced and cannot be overridden',
        name: 'FeatureFlagRepository',
      );
      return;
    }

    final prefKey = 'ff_$key';
    if (value == null) {
      log(
        'Feature flag "$key" reset to default',
        name: 'FeatureFlagRepository',
      );
      firebaseService.log('Feature flag "$key" reset to default');
      await _prefs.remove(prefKey);
      _flagsCache = null;
      _updateController.add(null);
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
    _updateController.add(null);
  }

  /// Resets a feature flag to its default or remote value by removing any local override.
  Future<void> resetFlag(String key) async {
    log('Feature flag "$key" reset to default', name: 'FeatureFlagRepository');
    firebaseService.log('Feature flag "$key" reset to default');
    await _prefs.remove('ff_$key');
    _flagsCache = null;
    _updateController.add(null);
  }
}
