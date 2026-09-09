import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tattoo/components/app_skeleton.dart';
import 'package:tattoo/components/section_header.dart';
import 'package:tattoo/components/widget_preview_frame.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/repositories/course_repository.dart';
import 'package:tattoo/screens/main/course_table/course_table_cell.dart';
import 'package:tattoo/screens/main/course_table/course_table_colors.dart';
import 'package:tattoo/screens/main/course_table/course_table_detail_sheet.dart';
import 'package:tattoo/screens/main/course_table/course_table_entrance_animation.dart';
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

const _initialEntranceDelay = Duration(milliseconds: 50);
const _entranceStagger = Duration(milliseconds: 40);
const _weeklyEntranceOffset = Offset(16, 0);

/// A list-based weekly course-table view grouped by day.
class CourseTableWeekly extends StatefulWidget {
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

  @override
  State<CourseTableWeekly> createState() => _CourseTableWeeklyState();
}

class _CourseTableWeeklyState extends State<CourseTableWeekly>
    with SingleTickerProviderStateMixin {
  late final int _entranceEntryCount;
  late final AnimationController _entranceTimeline;
  var _acceptEntranceEntries = true;

  bool get _isEmpty =>
      widget.courseTableData.scheduled.isEmpty &&
      widget.courseTableData.unscheduled.isEmpty;

  @override
  void initState() {
    super.initState();
    _entranceEntryCount = widget.loading
        ? 4
        : _courseCount(widget.courseTableData);
    _entranceTimeline = AnimationController(
      vsync: this,
      duration: _entranceTimelineDuration(_entranceEntryCount),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _acceptEntranceEntries = false;
    });
  }

  @override
  void didUpdateWidget(CourseTableWeekly oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loading != widget.loading ||
        oldWidget.courseTableData != widget.courseTableData) {
      _entranceTimeline.value = 1;
    }
  }

  @override
  void dispose() {
    _entranceTimeline.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorByCourseId = buildCourseTableColorMap(widget.courseTableData);
    final coursesByDay = _coursesByDay();
    final scrollView = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics().applyTo(
        ScrollConfiguration.of(context).getScrollPhysics(context),
      ),
      slivers: [
        if (widget.loading)
          SliverPadding(
            padding: const .all(16),
            sliver: SliverToBoxAdapter(
              child: _WeeklyLoadingSkeleton(
                entranceTimeline: _entranceTimeline,
                shouldAnimate: () => _acceptEntranceEntries,
              ),
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
              children: _buildWeeklyChildren(
                context,
                coursesByDay,
                colorByCourseId,
              ),
            ),
          ),
        if (widget.bottomInset > 0)
          SliverToBoxAdapter(child: SizedBox(height: widget.bottomInset)),
      ],
    );

    return switch (widget.onRefresh) {
      final onRefresh? => RefreshIndicator(
        onRefresh: onRefresh,
        child: scrollView,
      ),
      null => scrollView,
    };
  }

  List<Widget> _buildWeeklyChildren(
    BuildContext context,
    Map<DayOfWeek, List<_WeeklyCourse>> coursesByDay,
    Map<int, Color> colorByCourseId,
  ) {
    final children = <Widget>[];
    var animationIndex = 0;

    for (final day in _dayOrder) {
      final courses = coursesByDay[day];
      if (courses == null) continue;

      children.addAll([
        _WeeklySectionHeader(title: t.courseTable.dayOfWeekLong[day.name]!),
        const SizedBox(height: 8),
      ]);
      for (final course in courses) {
        children.addAll([
          _buildAnimatedEntry(
            animationIndex++,
            CourseTableListCell(
              courseTableCellData: course.cell,
              indicatorColor: colorByCourseId[course.cell.id] ?? Colors.grey,
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
          ),
          const SizedBox(height: 8),
        ]);
      }
    }

    if (widget.courseTableData.unscheduled.isNotEmpty) {
      children.addAll([
        _WeeklySectionHeader(title: t.courseTable.unscheduled),
        const SizedBox(height: 8),
      ]);
      for (final cell in widget.courseTableData.unscheduled) {
        children.addAll([
          _buildAnimatedEntry(
            animationIndex++,
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
          ),
          const SizedBox(height: 8),
        ]);
      }
    }

    children.add(
      Center(
        child: Padding(
          padding: const .all(8),
          child: Text(
            ' - '
            '${t.courseTable.summary.credits(count: widget.courseTableData.totalCredits).spaced} · '
            '${t.courseTable.summary.hours(count: widget.courseTableData.totalHours).spaced}'
            ' - ',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
    return children;
  }

  Widget _buildAnimatedEntry(int index, Widget child) {
    if (index >= _entranceEntryCount) return child;

    return CourseTableEntranceAnimation(
      key: ValueKey('weekly-course-$index'),
      delay: _initialEntranceDelay + (_entranceStagger * index),
      beginOffset: _weeklyEntranceOffset,
      timeline: _entranceTimeline,
      shouldAnimate: () => _acceptEntranceEntries,
      child: child,
    );
  }

  Map<DayOfWeek, List<_WeeklyCourse>> _coursesByDay() {
    final result = <DayOfWeek, List<_WeeklyCourse>>{};
    for (final entry in widget.courseTableData.scheduled.entries) {
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
  const _WeeklyLoadingSkeleton({
    required this.entranceTimeline,
    required this.shouldAnimate,
  });

  final AnimationController entranceTimeline;
  final ValueGetter<bool> shouldAnimate;

  @override
  Widget build(BuildContext context) {
    const placeholder = (
      id: 0,
      number: '0000000',
      span: 2,
      crossesNoon: false,
      courseName: '課程名稱',
      classroomName: '教室',
      teacherNames: ['測試教師'],
      credits: 3.0,
      hours: 3,
    );

    return AppSkeleton(
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: 8,
        children: [
          _WeeklySectionHeader(
            title: t.courseTable.dayOfWeekLong['monday']!,
          ),
          for (var i = 0; i < 4; i++)
            CourseTableEntranceAnimation(
              delay: _initialEntranceDelay + (_entranceStagger * i),
              beginOffset: _weeklyEntranceOffset,
              timeline: entranceTimeline,
              shouldAnimate: shouldAnimate,
              child: const CourseTableListCell(
                courseTableCellData: placeholder,
                indicatorColor: Colors.grey,
                additionalSubtitle: '教室',
                trailingText: '1–2',
              ),
            ),
        ],
      ),
    );
  }
}

class _WeeklySectionHeader extends StatelessWidget {
  const _WeeklySectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(child: SectionHeader(title: title));
  }
}

int _courseCount(CourseTableData data) =>
    data.scheduled.length + data.unscheduled.length;

Duration _entranceTimelineDuration(int entryCount) {
  final lastIndex = entryCount > 0 ? entryCount - 1 : 0;
  return _initialEntranceDelay +
      (_entranceStagger * lastIndex) +
      CourseTableEntranceAnimation.animationDuration;
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
      teacherNames: ['測試教師'],
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
      teacherNames: ['測試教師'],
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
      teacherNames: ['測試教師'],
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
