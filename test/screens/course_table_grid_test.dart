import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/repositories/course_repository.dart';
import 'package:tattoo/screens/main/course_table/course_table_export.dart';
import 'package:tattoo/screens/main/course_table/course_table_grid.dart';

void main() {
  group('courseTableGridRange noon row', () {
    test('keeps the noon row when morning and afternoon both have courses', () {
      final range = courseTableGridRange(
        _courseTable(
          scheduled: {
            (day: DayOfWeek.monday, period: Period.fourth): _cell(
              span: 2,
              crossesNoon: true,
            ),
          },
          hasAMCourse: true,
          hasPMCourse: true,
        ),
      );

      expect(range.visiblePeriods, contains(Period.nPeriod));
      expect(
        range.visiblePeriods,
        containsAllInOrder([Period.fourth, Period.nPeriod, Period.fifth]),
      );
    });

    test('omits the noon row when only the morning has courses', () {
      final range = courseTableGridRange(
        _courseTable(
          scheduled: {
            (day: DayOfWeek.monday, period: Period.first): _cell(),
          },
          hasAMCourse: true,
        ),
      );

      expect(range.visiblePeriods, isNot(contains(Period.nPeriod)));
    });
  });

  group('CourseTableGridMetrics', () {
    test('shrinks the noon row to a third while noon is free', () {
      final metrics = CourseTableGridMetrics(
        visiblePeriods: const [Period.fourth, Period.nPeriod, Period.fifth],
        hasNoonCourse: false,
        rowHeight: 30,
      );

      expect(metrics.periodHeight(Period.nPeriod), 10);
      expect(metrics.periodHeight(Period.fourth), 30);
      expect(metrics.gridHeight, 70);
      expect(metrics.periodTopOffset(2), 40);
    });

    test('keeps the noon row at full height while a course occupies it', () {
      final metrics = CourseTableGridMetrics(
        visiblePeriods: const [Period.fourth, Period.nPeriod, Period.fifth],
        hasNoonCourse: true,
        rowHeight: 30,
      );

      expect(metrics.periodHeight(Period.nPeriod), 30);
      expect(metrics.gridHeight, 90);
      expect(metrics.periodTopOffset(2), 60);
    });

    test('a noon-crossing course covers the shrunken noon row', () {
      final metrics = CourseTableGridMetrics(
        visiblePeriods: const [Period.fourth, Period.nPeriod, Period.fifth],
        hasNoonCourse: false,
        rowHeight: 30,
      );

      expect(
        metrics.courseCellHeight(0, _cell(span: 2, crossesNoon: true)),
        70,
      );
      expect(metrics.courseCellHeight(0, _cell()), 30);
    });

    test('a noon-crossing course covers the full noon row of another day', () {
      final metrics = CourseTableGridMetrics(
        visiblePeriods: const [Period.fourth, Period.nPeriod, Period.fifth],
        hasNoonCourse: true,
        rowHeight: 30,
      );

      expect(
        metrics.courseCellHeight(0, _cell(span: 2, crossesNoon: true)),
        90,
      );
    });
  });

  group('CourseTableExport', () {
    test('sizes the bitmap with the shrunken noon row', () {
      final scheduled = {
        (day: DayOfWeek.monday, period: Period.fourth): _cell(
          span: 2,
          crossesNoon: true,
        ),
      };
      final noonFree = _courseTable(
        scheduled: scheduled,
        hasAMCourse: true,
        hasPMCourse: true,
      );
      final noonBusy = _courseTable(
        scheduled: scheduled,
        hasAMCourse: true,
        hasNoonCourse: true,
        hasPMCourse: true,
      );

      // Both show the same rows, so a uniform row height would make the two
      // exports equally tall instead of shrinking the free noon row.
      expect(
        courseTableGridRange(noonFree).visiblePeriods,
        courseTableGridRange(noonBusy).visiblePeriods,
      );
      expect(
        CourseTableExport.logicalSizeFor(noonFree).height,
        lessThan(CourseTableExport.logicalSizeFor(noonBusy).height),
      );
    });
  });
}

CourseTableCellData _cell({int span = 1, bool crossesNoon = false}) => (
  id: 1,
  number: 'CSIE0001',
  span: span,
  crossesNoon: crossesNoon,
  courseName: '測試課程',
  classroomName: '共同101',
  teacherNames: const ['測試教師'],
  credits: 3.0,
  hours: 3,
);

CourseTableData _courseTable({
  required Map<({DayOfWeek day, Period period}), CourseTableCellData> scheduled,
  bool hasAMCourse = false,
  bool hasNoonCourse = false,
  bool hasPMCourse = false,
}) => (
  scheduled: scheduled,
  unscheduled: const <CourseTableCellData>[],
  hasWeekdayCourse: true,
  hasSaturdayCourse: false,
  hasSundayCourse: false,
  hasAMCourse: hasAMCourse,
  hasPMCourse: hasPMCourse,
  hasNoonCourse: hasNoonCourse,
  hasEveningCourse: false,
  earliestPeriod: scheduled.keys.first.period,
  latestPeriod: scheduled.keys.last.period,
  totalCredits: 3.0,
  totalHours: 3,
);
