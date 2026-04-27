import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/repositories/auth_repository.dart';

/// Provides the current user's profile.
///
/// Watches the DB directly — automatically updates when user data changes
/// (e.g., after login, profile fetch, or cache clear). Background-refreshes
/// stale data automatically.
final userProfileProvider = StreamProvider.autoDispose<User?>((ref) {
  return ref.watch(authRepositoryProvider).watchUser();
});

/// Provides the current user's avatar file.
///
/// Rebuilds when [userProfileProvider] emits a new `avatarFilename`,
/// so background profile refreshes automatically update the avatar.
/// Returns `null` if user has no avatar or not logged in.
final userAvatarProvider = FutureProvider.autoDispose<File?>((ref) {
  // Watch avatarFilename so this rebuilds when it changes.
  ref.watch(
    userProfileProvider.select((async) => async.asData?.value?.avatarFilename),
  );
  return ref.watch(authRepositoryProvider).getAvatar();
});
