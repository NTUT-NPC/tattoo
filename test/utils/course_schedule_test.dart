import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/repositories/course_repository.dart';
import 'package:tattoo/utils/course_schedule.dart';

void main() {
  group('PeriodScheduleTime', () {
    test('maps daytime and evening periods to NTUT times', () {
      expect(Period.first.startTime, (hour: 8, minute: 10));
      expect(Period.fourth.endTime, (hour: 12, minute: 0));
      expect(Period.nPeriod.startTime, (hour: 12, minute: 10));
      expect(Period.fifth.startTime, (hour: 13, minute: 10));
      expect(Period.aPeriod.startTime, (hour: 18, minute: 30));
      expect(Period.dPeriod.endTime, (hour: 22, minute: 0));
    });
  });

  group('todayCourseMeetings', () {
    test('returns only today and sorts meetings by start time', () {
      final mondayFirst = _course(id: 1);
      final mondayFifth = _course(id: 2, span: 2);
      final tuesday = _course(id: 3);

      final meetings = todayCourseMeetings(
        _table({
          (day: .monday, period: .fifth): mondayFifth,
          (day: .tuesday, period: .first): tuesday,
          (day: .monday, period: .first): mondayFirst,
        }),
        now: DateTime(2026, 8, 10, 7),
      );

      expect(meetings.map((meeting) => meeting.course.id), [1, 2]);
      expect(meetings.first.start, DateTime(2026, 8, 10, 8, 10));
      expect(meetings.last.end, DateTime(2026, 8, 10, 15));
    });

    test('skips noon when a merged meeting crosses the noon gap', () {
      final meetings = todayCourseMeetings(
        _table({
          (day: .monday, period: .fourth): _course(
            id: 1,
            span: 2,
            crossesNoon: true,
          ),
        }),
        now: DateTime(2026, 8, 10, 7),
      );

      expect(meetings.single.endPeriod, Period.fifth);
      expect(meetings.single.end, DateTime(2026, 8, 10, 14));
    });
  });

  group('preferredTodayCourseIndex', () {
    test('prefers a course starting within 30 minutes over an ongoing one', () {
      final now = DateTime(2026, 8, 10, 9, 45);
      final meetings = todayCourseMeetings(
        _table({
          (day: .monday, period: .second): _course(id: 1, span: 2),
          (day: .monday, period: .third): _course(id: 2),
        }),
        now: now,
      );

      expect(preferredTodayCourseIndex(meetings, now: now), 1);
    });

    test(
      'prefers the ongoing course when the next one is over 30 minutes away',
      () {
        final now = DateTime(2026, 8, 10, 9, 30);
        final meetings = todayCourseMeetings(
          _table({
            (day: .monday, period: .second): _course(id: 1, span: 2),
            (day: .monday, period: .fifth): _course(id: 2),
          }),
          now: now,
        );

        expect(preferredTodayCourseIndex(meetings, now: now), 0);
      },
    );

    test('selects the next course before it enters the 30 minute window', () {
      final now = DateTime(2026, 8, 10, 7);
      final meetings = todayCourseMeetings(
        _table({
          (day: .monday, period: .first): _course(id: 1),
          (day: .monday, period: .fifth): _course(id: 2),
        }),
        now: now,
      );

      expect(preferredTodayCourseIndex(meetings, now: now), 0);
    });

    test('returns null after every course today has ended', () {
      final now = DateTime(2026, 8, 10, 22);
      final meetings = todayCourseMeetings(
        _table({
          (day: .monday, period: .first): _course(id: 1),
        }),
        now: now,
      );

      expect(preferredTodayCourseIndex(meetings, now: now), isNull);
    });
  });
}

CourseTableCellData _course({
  required int id,
  int span = 1,
  bool crossesNoon = false,
}) => (
  id: id,
  number: '$id',
  span: span,
  crossesNoon: crossesNoon,
  courseName: 'Course $id',
  classroomName: 'Room $id',
  teacherNames: const ['Teacher'],
  credits: 3,
  hours: 3,
);

CourseTableData _table(
  Map<({DayOfWeek day, Period period}), CourseTableCellData> scheduled,
) => (
  scheduled: scheduled,
  unscheduled: const [],
  hasWeekdayCourse: true,
  hasSaturdayCourse: false,
  hasSundayCourse: false,
  hasAMCourse: true,
  hasPMCourse: false,
  hasNoonCourse: false,
  hasEveningCourse: false,
  earliestPeriod: scheduled.keys.firstOrNull?.period,
  latestPeriod: scheduled.keys.lastOrNull?.period,
  totalCredits: 0,
  totalHours: 0,
);
