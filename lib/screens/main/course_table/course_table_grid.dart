import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:tattoo/components/widget_preview_frame.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/repositories/course_repository.dart';
import 'package:tattoo/screens/main/course_table/course_table_cell.dart';

List<DayOfWeek> _weekDays = [
  DayOfWeek.monday,
  DayOfWeek.tuesday,
  DayOfWeek.wednesday,
  DayOfWeek.thursday,
  DayOfWeek.friday,
];

List<Period> _periods = [
  Period.first,
  Period.second,
  Period.third,
  Period.fourth,
  Period.nPeriod,
  Period.fifth,
  Period.sixth,
  Period.seventh,
  Period.eighth,
  Period.ninth,
  Period.aPeriod,
  Period.bPeriod,
  Period.cPeriod,
  Period.dPeriod,
];

class CourseTableGrid extends StatelessWidget {
  const CourseTableGrid({
    super.key,
    required this.courseTableData,
    this.loading = false,
    this.viewportWidth,
    this.viewportHeight,
  });

  final CourseTableData courseTableData;
  final bool loading;

  /// Initial visible width of the grid viewport (before user scrolls).
  final double? viewportWidth;

  /// Initial visible height of the grid viewport (before user scrolls).
  final double? viewportHeight;

  static const double _tableHeaderHeight = 25;
  static const double _stubWidth = 20;

  // TODO: dynamic row height based on viewport height
  static const double _periodRowHeight = 64;
  static const double _periodNoonHeight = _periodRowHeight;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // table header with weekday labels, pinned to top when scrolling
        SliverAppBar(
          pinned: true,
          primary: false,
          toolbarHeight: _tableHeaderHeight,
          automaticallyImplyLeading: false,
          backgroundColor: Colors.grey[100],
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          elevation: 0,
          titleSpacing: 0,
          title: _buildHeader(),
        ),

