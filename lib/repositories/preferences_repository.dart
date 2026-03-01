import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tattoo/utils/shared_preferences.dart';

/// SharedPreferences value type, used to dispatch to the correct accessor.
enum PrefType { boolean, integer, double, string, stringList }

// dart format off
/// Typed preference keys with defaults.
enum PrefKey<T> {
  /// Whether to use mock data instead of live NTUT services.
  demoMode<bool>(PrefType.boolean, false),

  /// Whether the "點一碗炒飯" easter egg is enabled.
  isFriedRiceEnabled<bool>(PrefType.boolean, false);

  const PrefKey(this.type, this.defaultValue);
  final PrefType type;
  final T defaultValue;
}
// dart format on

/// Provides the [PreferencesRepository] instance.
final preferencesRepositoryProvider = Provider<PreferencesRepository>((ref) {
  return PreferencesRepository(
    prefs: ref.watch(sharedPreferencesProvider),
  );
});

/// Manages app preferences: demo mode, color customizations, onboarding status.
class PreferencesRepository {
  final SharedPreferencesAsync _prefs;

  PreferencesRepository({
    required SharedPreferencesAsync prefs,
  }) : _prefs = prefs;

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

  /// Sets a preference value.
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
  }
}

/// Provides the "isFriedRiceEnabled" easter egg preference.
final isBarEnabledProvider = AsyncNotifierProvider<FriedRiceNotifier, bool>(
  FriedRiceNotifier.new,
);

class FriedRiceNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = ref.watch(preferencesRepositoryProvider);
    return await prefs.get(PrefKey.isFriedRiceEnabled);
  }

  Future<void> toggle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final prefs = ref.read(preferencesRepositoryProvider);
      final current = await prefs.get(PrefKey.isFriedRiceEnabled);
      final newState = !current;
      await prefs.set(PrefKey.isFriedRiceEnabled, newState);
      return newState;
    });
  }
}
