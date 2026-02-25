import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _sharedPreferences = SharedPreferencesAsync();

final sharedPreferencesProvider = Provider<SharedPreferencesAsync>(
  (_) => _sharedPreferences,
);
