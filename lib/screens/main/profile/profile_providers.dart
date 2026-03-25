import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/auth_repository.dart';

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
