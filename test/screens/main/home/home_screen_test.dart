import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/repositories/course_repository.dart';
import 'package:tattoo/screens/main/course_table_providers.dart';
import 'package:tattoo/screens/main/home/home_providers.dart';
import 'package:tattoo/screens/main/home/home_screen.dart';

void main() {
  testWidgets('preserves loading until the course table emits data', (
    tester,
  ) async {
    final semesters = StreamController<List<Semester>>();
    final courseTable = StreamController<CourseTableData>();
    addTearDown(semesters.close);
    addTearDown(courseTable.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          courseTableSemestersProvider.overrideWith(
            (ref) => semesters.stream,
          ),
          courseTableProvider.overrideWith(
            (ref, semesterId) => courseTable.stream,
          ),
        ],
        child: const MaterialApp(home: MainHomeScreen()),
      ),
    );

    expect(find.byKey(const Key('course-carousel-loading')), findsOneWidget);
    expect(find.byIcon(Icons.coffee_outlined), findsNothing);

    semesters.add([
      const Semester(
        id: 1,
        year: 115,
        term: 1,
        inCourseSemesterList: true,
        inScoreSemesterList: false,
      ),
    ]);
    await tester.pump();

    expect(find.byKey(const Key('course-carousel-loading')), findsOneWidget);
    expect(find.byIcon(Icons.coffee_outlined), findsNothing);

    courseTable.add(emptyCourseTableData);
    await tester.pump();

    expect(find.byKey(const Key('course-carousel-loading')), findsNothing);
    expect(find.byIcon(Icons.coffee_outlined), findsNWidgets(2));
  });

  testWidgets('shows a retryable error instead of an empty schedule', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          courseTableSemestersProvider.overrideWith(
            (ref) => Stream.error(StateError('database error')),
          ),
        ],
        child: const MaterialApp(home: MainHomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('course-carousel-error')), findsOneWidget);
    expect(find.byKey(const Key('course-carousel-retry')), findsOneWidget);
    expect(find.byIcon(Icons.coffee_outlined), findsNothing);
  });

  testWidgets('swipes forward from an empty day to the next course day', (
    tester,
  ) async {
    await tester.pumpWidget(
      _homeWithSchedule(
        now: Stream.value(DateTime(2026, 8, 30, 9)),
        courseTable: _courseTable({
          (day: .monday, period: .first): _course(1, 'Monday course'),
        }),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.coffee_outlined), findsNWidgets(2));

    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(find.text('Monday course').hitTestable(), findsOneWidget);
  });

  testWidgets('resets an adjacent date selection when today advances', (
    tester,
  ) async {
    final clock = StreamController<DateTime>();
    addTearDown(clock.close);
    clock.add(DateTime(2026, 8, 30, 9));

    await tester.pumpWidget(
      _homeWithSchedule(
        now: clock.stream,
        courseTable: _courseTable({
          (day: .monday, period: .first): _course(1, 'Monday course'),
        }),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Monday course'), findsNWidgets(2));

    clock.add(DateTime(2026, 9, 1, 0, 1));
    await tester.pumpAndSettle();

    expect(find.text('Monday course'), findsNothing);
    expect(find.byIcon(Icons.coffee_outlined), findsNWidgets(2));
  });
}

Widget _homeWithSchedule({
  required Stream<DateTime> now,
  required CourseTableData courseTable,
}) {
  return ProviderScope(
    overrides: [
      homeClockProvider.overrideWith((ref) => now),
      courseTableSemestersProvider.overrideWith(
        (ref) => Stream.value(const [
          Semester(
            id: 1,
            year: 115,
            term: 1,
            inCourseSemesterList: true,
            inScoreSemesterList: false,
          ),
        ]),
      ),
      courseTableProvider.overrideWith(
        (ref, semesterId) => Stream.value(courseTable),
      ),
    ],
    child: const MaterialApp(home: MainHomeScreen()),
  );
}

CourseTableData _courseTable(
  Map<({DayOfWeek day, Period period}), CourseTableCellData> scheduled,
) => (
  scheduled: scheduled,
  unscheduled: const [],
  hasWeekdayCourse: scheduled.keys.any(
    (slot) => slot.day.index <= DayOfWeek.friday.index,
  ),
  hasSaturdayCourse: scheduled.keys.any(
    (slot) => slot.day == DayOfWeek.saturday,
  ),
  hasSundayCourse: scheduled.keys.any(
    (slot) => slot.day == DayOfWeek.sunday,
  ),
  hasAMCourse: scheduled.keys.any(
    (slot) => slot.period.index <= Period.fourth.index,
  ),
  hasPMCourse: scheduled.keys.any(
    (slot) =>
        slot.period.index >= Period.fifth.index &&
        slot.period.index <= Period.ninth.index,
  ),
  hasNoonCourse: scheduled.keys.any(
    (slot) => slot.period == Period.nPeriod,
  ),
  hasEveningCourse: scheduled.keys.any(
    (slot) => slot.period.index >= Period.aPeriod.index,
  ),
  earliestPeriod: scheduled.keys.firstOrNull?.period,
  latestPeriod: scheduled.keys.firstOrNull?.period,
  totalCredits: 0,
  totalHours: 0,
);

CourseTableCellData _course(int id, String name) => (
  id: id,
  number: '$id',
  span: 1,
  crossesNoon: false,
  courseName: name,
  classroomName: 'Room',
  teacherNames: const ['Teacher'],
  credits: 1,
  hours: 1,
);
