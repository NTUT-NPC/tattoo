import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/repositories/course_repository.dart';

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

/// Provides the available semesters for the current user.
///
/// Returns an empty list if the user is not logged in.
final courseTableSemestersProvider = FutureProvider.autoDispose<List<Semester>>(
  (ref) async {
    final user = await ref.watch(courseTableUserProfileProvider.future);
    if (user == null) return [];

    try {
      return ref.watch(courseRepositoryProvider).getSemesters();
    } on NotLoggedInException {
      return [];
    }
  },
);

/// Provides course table cells for a semester.
///
/// Returns an empty table if the user is not logged in.
final courseTableProvider = FutureProvider.autoDispose
    .family<CourseTableData, Semester>((
      ref,
      semester,
    ) async {
      final user = await ref.watch(courseTableUserProfileProvider.future);
      if (user == null) return CourseTableData();

      try {
        return ref
            .watch(
              courseRepositoryProvider,
            )
            .getCourseTable(user: user, semester: semester);
      } on NotLoggedInException {
        return CourseTableData();
      }
    });
