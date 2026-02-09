import 'dart:io';

import 'package:riverpod/riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/repositories/auth_repository.dart';

/// Provides the current user's profile.
///
/// Returns `null` if not logged in.
final userProfileProvider = FutureProvider.autoDispose<UserProfile?>((ref) {
  return ref.watch(authRepositoryProvider).getUserProfile();
});

/// Provides the current user's avatar file.
///
/// Returns `null` if user has no avatar or not logged in.
final userAvatarProvider = FutureProvider.autoDispose<File?>((ref) {
  return ref.watch(authRepositoryProvider).getAvatar();
});
