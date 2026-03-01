import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/repositories/auth_repository.dart';

/// Provides the current user's profile.
///
/// Returns `null` if not logged in. Automatically fetches full profile if stale.
final userProfileProvider = FutureProvider.autoDispose<User?>((ref) {
  return ref.watch(authRepositoryProvider).getUser();
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

/// Provides a random tester action string.
final testerActionProvider =
    NotifierProvider.autoDispose<TesterActionNotifier, String>(
      TesterActionNotifier.new,
    );

class TesterActionNotifier extends Notifier<String> {
  static const _actions = [
    '點 0 杯啤酒',
    '點 999999999 杯啤酒',
    '點 1 支蜥蜴',
    '點 -1 杯啤酒',
    '點 1 份 asdfghjkl',
    '點 1 碗炒飯',
    '跑進吧檯被店員拖出去',
  ];

  @override
  String build() {
    return _actions[Random().nextInt(_actions.length)];
  }

  void refresh() {
    state = _actions[Random().nextInt(_actions.length)];
  }
}
