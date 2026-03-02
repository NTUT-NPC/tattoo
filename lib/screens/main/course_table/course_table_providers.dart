import 'dart:io';

import 'package:riverpod/riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/repositories/auth_repository.dart';

/// Provides the current user's basic profile for course table header.
///
/// Returns `null` if not logged in. Automatically fetches full profile if stale.
final courseTableUserProfileProvider = FutureProvider.autoDispose<User?>((ref) {
  return ref.watch(authRepositoryProvider).getUser();
});

/// Provides the current user's avatar file for course table header.
///
/// Returns `null` if user has no avatar or not logged in.
final courseTableUserAvatarProvider = FutureProvider.autoDispose<File?>((ref) {
  return ref.watch(authRepositoryProvider).getAvatar();
});
