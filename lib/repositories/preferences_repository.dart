import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tattoo/services/firebase_service.dart';
import 'package:tattoo/utils/pref_type.dart';
import 'package:tattoo/utils/shared_preferences.dart';

export 'package:tattoo/utils/pref_type.dart' show PrefType;

const defaultISchoolPlusNetworkGuideUrl =
    'https://cnc.ntut.edu.tw/p/405-1004-110297.php?Lang=zh-tw';

Uri iSchoolPlusNetworkGuideUri(String configuredUrl) {
  final configured = Uri.tryParse(configuredUrl);
  if (configured != null &&
      (configured.scheme == 'http' || configured.scheme == 'https') &&
      configured.host.isNotEmpty) {
    return configured;
  }
  return Uri.parse(defaultISchoolPlusNetworkGuideUrl);
}

// dart format off
/// Typed preference keys with defaults.
///
/// Each key is a setting whose effective value is resolved through a source
/// stack (see [PreferencesRepository]). Some are user-facing (toggled in the
/// settings UI), others are app-controlled gates managed only via Remote
/// Config and the debug screen.
enum PrefKey<T> {
  /// Whether authenticated navigation starts on the course table instead of home.
  startWithCourseTable<bool>(.boolean, false),

  /// Last app version whose new features were opened.
  lastSeenWhatsNewVersion<String>(.string, ''),

  /// Version associated with the new-feature prompt counter.
  lastPromptedWhatsNewVersion<String>(.string, ''),

  /// Number of new-feature prompts shown for that version.
  whatsNewPromptCount<int>(.integer, 0),

  /// The app theme mode: system, light, or dark.
  themeMode<String>(.string, 'system'),

  /// Whether the danger zone section is shown on the profile screen.
  showDangerZone<bool>(.boolean, false),

  /// Whether the Weblate button is shown on the about page.
  showWeblateButton<bool>(.boolean, false),

  /// Whether campus Wi-Fi UI, setup, and automatic credential refresh are enabled.
  showWifiButton<bool>(.boolean, false),

  /// Whether to show the detailed error dialog on uncaught exceptions.
  ///
  /// Defaults to `kDebugMode` (true in debug, false in release). Can be
  /// overridden via the regedit screen or Remote Config for on-device debugging.
  showErrorDialog<bool>(.boolean, kDebugMode),

  /// Whether the next course schedule carousel is shown on the home screen.
  showCourseSchedule<bool>(.boolean, true),

  /// Whether the iStudy QR scanner button is shown on the home screen.
  showScannerButton<bool>(.boolean, true),

  /// Whether the portal entry button is shown on the home screen.
  showPortalButton<bool>(.boolean, true),

  /// Whether the academic calendar button is shown on the home screen.
  showCalendarButton<bool>(.boolean, true),

  /// Whether the campus map entry button is shown on the home screen.
  showCampusMapButton<bool>(.boolean, true),

  /// Whether the student union entry button is shown on the home screen.
  showStudentUnionButton<bool>(.boolean, true),

  /// Whether the change password button is shown on the profile screen.
  showChangePasswordButton<bool>(.boolean, true),

  /// Whether the change avatar button is shown on the profile screen.
  showChangeAvatarButton<bool>(.boolean, true),

  /// Whether the I-School Plus student roster is shown in course details.
  showCourseRoster<bool>(.boolean, true),

  /// Whether the campus map building menu lists buildings hidden from the map.
  showAllCampusMapBuildings<bool>(.boolean, false),
  /// Whether I-School Plus materials are shown in course details.
  showCourseMaterials<bool>(.boolean, true),

  /// Link to instructions for connecting to the NTUT network remotely.
  iSchoolPlusNetworkGuideUrl<String>(.string, defaultISchoolPlusNetworkGuideUrl),

  /// Student union link URL overrides as a JSON array of `{id, url}` objects.
  ///
  /// See `parseLinkUrlOverrides` for the format.
  studentUnionLinks<String>(.string, '[]');

  const PrefKey(this.type, this.defaultValue);
  final PrefType type;
  final T defaultValue;
}
// dart format on

/// Where a preference's effective value came from.
enum PrefSource {
  /// The key's declared default value.
  local,

  /// A value provided by Firebase Remote Config.
  remote,

  /// A value set locally by the user (or via the debug screen).
  override,

  /// A value forced by Remote Config, ignoring any local override.
  forced,
}

/// A preference's resolved value and the source that produced it.
class ResolvedPreference {
  final PrefKey key;
  final Object value;
  final PrefSource source;

  const ResolvedPreference({
    required this.key,
    required this.value,
    required this.source,
  });

  /// The preference's storage/Remote Config key name.
  String get name => key.name;

  /// The key's declared default value.
  Object get defaultValue => key.defaultValue as Object;

  /// Whether the value is forced by Remote Config and cannot be overridden.
  bool get isForced => source == .forced;

  /// The value type of the preference.
  PrefType get type => key.type;

  @override
  String toString() => '$name: $value (${source.name})';
}

/// Provides the [TypedPreferenceStore] backed by the app's
/// [SharedPreferencesAsync] singleton.
final typedPreferenceStoreProvider = Provider<TypedPreferenceStore>((ref) {
  return TypedPreferenceStore(ref.watch(sharedPreferencesProvider));
});

/// A typed wrapper over [SharedPreferencesAsync], keyed by [PrefKey].
///
/// Centralizes the `switch (PrefType)` dispatch to the type-specific
/// SharedPreferences accessors, inferring the storage name and value type from
/// the [PrefKey] itself.
class TypedPreferenceStore {
  final SharedPreferencesAsync _prefs;

