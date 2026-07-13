import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/services/firebase_service.dart';
import 'package:tattoo/services/portal/portal_service.dart';
import 'package:tattoo/utils/avatar_payload.dart';
import 'package:tattoo/utils/pref_type.dart';
import 'package:tattoo/utils/shared_preferences.dart';

export 'package:tattoo/utils/pref_type.dart' show PrefType;

// dart format off
/// Typed preference keys with defaults.
///
/// Each key is a setting whose effective value is resolved through a source
/// stack (see [PreferencesRepository]). Some are user-facing (toggled in the
/// settings UI), others are app-controlled gates managed only via Remote
/// Config and the debug screen.
enum PrefKey<T> {
  /// Whether to use mock data instead of live NTUT services.
  demoMode<bool>(.boolean, false),

  /// Whether the danger zone section is shown on the profile screen.
  showDangerZone<bool>(.boolean, false),

  /// Whether the Crowdin button is shown on the about page.
  showCrowdinButton<bool>(.boolean, false);

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
  Future<void> remove(PrefKey key) => _prefs.remove(key.name);
}

/// Provides the [PreferencesRepository] instance.
final preferencesRepositoryProvider = Provider<PreferencesRepository>((ref) {
  return PreferencesRepository(
    store: ref.watch(typedPreferenceStoreProvider),
    portalService: ref.watch(portalServiceProvider),
    database: ref.watch(databaseProvider),
    authRepository: ref.watch(authRepositoryProvider),
    isLoggedIn: () => ref.read(sessionProvider),
  );
});

/// Manages app preferences and resolves each through a layered source stack.
///
/// Resolution precedence (highest first): forced (Remote Config
/// `_force_override_flags`) > local override (SharedPreferences) > Remote
/// Config value > the key's declared default. Remote Config lets the server
/// control or force a preference; `PrefSource` records which layer answered.
///
/// Supports cloud sync by embedding the user's locally-set values as MessagePack
/// in the avatar file uploaded to NTUT's portal (see [syncUp]/[syncDown]). Only
/// values the user explicitly set are synced — server-controlled and default
/// values are never baked into the payload. Sync runs only while logged in.
class PreferencesRepository {
  final TypedPreferenceStore _store;
  final PortalService _portalService;
  final AppDatabase _database;
  final AuthRepository _authRepository;
  final bool Function() _isLoggedIn;
  final _updateController = StreamController<void>.broadcast();
  bool _syncing = false;

  /// Whether locally-set values have changed since the last successful sync.
  ///
  /// In-memory only: an unsynced edit (made offline or logged out) is not
  /// retried after a restart.
  bool _dirty = false;

  /// Remote Config key holding the list of forced preference names.
  static const _forceOverrideKey = '_force_override_flags';

  PreferencesRepository({
    required this._store,
    required this._portalService,
    required this._database,
    required this._authRepository,
    required this._isLoggedIn,
  });

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

    if (_readForcedSet().contains(key.name)) {
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

  /// Sets a preference's local value and marks state dirty for cloud sync.
  ///
  /// No-op for forced preferences.
  Future<void> set<T>(PrefKey<T> key, T value) async {
    log(
      'Setting preference "${key.name}" to $value',
      name: 'PreferencesRepository',
    );
    if (_readForcedSet().contains(key.name)) {
      log(
        'Preference "${key.name}" is forced and cannot be overridden',
        name: 'PreferencesRepository',
      );
      return;
    }

    await _store.write(key, value);
    _dirty = true;
    _maybeSyncUp();
    _updateController.add(null);
  }

  /// Removes a preference's local value, reverting to remote/default.
  Future<void> reset(PrefKey key) async {
    await _store.remove(key);
    _dirty = true;
    _maybeSyncUp();
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
    return result.isRemote ? result.value : null;
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

  /// Uploads preferences embedded in the current avatar.
  ///
  /// Downloads the current avatar, appends serialized preferences, and
  /// re-uploads. The avatar image is preserved — only the trailing
  /// payload changes.
  ///
  /// If the user has no avatar, the server's generated placeholder is
  /// used as the base image, which becomes the user's new avatar.
  ///
  /// Clears the dirty flag on success.
  Future<void> syncUp() async {
    final user = await _database.select(_database.users).getSingleOrNull();
    // No user row (e.g. logged out mid-sync) — keep _dirty set for a later retry
    if (user == null) return;
    final filename = user.avatarFilename;

    final avatarBytes = await _authRepository.withAuth(
      () => _portalService.getAvatar(filename),
    );

    // Strip any existing payload to avoid nesting
    final (:jpeg, version: _, data: _) = decodeAvatarPayload(avatarBytes);

    final prefs = await _toMap();
    final combined = encodeAvatarPayload(jpeg, prefs);

    final newFilename = await _authRepository.withAuth(
      () => _portalService.uploadAvatar(combined, filename),
    );

    await (_database.update(_database.users)
          ..where((u) => u.id.equals(user.id)))
        .write(UsersCompanion(avatarFilename: Value(newFilename)));

    _dirty = false;
  }

  /// Syncs preferences with the cloud on app launch.
  ///
  /// If local changes were not uploaded (dirty flag set), syncs up first
  /// to avoid overwriting them. Then syncs down to pull any cloud changes.
  Future<void> syncOnLaunch() async {
    if (!_isLoggedIn()) return;
    if (_dirty) await syncUp();
    await syncDown();
  }

  /// Downloads the avatar and restores embedded preferences if present.
  Future<void> syncDown() async {
    final user = await _database.select(_database.users).getSingle();
    final filename = user.avatarFilename;

    final avatarBytes = await _authRepository.withAuth(
      () => _portalService.getAvatar(filename),
    );

    final (:jpeg, :version, :data) = decodeAvatarPayload(avatarBytes);
    if (data == null || version != 0x00) return;

    await _fromMap(data);
  }

  /// Serializes the user's explicitly-set preferences for cloud sync.
  ///
  /// Only values present in local storage are included — server-controlled,
  /// forced, and default values are deliberately omitted so they never get
  /// baked into the synced payload.
  Future<Map<String, dynamic>> _toMap() async {
    final map = <String, dynamic>{};
    for (final key in PrefKey.values) {
      if (await _store.read(key) case final value?) {
        map[key.name] = value;
      }
    }
    return map;
  }

  /// Restores preferences from a cloud sync map.
  ///
  /// Writes directly to SharedPreferences to avoid triggering [set]'s
  /// dirty flag and sync logic.
  Future<void> _fromMap(Map<String, dynamic> map) async {
    await Future.wait([
      for (final key in PrefKey.values)
        if (map[key.name] case final value?) _store.write(key, value),
    ]);
  }

  /// Fire-and-forget sync with coalescing: if already syncing, the dirty
  /// flag ensures one more sync runs after the current one finishes.
  ///
  /// No-op when logged out — the dirty flag persists until the next login.
  Future<void> _maybeSyncUp() async {
    if (!_isLoggedIn() || _syncing) return;
    _syncing = true;
    try {
      while (_dirty) {
        await syncUp();
      }
    } on DioException catch (_) {
      // Network failures are fine — dirty flag persists for next attempt
    } finally {
      _syncing = false;
    }
  }
}
