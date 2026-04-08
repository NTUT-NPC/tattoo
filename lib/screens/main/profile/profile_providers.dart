import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/screens/main/profile/feature_flag_providers.dart';

/// Provides the user's active registration (current class and semester).
///
/// Watches the DB view directly — automatically updates when registration
/// data changes (e.g., after login, profile fetch, or cache clear).
final activeRegistrationProvider =
    StreamProvider.autoDispose<UserRegistration?>((ref) {
      return ref.watch(authRepositoryProvider).watchActiveRegistration();
    });

/// Random action string from [t.profile.dangerZone.actions] for the easter egg button.
/// Invalidate to pick a new action.
final dangerZoneActionProvider = Provider.autoDispose<String>((ref) {
  final actions = t.profile.dangerZone.actions;
  return actions[Random().nextInt(actions.length)];
});

/// Indicates whether the dummy feature is enabled.
final isDummyFeatureEnabledProvider = FutureProvider.autoDispose<bool>((
  ref,
) async {
  final val = await ref.watch(
    featureFlagValueProvider('enable_dummy_feature').future,
  );
  return val == true;
});

final dummyStringValueProvider = FutureProvider.autoDispose<String>((
  ref,
) async {
  final val = await ref.watch(
    featureFlagValueProvider('dummy_string_value').future,
  );
  return val as String? ?? 'Hello World';
});

final dummyIntValueProvider = FutureProvider.autoDispose<int>((ref) async {
  final val = await ref.watch(
    featureFlagValueProvider('dummy_num_lock').future,
  );
  return val as int? ?? 42;
});

enum ThemeOption { light, dark, system }

final dummyThemeProvider = FutureProvider.autoDispose<ThemeOption>((ref) async {
  final val = await ref.watch(featureFlagValueProvider('dummy_theme').future);
  return switch (val) {
    'light' => ThemeOption.light,
    'dark' => ThemeOption.dark,
    _ => ThemeOption.system,
  };
});