        // table body with period labels and course cells
        SliverToBoxAdapter(
          child: Stack(
            children: [
              _buildPeriodRows(),
              ...(loading ? _buildSkeleton() : _buildCourseCells()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        SizedBox(width: _stubWidth),
        for (var day in _weekDays)
          SizedBox(
            width: (viewportWidth! - _stubWidth) / _weekDays.length,
            child: AutoSizeText(
              day.label,
              textAlign: .center,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
            ),
          ),
      ],
    );
  }

  Widget _buildPeriodRows() {
    return Column(
      crossAxisAlignment: .start,
      children: [
        for (var period in _periods)
          Row(
            children: [
              SizedBox(
                width: _stubWidth,
                height: _periodRowHeight,
                child: Container(
                  alignment: .center,
                  child: AutoSizeText(
                    period.code,
                    textAlign: .center,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                  ),
                ),
              ),
              SizedBox(
                width: viewportWidth! - _stubWidth,
                height: _periodRowHeight,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  List<Widget> _buildSkeleton() {
    final columnWidth = (viewportWidth! - _stubWidth) / _weekDays.length;
    final random = Random();

    // Track occupied slots per day to avoid overlaps
    final occupied = List.generate(_weekDays.length, (_) => <int>{});
    final cells = <Widget>[];

    for (var i = 0; i < 16; i++) {
      final dayIndex = random.nextInt(_weekDays.length);
      final spanLength = 2 + random.nextInt(2); // 2-3 periods
      final maxStart = _periods.length - spanLength;

      // Find a non-overlapping start index
      int? startIndex;
      for (var attempt = 0; attempt < 10; attempt++) {
        final candidate = random.nextInt(maxStart + 1);
        final slots = List.generate(spanLength, (j) => candidate + j);
        if (slots.every((s) => !occupied[dayIndex].contains(s))) {
          startIndex = candidate;
          occupied[dayIndex].addAll(slots);
          break;
        }
      }
      if (startIndex == null) continue;

      final cellTop = startIndex * _periodRowHeight;
      final cellLeft = _stubWidth + (dayIndex * columnWidth);
      final cellHeight = spanLength * _periodRowHeight;
      final delayMs = 50 + random.nextInt(101);
      const riseDurationMs = 350;
      final totalDurationMs = riseDurationMs + delayMs;
      final startAt = delayMs / totalDurationMs;

      cells.add(
        Positioned(
          key: ValueKey('skeleton-$i'),
          top: cellTop,
          left: cellLeft,
          child: SizedBox(
            width: columnWidth,
            height: cellHeight,
            child: Padding(
              padding: const .all(2),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 1, end: 0),
                duration: Duration(milliseconds: totalDurationMs),
                curve: Interval(startAt, 1, curve: Curves.easeOutCubic),
                builder: (context, t, child) {
                  return Opacity(
                    opacity: 1 - t,
                    child: Transform.translate(
                      offset: Offset(0, 16 * t),
                      child: child,
                    ),
                  );
                },
                child: const CourseTableCellSkeleton(),
              ),
            ),
          ),
        ),
      );
    }

    return cells;
  }

  List<Widget> _buildCourseCells() {
    final columnWidth = (viewportWidth! - _stubWidth) / _weekDays.length;
    final random = Random();
    const cellColors = <Color>[
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.red,
    ];

    final sortedEntries = courseTableData.entries.toList()
      ..sort((a, b) {
        final dayComparison = _weekDays
            .indexOf(a.key.day)
            .compareTo(_weekDays.indexOf(b.key.day));
        if (dayComparison != 0) return dayComparison;

        return _periods
            .indexOf(a.key.period)
            .compareTo(_periods.indexOf(b.key.period));
      });

    final cells = <Widget>[];
    for (var i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      final cell = entry.value;
      final dayIndex = _weekDays.indexOf(entry.key.day);
      final startIndex = _periods.indexOf(entry.key.period);

      if (dayIndex == -1 || startIndex == -1) {
        continue;
      }

      final cellTop = startIndex * _periodRowHeight;
      final cellLeft = _stubWidth + (dayIndex * columnWidth);
      final cellHeight =
          (cell.span * _periodRowHeight) +
          (cell.crossesNoon ? _periodNoonHeight : 0);
      final delayMs = 50 + random.nextInt(101);
      const riseDurationMs = 350;
      final totalDurationMs = riseDurationMs + delayMs;
      final startAt = delayMs / totalDurationMs;

      cells.add(
        Positioned(
          key: ValueKey('course-$i'),
          top: cellTop,
          left: cellLeft,
          child: SizedBox(
            width: columnWidth,
            height: cellHeight,
            child: Padding(
              padding: const .all(2),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 1, end: 0),
                duration: Duration(milliseconds: totalDurationMs),
                curve: Interval(startAt, 1, curve: Curves.easeOutCubic),
                builder: (context, t, child) {
                  return Opacity(
                    opacity: 1 - t,
                    child: Transform.translate(
                      offset: Offset(0, 16 * t),
                      child: child,
                    ),
                  );
                },
                child: CourseTableCell(
                  courseTableCellData: cell,
                  cellColor:
                      // TODO: better random color algorithm
                      cellColors[cell.number.hashCode.abs() %
                          cellColors.length],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return cells;
  }
}

@Preview(
  name: 'CourseTableGrid',
  group: 'Course Table',
  size: Size(420, 720),
)
Widget previewCourseTableGrid() {
  return WidgetPreviewFrame(
    child: LayoutBuilder(
      builder: (context, constraints) {
        return CourseTableGrid(
          courseTableData: _previewCourseTableData,
          viewportWidth: constraints.maxWidth,
          viewportHeight: constraints.maxHeight,
        );
      },
    ),
  );
}

final CourseTableData _previewCourseTableData = {
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
  (day: .wednesday, period: .sixth): (
    id: 2,
    number: 'CSIE3045',
    span: 3,
    crossesNoon: false,
    courseName: '雲端平台實作',
    classroomName: '科研B215',
    credits: 3.0,
    hours: 3,
  ),
  (day: .thursday, period: .fourth): (
    id: 3,
    number: 'CSIE3702',
    span: 2,
    crossesNoon: true,
    courseName: '軟體工程',
    classroomName: '科研B112',
    credits: 3.0,
    hours: 3,
  ),
};