  const TypedPreferenceStore(this._prefs);

  /// Reads the value stored for [key], or `null` if absent.
  Future<T?> read<T>(PrefKey<T> key) async {
    final value = switch (key.type) {
      .boolean => await _prefs.getBool(key.name),
      .integer => await _prefs.getInt(key.name),
      .double => await _prefs.getDouble(key.name),
      .string => await _prefs.getString(key.name),
      .stringList => await _prefs.getStringList(key.name),
    };
    return value as T?;
  }

  /// Writes [value] for [key], dispatching on the key's type.
  Future<void> write<T>(PrefKey<T> key, T value) async {
    await switch (key.type) {
      .boolean => _prefs.setBool(key.name, value as bool),
      .integer => _prefs.setInt(key.name, value as int),
      .double => _prefs.setDouble(key.name, value as double),
      .string => _prefs.setString(key.name, value as String),
      .stringList => _prefs.setStringList(key.name, value as List<String>),
    };
  }

  /// Removes any value stored for [key].
  Future<void> remove(PrefKey key) async {
    await _prefs.remove(key.name);
  }
}

/// Provides the [PreferencesRepository] instance.
final preferencesRepositoryProvider = Provider<PreferencesRepository>((ref) {
  return PreferencesRepository(
    store: ref.watch(typedPreferenceStoreProvider),
  );
});

/// Manages app preferences and resolves each through a layered source stack.
///
/// Resolution precedence (highest first): forced (Remote Config
/// `_force_override_flags`) > local override (SharedPreferences) > Remote
/// Config value > the key's declared default. Remote Config lets the server
/// control or force a preference; `PrefSource` records which layer answered.
class PreferencesRepository {
  final TypedPreferenceStore _store;
  final _updateController = StreamController<void>.broadcast();

  /// Remote Config key holding the list of forced preference names.
  static const _forceOverrideKey = '_force_override_flags';

  PreferencesRepository({required this._store});

  /// Emits whenever a resolved value may have changed (override set/reset or a
  /// Remote Config update).
  Stream<void> get onUpdated => _updateController.stream;

  /// Seeds Remote Config defaults from [PrefKey.values] and wires updates.
  ///
  /// Call once at app start (before login).
  Future<void> init() async {
    try {
      final defaults = {
        for (final key in PrefKey.values) key.name: key.defaultValue,
      };
      await firebaseService.init(defaults: defaults);
      firebaseService.onConfigUpdated.listen(
        (_) => _updateController.add(null),
      );
    } catch (e) {
      log(
        'Failed to initialize Remote Config: $e',
        name: 'PreferencesRepository',
      );
    }
  }

  /// Gets a preference's effective value, resolving the source stack.
  Future<T> get<T>(PrefKey<T> key) async => (await resolve(key)).value as T;

  /// Resolves every preference through the source stack.
  Future<List<ResolvedPreference>> resolveAll() =>
      Future.wait(PrefKey.values.map(resolve));

  /// Resolves one preference by walking the source stack (highest first).
  Future<ResolvedPreference> resolve(PrefKey key) async {
    final remote = _readRemote(key);

    if (_isForced(key)) {
      return ResolvedPreference(
        key: key,
        value: remote ?? key.defaultValue as Object,
        source: .forced,
      );
    }

    final override = await _store.read(key);
    if (override != null) {
      return ResolvedPreference(key: key, value: override, source: .override);
    }

    if (remote != null) {
      return ResolvedPreference(key: key, value: remote, source: .remote);
    }

    return ResolvedPreference(
      key: key,
      value: key.defaultValue as Object,
      source: .local,
    );
  }

  /// Sets a preference's local value.
  ///
  /// No-op for forced preferences.
  Future<void> set<T>(PrefKey<T> key, T value) async {
    log(
      'Setting preference "${key.name}" to $value',
      name: 'PreferencesRepository',
    );
    if (_isForced(key)) {
      log(
        'Preference "${key.name}" is forced and cannot be overridden',
        name: 'PreferencesRepository',
      );
      return;
    }

    await _store.write(key, value);
    _updateController.add(null);
  }

  /// Removes a preference's local value, reverting to remote/default.
  Future<void> reset(PrefKey key) async {
    await _store.remove(key);
    _updateController.add(null);
  }

  /// Forces a fresh Remote Config fetch and re-emits.
  Future<void> refresh() async {
    await firebaseService.fetch();
    _updateController.add(null);
  }

  /// Reads a key's Remote Config value, or `null` if not remotely set.
  Object? _readRemote(PrefKey key) {
    final result = firebaseService.getRemoteConfigTyped(key.name, key.type);
    if (result.isRemote) return result.value;
    return null;
  }

  bool _isForced(PrefKey key) {
    final forced = _readForcedSet();
    return forced.contains(key.name);
  }

  /// Reads the set of forced preference names from Remote Config.
  ///
  /// The value may be a JSON array string or a comma-separated string. Empty
  /// when Firebase is disabled, so nothing is forced offline.
  Set<String> _readForcedSet() {
    final result = firebaseService.getRemoteConfigTyped(
      _forceOverrideKey,
      .string,
    );
    if (result.value is! String) return const {};
    log(
      "Forced override flags: ${result.value}",
      name: 'PreferencesRepository',
    );
    final raw = result.value as String;
    try {
      if (jsonDecode(raw) case final List<dynamic> decoded) {
        return decoded.map((e) => e.toString()).toSet();
      }
    } catch (_) {
      // Not JSON — fall back to comma-separated parsing.
    }
    return raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet();
  }
}
