import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/screens/main/user_providers.dart';

/// Provides the user's active registration (current class and semester).
///
/// Depends on [userProfileProvider] to ensure registration data is populated.
final activeRegistrationProvider =
    FutureProvider.autoDispose<UserRegistration?>((ref) async {
      await ref.watch(userProfileProvider.future);
      return ref.watch(authRepositoryProvider).getActiveRegistration();
    });

/// Random action string from [t.profile.dangerZone.actions] for the easter egg button.
/// Invalidate to pick a new action.
final dangerZoneActionProvider = Provider.autoDispose<String>((ref) {
  final actions = t.profile.dangerZone.actions;
  return actions[Random().nextInt(actions.length)];
});
