import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/repositories/course_repository.dart';
import 'package:tattoo/screens/main/course_table/course_table_export.dart';
import 'package:tattoo/screens/main/course_table/course_table_grid.dart';

void main() {
  group('courseTableGridRange', () {
    test('shows weekdays and morning periods for a morning-only table', () {
      final range = courseTableGridRange(
        _table(hasWeekdayCourse: true, hasAMCourse: true),
      );

      expect(
        range.visibleDaysOfWeek,
        DayOfWeek.values.where((day) => day.isWeekday),
      );
      expect(range.visiblePeriods.map((period) => period.code), [
        '1',
        '2',
        '3',
        '4',
      ]);
    });

    test('omits noon when morning and afternoon courses do not use it', () {
      final range = courseTableGridRange(
        _table(
          hasWeekdayCourse: true,
          hasAMCourse: true,
          hasPMCourse: true,
        ),
      );

      expect(range.visiblePeriods, isNot(contains(Period.nPeriod)));
      expect(
        range.visiblePeriods,
        Period.values.where((period) => period.isAM || period.isPM),
      );
    });

    test('shows only Saturday and noon for a Saturday noon-only table', () {
      final range = courseTableGridRange(
        _table(hasSaturdayCourse: true, hasNoonCourse: true),
      );

      expect(range.visibleDaysOfWeek, [DayOfWeek.saturday]);
      expect(range.visiblePeriods, [Period.nPeriod]);
    });
  });

  group('CourseTableExport.logicalSizeFor', () {
    test('makes a weekday morning-only table wider than it is tall', () {
      final morningSize = CourseTableExport.logicalSizeFor(
        _table(hasWeekdayCourse: true, hasAMCourse: true),
      );
      final fullDaySize = CourseTableExport.logicalSizeFor(
        _table(
          hasWeekdayCourse: true,
          hasAMCourse: true,
          hasNoonCourse: true,
          hasPMCourse: true,
          hasEveningCourse: true,
        ),
      );

      expect(morningSize, const Size(250, 156));
      expect(morningSize.aspectRatio, greaterThan(1));
      expect(morningSize.width, fullDaySize.width);
      expect(morningSize.height, lessThan(fullDaySize.height));
    });
  });
}

CourseTableData _table({
  bool hasWeekdayCourse = false,
  bool hasSaturdayCourse = false,
  bool hasSundayCourse = false,
  bool hasAMCourse = false,
  bool hasPMCourse = false,
  bool hasNoonCourse = false,
  bool hasEveningCourse = false,
}) => (
  scheduled: const {},
  unscheduled: const [
    (
      id: 1,
      number: null,
      span: 1,
      crossesNoon: false,
      courseName: 'Course',
      classroomName: null,
      teacherNames: <String>[],
      credits: 0.0,
      hours: 0,
    ),
  ],
  hasWeekdayCourse: hasWeekdayCourse,
  hasSaturdayCourse: hasSaturdayCourse,
  hasSundayCourse: hasSundayCourse,
  hasAMCourse: hasAMCourse,
  hasPMCourse: hasPMCourse,
  hasNoonCourse: hasNoonCourse,
  hasEveningCourse: hasEveningCourse,
  earliestPeriod: null,
  latestPeriod: null,
  totalCredits: 0.0,
  totalHours: 0,
);
