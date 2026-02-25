// ignore_for_file: unused_field

import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tattoo/utils/shared_preferences.dart';

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
}
