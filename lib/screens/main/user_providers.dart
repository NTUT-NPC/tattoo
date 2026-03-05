import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/models/course.dart';
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

final CourseTableInfoObject mockCourseTableInfo = (
  number: 'CSIE3001',
  courseNameZh: '微處理機及自動控制應用實務',
  teacherNamesZh: ['王小明', '李小華'],
  credits: 3.0,
  hours: 3,
  classroomNamesZh: ['科研B1234', '三教101'],
  schedule: [
    (dayOfWeek: DayOfWeek.monday, period: Period.third),
    (dayOfWeek: DayOfWeek.monday, period: Period.fourth),
  ],
  classNamesZh: ['資工三甲'],
);

final CourseTableBlockObject mockCourseTableBlock = (
  courseNumber: mockCourseTableInfo.number,
  courseNameZh: mockCourseTableInfo.courseNameZh,
  classroomNameZh: '六教305',
  dayOfWeek: DayOfWeek.monday,
  startSection: Period.third,
  endSection: Period.fourth,
);

final CourseTableSummaryObject mockCourseTableSummary = (
  semester: Semester(id: 1, year: 114, term: 1),
  courses: [
    (
      courseNumber: 'CSIE3002',
      courseNameZh: '作業系統',
      classroomNameZh: '共科201',
      dayOfWeek: DayOfWeek.monday,
      startSection: Period.first,
      endSection: Period.second,
    ),
    (
      courseNumber: 'CSIE3021',
      courseNameZh: '機率與統計',
      classroomNameZh: '共科105',
      dayOfWeek: DayOfWeek.tuesday,
      startSection: Period.nPeriod,
      endSection: Period.fifth,
    ),
    (
      courseNumber: 'CSIE3045',
      courseNameZh: '雲端平台實作',
      classroomNameZh: '科研B215',
      dayOfWeek: DayOfWeek.wednesday,
      startSection: Period.sixth,
      endSection: Period.eighth,
    ),
    (
      courseNumber: 'CSIE3990',
      courseNameZh: '人工智慧導論',
      classroomNameZh: '綜科502',
      dayOfWeek: DayOfWeek.thursday,
      startSection: Period.third,
      endSection: Period.fourth,
    ),
    (
      courseNumber: 'CSIE3901',
      courseNameZh: '行動應用程式開發',
      classroomNameZh: '億光909',
      dayOfWeek: DayOfWeek.friday,
      startSection: Period.sixth,
      endSection: Period.ninth,
    ),
    (
      courseNumber: 'GE4201',
      courseNameZh: '創新與創業實務',
      classroomNameZh: '宏裕704',
      dayOfWeek: DayOfWeek.thursday,
      startSection: Period.sixth,
      endSection: Period.sixth,
    ),
    (
      courseNumber: 'PE2003',
      courseNameZh: '體育(羽球)',
      classroomNameZh: '綜合體育館羽球場',
      dayOfWeek: DayOfWeek.friday,
      startSection: Period.third,
      endSection: Period.fourth,
    ),
    (
      courseNumber: 'CSIE4988',
      courseNameZh: '專題實作討論',
      classroomNameZh: '科研B309',
      dayOfWeek: DayOfWeek.wednesday,
      startSection: Period.nPeriod,
      endSection: Period.fifth,
    ),
    (
      courseNumber: 'CSIE3105',
      courseNameZh: '資料庫系統',
      classroomNameZh: '共科301',
      dayOfWeek: DayOfWeek.monday,
      startSection: Period.third,
      endSection: Period.fourth,
    ),
    (
      courseNumber: 'GE2302',
      courseNameZh: '科技英文',
      classroomNameZh: '綜科204',
      dayOfWeek: DayOfWeek.tuesday,
      startSection: Period.second,
      endSection: Period.third,
    ),
    (
      courseNumber: 'CSIE3702',
      courseNameZh: '軟體工程',
      classroomNameZh: '科研B112',
      dayOfWeek: DayOfWeek.thursday,
      startSection: Period.nPeriod,
      endSection: Period.fifth,
    ),
  ],
  hasAmCourse: true,
  hasNCourse: true,
  hasPmCourse: true,
  hasNightCourse: false,
  earliestStartSection: Period.first,
  latestEndSection: Period.ninth,
  hasWeekdayCourse: true,
  hasSatCourse: false,
  hasSunCourse: false,
  totalCredits: 26.0,
  totalHours: 25,
);
