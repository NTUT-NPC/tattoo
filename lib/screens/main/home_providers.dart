import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/repositories/auth_repository.dart';

part 'home_providers.g.dart';

/// Provides the current user's profile.
///
/// Returns `null` if not logged in.
@riverpod
Future<UserProfile?> userProfile(Ref ref) {
  return ref.watch(authRepositoryProvider).getUserProfile();
}

/// Provides the current user's avatar file.
///
/// Returns `null` if user has no avatar or not logged in.
@riverpod
Future<File?> userAvatar(Ref ref) {
  return ref.watch(authRepositoryProvider).getAvatar();
}
