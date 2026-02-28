import 'dart:io';

import 'package:riverpod/riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/repositories/course_repository.dart';

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

final CourseTableInfoObject mockCourseTableInfo = (
  number: 'CSIE3001',
  courseNameZh: '微處理機及自動控制應用實務',
  teacherNamesZh: ['王小明', '李小華'],
  credits: 3,
  hours: 3,
  classroomNamesZh: ['六教305', '三教101'],
  schedule: [
    (dayOfWeek: DayOfWeek.monday, period: Period.third),
    (dayOfWeek: DayOfWeek.monday, period: Period.fourth),
  ],
  classNamesZh: ['資工三甲'],
);

final CourseTableBlockObject mockCourseTableBlock = (
  courseInfo: mockCourseTableInfo,
  dayOfWeek: DayOfWeek.monday,
  startSection: Period.third,
  endSection: Period.fourth,
);
