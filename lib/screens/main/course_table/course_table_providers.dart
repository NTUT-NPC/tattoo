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
        classroomNamesZh: ['共科201'],
        schedule: [
          (dayOfWeek: DayOfWeek.monday, period: Period.first),
          (dayOfWeek: DayOfWeek.monday, period: Period.second),
        ],
        classNamesZh: ['資工三甲'],
      ),
      classroomNameZh: '共科201',
      dayOfWeek: DayOfWeek.monday,
      startSection: Period.first,
      endSection: Period.second,
    ),
    (
      courseInfo: (
        number: 'CSIE3021',
        courseNameZh: '機率與統計',
        teacherNamesZh: ['林小雅', '周明德'],
        credits: 2.0,
        hours: 2,
        classroomNamesZh: ['共科105', '共科107'],
        schedule: [
          (dayOfWeek: DayOfWeek.tuesday, period: Period.nPeriod),
          (dayOfWeek: DayOfWeek.tuesday, period: Period.fifth),
        ],
        classNamesZh: ['資工三甲', '資工三乙'],
      ),
      classroomNameZh: '共科105',
      dayOfWeek: DayOfWeek.tuesday,
      startSection: Period.nPeriod,
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
        classroomNamesZh: ['綜科502'],
        schedule: [
          (dayOfWeek: DayOfWeek.thursday, period: Period.third),
          (dayOfWeek: DayOfWeek.thursday, period: Period.fourth),
        ],
        classNamesZh: ['資工三甲'],
      ),
      classroomNameZh: '綜科502',
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
        classroomNamesZh: ['億光909'],
        schedule: [
          (dayOfWeek: DayOfWeek.friday, period: Period.sixth),
          (dayOfWeek: DayOfWeek.friday, period: Period.seventh),
          (dayOfWeek: DayOfWeek.friday, period: Period.eighth),
          (dayOfWeek: DayOfWeek.friday, period: Period.ninth),
        ],
        classNamesZh: ['資工三甲'],
      ),
      classroomNameZh: '億光909',
      dayOfWeek: DayOfWeek.friday,
      startSection: Period.sixth,
      endSection: Period.ninth,
    ),
    (
      courseInfo: (
        number: 'GE4201',
        courseNameZh: '創新與創業實務',
        teacherNamesZh: ['蔡宜庭'],
        credits: 2.0,
        hours: 2,
        classroomNamesZh: ['宏裕704'],
        schedule: [
          (dayOfWeek: DayOfWeek.thursday, period: Period.sixth),
        ],
        classNamesZh: ['跨院選修'],
      ),
      classroomNameZh: '宏裕704',
      dayOfWeek: DayOfWeek.thursday,
      startSection: Period.sixth,
      endSection: Period.sixth,
    ),
    (
      courseInfo: (
        number: 'PE2003',
        courseNameZh: '體育(羽球)',
        teacherNamesZh: ['陳佳琳'],
        credits: 1.0,
        hours: 2,
        classroomNamesZh: [''],
        schedule: [
          (dayOfWeek: DayOfWeek.friday, period: Period.third),
          (dayOfWeek: DayOfWeek.friday, period: Period.fourth),
        ],
        classNamesZh: ['體育必修'],
      ),
      classroomNameZh: '綜合體育館羽球場',
      dayOfWeek: DayOfWeek.friday,
      startSection: Period.third,
      endSection: Period.fourth,
    ),
    (
      courseInfo: (
        number: 'CSIE4988',
        courseNameZh: '專題實作討論',
        teacherNamesZh: ['許哲維', '何思穎'],
        credits: 1.0,
        hours: 2,
        classroomNamesZh: ['科研B309'],
        schedule: [
          (dayOfWeek: DayOfWeek.wednesday, period: Period.nPeriod),
          (dayOfWeek: DayOfWeek.wednesday, period: Period.fifth),
        ],
        classNamesZh: ['資工四甲'],
      ),
      classroomNameZh: '科研B309',
      dayOfWeek: DayOfWeek.wednesday,
      startSection: Period.nPeriod,
      endSection: Period.fifth,
    ),
    (
      courseInfo: (
        number: 'CSIE3105',
        courseNameZh: '資料庫系統',
        teacherNamesZh: ['洪志賢'],
        credits: 3.0,
        hours: 2,
        classroomNamesZh: ['共科301'],
        schedule: [
          (dayOfWeek: DayOfWeek.monday, period: Period.third),
          (dayOfWeek: DayOfWeek.monday, period: Period.fourth),
        ],
        classNamesZh: ['資工三甲'],
      ),
      classroomNameZh: '共科301',
      dayOfWeek: DayOfWeek.monday,
      startSection: Period.third,
      endSection: Period.fourth,
    ),
    (
      courseInfo: (
        number: 'GE2302',
        courseNameZh: '科技英文',
        teacherNamesZh: ['李雅雯'],
        credits: 2.0,
        hours: 2,
        classroomNamesZh: ['綜科204'],
        schedule: [
          (dayOfWeek: DayOfWeek.tuesday, period: Period.second),
          (dayOfWeek: DayOfWeek.tuesday, period: Period.third),
        ],
        classNamesZh: ['校共同必修'],
      ),
      classroomNameZh: '綜科204',
      dayOfWeek: DayOfWeek.tuesday,
      startSection: Period.second,
      endSection: Period.third,
    ),
    (
      courseInfo: (
        number: 'CSIE3702',
        courseNameZh: '軟體工程',
        teacherNamesZh: ['郭冠廷'],
        credits: 3.0,
        hours: 2,
        classroomNamesZh: ['科研B112'],
        schedule: [
          (dayOfWeek: DayOfWeek.thursday, period: Period.nPeriod),
          (dayOfWeek: DayOfWeek.thursday, period: Period.fifth),
        ],
        classNamesZh: ['資工三甲', '資工三乙'],
      ),
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
