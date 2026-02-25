import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/services/portal_service.dart';
import 'package:tattoo/utils/avatar_payload.dart';
import 'package:tattoo/utils/shared_preferences.dart';

/// SharedPreferences value type, used to dispatch to the correct accessor.
enum PrefType { boolean, integer, double, string, stringList }

// dart format off
/// Typed preference keys with defaults.
enum PrefKey<T> {
  /// Whether to use mock data instead of live NTUT services.
  demoMode<bool>(PrefType.boolean, false);

  const PrefKey(this.type, this.defaultValue);
  final PrefType type;
  final T defaultValue;
}
// dart format on

/// Provides the [PreferencesRepository] instance.
final preferencesRepositoryProvider = Provider<PreferencesRepository>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);

  return PreferencesRepository(
    prefs: ref.watch(sharedPreferencesProvider),
    portalService: ref.watch(portalServiceProvider),
    database: ref.watch(databaseProvider),
    withAuth: authRepo.withAuth,
  );
});

/// Manages app preferences: demo mode, color customizations, onboarding status.
///
/// Supports cloud sync by embedding preferences as MessagePack in the
/// avatar file uploaded to NTUT's portal. See [syncUp] and [syncDown].
class PreferencesRepository {
  final SharedPreferencesAsync _prefs;
  final PortalService _portalService;
  final AppDatabase _database;
  final Future<T> Function<T>(Future<T> Function()) _withAuth;
  bool _syncing = false;

  /// Internal key for persisting the dirty flag across app restarts.
  static const _dirtyKey = '_prefsSyncDirty';

  PreferencesRepository({
    required SharedPreferencesAsync prefs,
    required PortalService portalService,
    required AppDatabase database,
    required Future<T> Function<T>(Future<T> Function()) withAuth,
  }) : _prefs = prefs,
       _portalService = portalService,
       _database = database,
       _withAuth = withAuth;

  /// Gets a preference value, returning the key's default if not set.
  Future<T> get<T>(PrefKey<T> key) async {
    final value = switch (key.type) {
      PrefType.boolean => await _prefs.getBool(key.name),
      PrefType.integer => await _prefs.getInt(key.name),
      PrefType.double => await _prefs.getDouble(key.name),
      PrefType.string => await _prefs.getString(key.name),
      PrefType.stringList => await _prefs.getStringList(key.name),
    };
    return (value as T?) ?? key.defaultValue;
  }

  /// Sets a preference value and marks local state as dirty for cloud sync.
  Future<void> set<T>(PrefKey<T> key, T value) async {
    switch (key.type) {
      case PrefType.boolean:
        await _prefs.setBool(key.name, value as bool);
      case PrefType.integer:
        await _prefs.setInt(key.name, value as int);
      case PrefType.double:
        await _prefs.setDouble(key.name, value as double);
      case PrefType.string:
        await _prefs.setString(key.name, value as String);
      case PrefType.stringList:
        await _prefs.setStringList(key.name, value as List<String>);
    }
    _dirty = true;
    _maybeSyncUp();
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
    if (user == null) return;

    final avatarBytes = await _withAuth(
      () => _portalService.getAvatar(user.avatarFilename),
    );

    // Strip any existing payload to avoid nesting
    final (:jpeg, version: _, data: _) = decodeAvatarPayload(avatarBytes);

    final prefs = await _toMap();
    final combined = encodeAvatarPayload(jpeg, prefs);

    final newFilename = await _withAuth(
      () => _portalService.uploadAvatar(combined, user.avatarFilename),
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
    if (await _dirty) await syncUp();
    await syncDown();
  }

  /// Downloads the avatar and restores embedded preferences if present.
  Future<void> syncDown() async {
    final user = await _database.select(_database.users).getSingleOrNull();
    if (user == null || user.avatarFilename.isEmpty) return;

    final avatarBytes = await _withAuth(
      () => _portalService.getAvatar(user.avatarFilename),
    );

    final (:jpeg, :version, :data) = decodeAvatarPayload(avatarBytes);
    if (data == null || version != 0x00) return;

    await _fromMap(data);
  }

  /// Serializes all preferences to a map for cloud sync.
  Future<Map<String, dynamic>> _toMap() async {
    return {
      for (final key in PrefKey.values) key.name: await get(key),
    };
  }

  /// Restores preferences from a cloud sync map.
  ///
  /// Writes directly to SharedPreferences to avoid triggering [set]'s
  /// dirty flag and sync logic.
  Future<void> _fromMap(Map<String, dynamic> map) async {
    for (final key in PrefKey.values) {
      if (!map.containsKey(key.name)) continue;
      final value = map[key.name];
      switch (key.type) {
        case PrefType.boolean:
          await _prefs.setBool(key.name, value as bool);
        case PrefType.integer:
          await _prefs.setInt(key.name, value as int);
        case PrefType.double:
          await _prefs.setDouble(key.name, value as double);
        case PrefType.string:
          await _prefs.setString(key.name, value as String);
        case PrefType.stringList:
          await _prefs.setStringList(key.name, value as List<String>);
      }
    }
  }

  /// Fire-and-forget sync with coalescing: if already syncing, the dirty
  /// flag ensures one more sync runs after the current one finishes.
  Future<void> _maybeSyncUp() async {
    if (_syncing) return;
    _syncing = true;
    try {
      while (await _dirty) {
        await syncUp();
      }
    } on DioException catch (_) {
      // Network failures are fine — dirty flag persists for next attempt
    } finally {
      _syncing = false;
    }
  }

  Future<bool> get _dirty async => await _prefs.getBool(_dirtyKey) ?? false;
  set _dirty(bool value) => _prefs.setBool(_dirtyKey, value);
}
