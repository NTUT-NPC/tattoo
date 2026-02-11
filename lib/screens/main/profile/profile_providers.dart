import 'dart:io';

import 'package:riverpod/riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/repositories/auth_repository.dart';

/// Provides the current user's profile.
///
/// Returns `null` if not logged in.
final userProfileProvider = FutureProvider.autoDispose<User?>((ref) {
  return ref.watch(authRepositoryProvider).fetchUser();
});

/// Provides the current user's avatar file.
///
/// Returns `null` if user has no avatar or not logged in.
final userAvatarProvider = FutureProvider.autoDispose<File?>((ref) {
  return ref.watch(authRepositoryProvider).getAvatar();
});

/// Provides the user's active registration (current class and semester).
///
/// Depends on [userProfileProvider] to ensure registration data is populated.
final activeRegistrationProvider =
    FutureProvider.autoDispose<UserRegistration?>((ref) async {
      await ref.watch(userProfileProvider.future);
      return ref.watch(authRepositoryProvider).getActiveRegistration();
    });
