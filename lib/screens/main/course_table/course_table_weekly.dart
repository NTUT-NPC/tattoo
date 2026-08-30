import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:tattoo/components/app_skeleton.dart';
import 'package:tattoo/components/section_header.dart';
import 'package:tattoo/components/widget_preview_frame.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/repositories/course_repository.dart';
import 'package:tattoo/screens/main/course_table/course_table_cell.dart';
import 'package:tattoo/screens/main/course_table/course_table_colors.dart';
import 'package:tattoo/screens/main/course_table/course_table_detail_sheet.dart';
import 'package:tattoo/utils/auto_spacing.dart';

const _dayOrder = [
  DayOfWeek.monday,
  DayOfWeek.tuesday,
  DayOfWeek.wednesday,
  DayOfWeek.thursday,
  DayOfWeek.friday,
  DayOfWeek.saturday,
  DayOfWeek.sunday,
];

typedef _WeeklyCourse = ({
  Period startPeriod,
  CourseTableCellData cell,
});

/// A list-based weekly course-table view grouped by day.
class CourseTableWeekly extends StatelessWidget {
  const CourseTableWeekly({
    super.key,
    required this.courseTableData,
    this.loading = false,
    this.onRefresh,
    this.bottomInset = 0,
  });

  final CourseTableData courseTableData;
  final bool loading;
  final RefreshCallback? onRefresh;
  final double bottomInset;

  bool get _isEmpty =>
      courseTableData.scheduled.isEmpty && courseTableData.unscheduled.isEmpty;

  @override
  Widget build(BuildContext context) {
    final colorByCourseId = buildCourseTableColorMap(courseTableData);
    final coursesByDay = _coursesByDay();
    final scrollView = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics().applyTo(
        ScrollConfiguration.of(context).getScrollPhysics(context),
      ),
      slivers: [
        if (loading)
          const SliverPadding(
            padding: .all(16),
            sliver: SliverToBoxAdapter(
              child: _WeeklyLoadingSkeleton(),
            ),
          )
        else if (_isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text(t.courseTable.notFound)),
          )
        else
          SliverPadding(
            padding: const .all(16),
            sliver: SliverList.list(
              children: [
                for (final day in _dayOrder)
                  if (coursesByDay[day] case final courses?) ...[
                    SectionHeader(
                      title: t.courseTable.dayOfWeekLong[day.name]!,
                    ),
                    const SizedBox(height: 8),
                    for (final course in courses) ...[
                      CourseTableListCell(
                        courseTableCellData: course.cell,
                        indicatorColor:
                            colorByCourseId[course.cell.id] ?? Colors.grey,
                        additionalSubtitle: course.cell.classroomName,
                        trailingText: _periodLabel(course),
                        onTap: switch (course.cell.number) {
                          final number? => () => showCourseTableDetailSheet(
                            context,
                            number: number,
                          ),
                          null => null,
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                if (courseTableData.unscheduled.isNotEmpty) ...[
                  SectionHeader(title: t.courseTable.unscheduled),
                  const SizedBox(height: 8),
                  for (final cell in courseTableData.unscheduled) ...[
                    CourseTableListCell(
                      courseTableCellData: cell,
                      indicatorColor: colorByCourseId[cell.id] ?? Colors.grey,
                      onTap: switch (cell.number) {
                        final number? => () => showCourseTableDetailSheet(
                          context,
                          number: number,
                        ),
                        null => null,
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
                Center(
                  child: Padding(
                    padding: const .all(8),
                    child: Text(
                      ' - '
                      '${t.courseTable.summary.credits(count: courseTableData.totalCredits).spaced} · '
                      '${t.courseTable.summary.hours(count: courseTableData.totalHours).spaced}'
                      ' - ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (bottomInset > 0)
          SliverToBoxAdapter(child: SizedBox(height: bottomInset)),
      ],
    );

    return switch (onRefresh) {
      final onRefresh? => RefreshIndicator(
        onRefresh: onRefresh,
        child: scrollView,
      ),
      null => scrollView,
    };
  }

  Map<DayOfWeek, List<_WeeklyCourse>> _coursesByDay() {
    final result = <DayOfWeek, List<_WeeklyCourse>>{};
    for (final entry in courseTableData.scheduled.entries) {
      result.putIfAbsent(entry.key.day, () => []).add((
        startPeriod: entry.key.period,
        cell: entry.value,
      ));
    }
    for (final courses in result.values) {
      courses.sort(
        (a, b) => a.startPeriod.index.compareTo(b.startPeriod.index),
      );
    }
    return result;
  }

  String _periodLabel(_WeeklyCourse course) {
    final start = course.startPeriod;
    final rawEndIndex = start.index + course.cell.span - 1;
    final endIndex =
        rawEndIndex >= Period.nPeriod.index && course.cell.crossesNoon
        ? rawEndIndex + 1
        : rawEndIndex;
    final end = Period.values[endIndex];

    return switch (start == end) {
      true => start.code,
      false => '${start.code}–${end.code}',
    };
  }
}

class _WeeklyLoadingSkeleton extends StatelessWidget {
  const _WeeklyLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    const placeholder = (
      id: 0,
      number: '0000000',
      span: 2,
      crossesNoon: false,
      courseName: '課程名稱',
      classroomName: '教室',
      credits: 3.0,
      hours: 3,
    );

    return AppSkeleton(
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: 8,
        children: [
          SectionHeader(title: t.courseTable.dayOfWeekLong['monday']!),
          for (var i = 0; i < 4; i++)
            const CourseTableListCell(
              courseTableCellData: placeholder,
              indicatorColor: Colors.grey,
              additionalSubtitle: '教室',
              trailingText: '1–2',
            ),
        ],
      ),
    );
  }
}

@Preview(
  name: 'CourseTableWeekly',
  group: 'Course Table',
  size: Size(420, 720),
)
Widget previewCourseTableWeekly() {
  return WidgetPreviewFrame(
    child: CourseTableWeekly(courseTableData: _previewCourseTableData),
  );
}

final CourseTableData _previewCourseTableData = (
  scheduled: {
    (day: .monday, period: .first): (
      id: 1,
      number: 'CSIE3002',
      span: 2,
      crossesNoon: false,
      courseName: '作業系統',
      classroomName: '共同科館201',
      credits: 3.0,
      hours: 3,
    ),
    (day: .wednesday, period: .fourth): (
      id: 2,
      number: 'CSIE3702',
      span: 2,
      crossesNoon: true,
      courseName: '軟體工程',
      classroomName: '科研B112',
      credits: 3.0,
      hours: 3,
    ),
  },
  unscheduled: [
    (
      id: 3,
      number: 'CSIE4999',
      span: 0,
      crossesNoon: false,
      courseName: '校外實習',
      classroomName: null,
      credits: 9.0,
      hours: 9,
    ),
  ],
  hasWeekdayCourse: true,
  hasSaturdayCourse: false,
  hasSundayCourse: false,
  hasAMCourse: true,
  hasPMCourse: true,
  hasNoonCourse: false,
  hasEveningCourse: false,
  earliestPeriod: .first,
  latestPeriod: .fifth,
  totalCredits: 15.0,
  totalHours: 15,
);
