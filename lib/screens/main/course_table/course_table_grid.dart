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

class CourseTableGrid extends StatelessWidget {
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

  final double _tableHeaderHeight = 25;
  final double _stubWidth = 20;

  // TODO: dynamic row height based on viewport height
  final double _periodRowHeight = 60;

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
            children: [_buildPeriodRows(), ..._buildCourseBlocks()],
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
            // TODO: dynamic width
            width: (viewportWidth! - _stubWidth) / 5,
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

  List<Widget> _buildCourseBlocks() {
    final columnWidth = (viewportWidth! - _stubWidth) / _weekDays.length;
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
    for (var i = 0; i < couseTableSummary.courses.length; i++) {
      final course = couseTableSummary.courses[i];
      final dayIndex = _weekDays.indexOf(course.dayOfWeek);
      final startIndex = _periods.indexOf(course.startSection);
      final endIndex = _periods.indexOf(course.endSection);

      if (dayIndex == -1 || startIndex == -1 || endIndex == -1) {
        continue;
      }

      final blockTop = startIndex * _periodRowHeight;
      final blockLeft = _stubWidth + (dayIndex * columnWidth);
      final blockHeight = (endIndex - startIndex + 1) * _periodRowHeight;

      blocks.add(
        Positioned(
          top: blockTop,
          left: blockLeft,
          child: SizedBox(
            width: columnWidth,
            height: blockHeight,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: CourseTableBlock(
                courseBlock: course,
                blockColor: blockColors[i % blockColors.length],
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
    child: CourseTableGrid(
      couseTableSummary: _previewCourseTableSummary,
      viewportWidth: 420,
      viewportHeight: 720,
    ),
  );
}

final CourseTableSummaryObject _previewCourseTableSummary = (
  semester: Semester(id: 1, year: 114, term: 2),
  courses: [
    (
      courseInfo: (
        number: 'CSIE3002',
        courseNameZh: '作業系統',
        teacherNamesZh: ['陳大文'],
        credits: 3.0,
        hours: 3,
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
