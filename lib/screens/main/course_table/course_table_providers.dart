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
  courseInfo: mockCourseTableInfo,
  classroomNameZh: '六教305',
  dayOfWeek: DayOfWeek.monday,
  startSection: Period.third,
  endSection: Period.fourth,
);

final CourseTableSummaryObject mockCourseTableSummary = (
  semester: Semester(id: 1, year: 114, term: 1),
  courses: [
    (
      courseInfo: (
        number: 'CSIE3002',
        courseNameZh: '作業系統',
        teacherNamesZh: ['陳大文'],
        credits: 3.0,
        hours: 2,
        classroomNamesZh: ['共同科館201'],
        schedule: [
          (dayOfWeek: DayOfWeek.monday, period: Period.first),
          (dayOfWeek: DayOfWeek.monday, period: Period.second),
        ],
        classNamesZh: ['資工三甲'],
      ),
      classroomNameZh: '共同科館201',
      dayOfWeek: DayOfWeek.monday,
      startSection: Period.first,
      endSection: Period.second,
    ),
    (
      courseInfo: (
        number: 'CSIE3021',
        courseNameZh: '資料探勘',
        teacherNamesZh: ['林小雅'],
        credits: 2.0,
        hours: 1,
        classroomNamesZh: ['六教304'],
        schedule: [(dayOfWeek: DayOfWeek.tuesday, period: Period.fifth)],
        classNamesZh: ['資工三甲'],
      ),
      classroomNameZh: '六教304',
      dayOfWeek: DayOfWeek.tuesday,
      startSection: Period.fifth,
      endSection: Period.fifth,
    ),
    (
      courseInfo: (
        number: 'CSIE3045',
        courseNameZh: '雲端平台實作',
        teacherNamesZh: ['吳佳穎'],
        credits: 3.0,
        hours: 3,
        classroomNamesZh: ['科研B215'],
        schedule: [
          (dayOfWeek: DayOfWeek.wednesday, period: Period.sixth),
          (dayOfWeek: DayOfWeek.wednesday, period: Period.seventh),
          (dayOfWeek: DayOfWeek.wednesday, period: Period.eighth),
        ],
        classNamesZh: ['資工三甲'],
      ),
      classroomNameZh: '科研B215',
      dayOfWeek: DayOfWeek.wednesday,
      startSection: Period.sixth,
      endSection: Period.eighth,
    ),
    (
      courseInfo: (
        number: 'CSIE3990',
        courseNameZh: '人工智慧導論',
        teacherNamesZh: ['張承恩'],
        credits: 2.0,
        hours: 2,
        classroomNamesZh: ['綜科館502'],
        schedule: [
          (dayOfWeek: DayOfWeek.thursday, period: Period.third),
          (dayOfWeek: DayOfWeek.thursday, period: Period.fourth),
        ],
        classNamesZh: ['資工三甲'],
      ),
      classroomNameZh: '綜科館502',
      dayOfWeek: DayOfWeek.thursday,
      startSection: Period.third,
      endSection: Period.fourth,
    ),
    (
      courseInfo: (
        number: 'CSIE3901',
        courseNameZh: '行動應用程式開發',
        teacherNamesZh: ['黃柏鈞'],
        credits: 4.0,
        hours: 4,
        classroomNamesZh: ['億光大樓909'],
        schedule: [
          (dayOfWeek: DayOfWeek.friday, period: Period.sixth),
          (dayOfWeek: DayOfWeek.friday, period: Period.seventh),
          (dayOfWeek: DayOfWeek.friday, period: Period.eighth),
          (dayOfWeek: DayOfWeek.friday, period: Period.ninth),
        ],
        classNamesZh: ['資工三甲'],
      ),
      classroomNameZh: '億光大樓909',
      dayOfWeek: DayOfWeek.friday,
      startSection: Period.sixth,
      endSection: Period.ninth,
    ),
  ],
  hasAmCourse: true,
  hasNCourse: false,
  hasPmCourse: true,
  hasNightCourse: false,
  earliestStartSection: Period.first,
  latestEndSection: Period.ninth,
  hasWeekdayCourse: true,
  hasSatCourse: false,
  hasSunCourse: false,
  totalCredits: 14.0,
  totalHours: 12,
);
