import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:tattoo/components/widget_preview_frame.dart';
import 'package:tattoo/database/database.dart' show Semester;
import 'package:tattoo/models/course.dart';
import 'package:tattoo/repositories/course_repository.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:tattoo/screens/main/course_table/course_table_block.dart';

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

class CourseTableGrid extends StatefulWidget {
  const CourseTableGrid({
    super.key,
    required this.couseTableSummary,
    this.viewportWidth,
    this.viewportHeight,
  });

  final CourseTableSummaryObject couseTableSummary;

  /// Initial visible width of the grid viewport (before user scrolls).
  final double? viewportWidth;

  /// Initial visible height of the grid viewport (before user scrolls).
  final double? viewportHeight;

  @override
  State<CourseTableGrid> createState() => _CourseTableGridState();
}

class _CourseTableGridState extends State<CourseTableGrid> {
  bool _loading = true;

  final double _tableHeaderHeight = 25;
  final double _stubWidth = 20;

  // TODO: dynamic row height based on viewport height
  final double _periodRowHeight = 64;

  @override
  void initState() {
    super.initState();
    final random = Random();
    Future.delayed(Duration(milliseconds: random.nextInt(1000)), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
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
        SliverToBoxAdapter(
          child: Stack(
            children: [
              _buildPeriodRows(),
              ...(_loading ? _bulidSkeleton() : _buildCourseBlocks()),
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
            width: (widget.viewportWidth! - _stubWidth) / _weekDays.length,
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
                width: widget.viewportWidth! - _stubWidth,
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

  
  List<Widget> _bulidSkeleton() {
    final columnWidth = (widget.viewportWidth! - _stubWidth) / _weekDays.length;
    final random = Random();

    // Track occupied slots per day to avoid overlaps
    final occupied = List.generate(_weekDays.length, (_) => <int>{});
    final blocks = <Widget>[];

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

      final blockTop = startIndex * _periodRowHeight;
      final blockLeft = _stubWidth + (dayIndex * columnWidth);
      final blockHeight = spanLength * _periodRowHeight;
      final delayMs = 50 + random.nextInt(101);
      const riseDurationMs = 350;
      final totalDurationMs = riseDurationMs + delayMs;
      final startAt = delayMs / totalDurationMs;

      blocks.add(
        Positioned(
          key: ValueKey('skeleton-$i'),
          top: blockTop,
          left: blockLeft,
          child: SizedBox(
            width: columnWidth,
            height: blockHeight,
            child: Padding(
              padding: const EdgeInsets.all(2),
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
                child: const CourseTableBlockSkeleton(),
              ),
            ),
          ),
        ),
      );
    }

    return blocks;
  }

  List<Widget> _buildCourseBlocks() {
    final columnWidth = (widget.viewportWidth! - _stubWidth) / _weekDays.length;
    final random = Random();
    const blockColors = <Color>[
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.red,
    ];

    final blocks = <Widget>[];
    for (var i = 0; i < widget.couseTableSummary.courses.length; i++) {
      final course = widget.couseTableSummary.courses[i];
      final dayIndex = _weekDays.indexOf(course.dayOfWeek);
      final startIndex = _periods.indexOf(course.startSection);
      final endIndex = _periods.indexOf(course.endSection);

      if (dayIndex == -1 || startIndex == -1 || endIndex == -1) {
        continue;
      }

      final blockTop = startIndex * _periodRowHeight;
      final blockLeft = _stubWidth + (dayIndex * columnWidth);
      final blockHeight = (endIndex - startIndex + 1) * _periodRowHeight;
      final delayMs = 50 + random.nextInt(101);
      const riseDurationMs = 350;
      final totalDurationMs = riseDurationMs + delayMs;
      final startAt = delayMs / totalDurationMs;

      blocks.add(
        Positioned(
          key: ValueKey('course-$i'),
          top: blockTop,
          left: blockLeft,
          child: SizedBox(
            width: columnWidth,
            height: blockHeight,
            child: Padding(
              padding: const EdgeInsets.all(2),
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
                child: CourseTableBlock(
                  courseBlock: course,
                  blockColor: blockColors[i % blockColors.length],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return blocks;
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
          couseTableSummary: _previewCourseTableSummary,
          viewportWidth: constraints.maxWidth,
          viewportHeight: constraints.maxHeight,
        );
      },
    ),
  );
}

final CourseTableSummaryObject _previewCourseTableSummary = (
  semester: Semester(id: 1, year: 114, term: 2),
  courses: [
    (
      courseNumber: 'CSIE3002',
      courseNameZh: '作業系統',
      classroomNameZh: '共同科館201',
      dayOfWeek: DayOfWeek.monday,
      startSection: Period.first,
      endSection: Period.second,
    ),
  ],
  hasAmCourse: true,
  hasNCourse: false,
  hasPmCourse: false,
  hasNightCourse: false,
  earliestStartSection: Period.first,
  latestEndSection: Period.second,
  hasWeekdayCourse: true,
  hasSatCourse: false,
  hasSunCourse: false,
  totalCredits: 3.0,
  totalHours: 3,
);
