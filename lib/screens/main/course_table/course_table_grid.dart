import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:tattoo/components/widget_preview_frame.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/repositories/course_repository.dart';
import 'package:tattoo/screens/main/course_table/course_table_cell.dart';
import 'package:tattoo/screens/main/course_table/course_table_detail_sheet.dart';

typedef GridRange = ({
  List<DayOfWeek> visibleDaysOfWeek,
  List<Period> visiblePeriods,
});

class CourseTableGrid extends StatelessWidget {
  CourseTableGrid({
    super.key,
    required this.courseTableData,
    required this.viewportWidth,
    required this.viewportHeight,
    this.loading = false,
  });

  final CourseTableData courseTableData;
  final bool loading;

  /// Initial visible width of the grid viewport (before user scrolls).
  final double viewportWidth;

  /// Initial visible height of the grid viewport (before user scrolls).
  final double viewportHeight;

  static const double _tableHeaderHeight = 25;
  static const double _stubWidth = 20;
  static const double _gridLineThickness = 1;

  late final GridRange _gridRange = _visibleGridRange();
  List<DayOfWeek> get _visibleDaysOfWeek => _gridRange.visibleDaysOfWeek;
  List<Period> get _visiblePeriods => _gridRange.visiblePeriods;

  double get _periodRowHeight =>
      max((viewportHeight - _tableHeaderHeight) / 9, 64.0).toDouble();
  double get _periodNoonHeight => switch (courseTableData.hasNoonCourse) {
    true => _periodRowHeight,
    false => _periodRowHeight / 3,
  };
  double get _dayColumnWidth => min(
    ((viewportWidth - _stubWidth) / _visibleDaysOfWeek.length),
    120,
  ).toDouble();

  double _periodHeight(Period period) => switch (period) {
    Period.nPeriod => _periodNoonHeight,
    _ => _periodRowHeight,
  };

  double _periodTopOffset(List<Period> visiblePeriods, int periodIndex) {
    return visiblePeriods
        .take(periodIndex)
        .fold(0.0, (sum, period) => sum + _periodHeight(period));
  }

  double _visiblePeriodSpanHeight(
    List<Period> visiblePeriods,
    int startIndex,
    int span,
  ) {
    return visiblePeriods
        .skip(startIndex)
        .take(span)
        .fold(0.0, (sum, period) => sum + _periodHeight(period));
  }

  double _courseCellHeight(
    List<Period> visiblePeriods,
    int startIndex,
    CourseTableCellData cell,
  ) {
    var remainingPeriods = cell.span;
    var includeSyntheticNoonGap =
        cell.crossesNoon && !courseTableData.hasNoonCourse;
    var totalHeight = 0.0;

    for (final period in visiblePeriods.skip(startIndex)) {
      if (period == Period.nPeriod && includeSyntheticNoonGap) {
        totalHeight += _periodNoonHeight;
        includeSyntheticNoonGap = false;
        continue;
      }

      totalHeight += _periodHeight(period);
      remainingPeriods--;
      if (remainingPeriods == 0) {
        break;
      }
    }

    return totalHeight;
  }

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
          title: _buildHeader(_visibleDaysOfWeek),
        ),

        // table body with period labels and course cells
        SliverToBoxAdapter(
          child: Stack(
            children: [
              _buildPeriodRows(_visiblePeriods),
              ..._buildHorizontalGridLines(_visiblePeriods, context),
              ...(loading
                  ? _buildSkeleton(_visibleDaysOfWeek, _visiblePeriods)
                  : _buildCourseCells(
                      context,
                      _visibleDaysOfWeek,
                      _visiblePeriods,
                    )),
            ],
          ),
        ),
      ],
    );
  }

  GridRange _visibleGridRange() {
    final weekdays = DayOfWeek.values
        .where((day) => day.isWeekday)
        .toList(growable: false);
    final defaultPeriods = Period.values
        .where(
          (period) => period.isAM || period == Period.nPeriod || period.isPM,
        )
        .toList(growable: false);

    if (courseTableData.isEmpty) {
      return (visibleDaysOfWeek: weekdays, visiblePeriods: defaultPeriods);
    }

    final visibleDays = switch ((
      courseTableData.hasWeekdayCourse,
      courseTableData.hasSaturdayCourse,
      courseTableData.hasSundayCourse,
    )) {
      (true, true, true) => [...weekdays, DayOfWeek.saturday, DayOfWeek.sunday],
      (true, true, false) => [...weekdays, DayOfWeek.saturday],
      (true, false, true) => [...weekdays, DayOfWeek.sunday],
      (true, false, false) => [...weekdays],
      (false, true, true) => [DayOfWeek.saturday, DayOfWeek.sunday],
      (false, true, false) => [DayOfWeek.saturday],
      (false, false, true) => [DayOfWeek.sunday],
      (false, false, false) => <DayOfWeek>[],
    };
    final visiblePeriods = <Period>[];

    void addPeriod(Period period) {
      if (!visiblePeriods.contains(period)) {
        visiblePeriods.add(period);
      }
    }

    void addPeriods(Iterable<Period> periods) {
      for (final period in periods) {
        addPeriod(period);
      }
    }

    switch ((
      courseTableData.hasAMCourse,
      courseTableData.hasNoonCourse,
      courseTableData.hasPMCourse,
    )) {
      case (false, false, false):
        break;
      case (true, false, false):
        addPeriods(Period.values.where((period) => period.isAM));
        break;
      case (false, true, false):
        addPeriod(Period.nPeriod);
        break;
      case (false, false, true):
        addPeriods(Period.values.where((period) => period.isPM));
        break;
      case (true, true, false):
        addPeriods(Period.values.where((period) => period.isAM));
        addPeriod(Period.nPeriod);
        break;
      case (false, true, true):
        addPeriod(Period.nPeriod);
        addPeriods(Period.values.where((period) => period.isPM));
        break;
      case (true, false, true):
      case (true, true, true):
        addPeriods(Period.values.where((period) => period.isAM));
        addPeriod(Period.nPeriod);
        addPeriods(Period.values.where((period) => period.isPM));
        break;
    }

    final isEveningOnly =
        !courseTableData.hasAMCourse &&
        !courseTableData.hasPMCourse &&
        courseTableData.hasEveningCourse;

    switch ((
      courseTableData.hasEveningCourse,
      isEveningOnly,
      courseTableData.latestPeriod,
    )) {
      case (false, _, _):
        break;
      case (true, true, _):
        addPeriods(Period.values.where((period) => period.isEvening));
        break;
      case (true, false, Period lastPeriod):
        addPeriods(
          Period.values
              .skip(visiblePeriods.last.index + 1)
              .take(lastPeriod.index - visiblePeriods.last.index),
        );
        break;
      case (true, false, null):
        break;
    }

    return (
      visibleDaysOfWeek: visibleDays.isEmpty ? weekdays : visibleDays,
      visiblePeriods: visiblePeriods.isEmpty ? defaultPeriods : visiblePeriods,
    );
  }

  Widget _buildHeader(List<DayOfWeek> visibleDaysOfWeek) {
    return Row(
      children: [
        SizedBox(width: _stubWidth),
        for (var day in visibleDaysOfWeek)
          SizedBox(
            width: _dayColumnWidth,
            child: AutoSizeText(
              t.courseTable.dayOfWeek[day.name]!,
              textAlign: .center,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
            ),
          ),
      ],
    );
  }

  Widget _buildPeriodRows(List<Period> visiblePeriods) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        for (var period in visiblePeriods)
          Row(
            children: [
              SizedBox(
                width: _stubWidth,
                height: _periodHeight(period),
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
                width: viewportWidth - _stubWidth,
                height: _periodHeight(period),
                child: const SizedBox.shrink(),
              ),
            ],
          ),
      ],
    );
  }

  List<Widget> _buildHorizontalGridLines(
    List<Period> visiblePeriods,
    BuildContext context,
  ) {
    final gridWidth = max(0.0, viewportWidth - _stubWidth);

    return [
      for (var i = 1; i < visiblePeriods.length; i++)
        Positioned(
          top: _periodTopOffset(visiblePeriods, i) - (_gridLineThickness / 2),
          left: _stubWidth,
          child: Container(
            width: gridWidth,
            height: _gridLineThickness,
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
    ];
  }

  List<Widget> _buildSkeleton(
    List<DayOfWeek> visibleDaysOfWeek,
    List<Period> visiblePeriods,
  ) {
    final columnWidth = _dayColumnWidth;
    // Derive a stable seed from the widget key so each semester keeps its own
    // placeholder layout across rebuilds without adding another parameter.
    final random = Random(key.hashCode);

    // Track occupied slots per day to avoid overlaps
    final occupied = List.generate(visibleDaysOfWeek.length, (_) => <int>{});
    final cells = <Widget>[];

    for (var i = 0; i < 16; i++) {
      final dayIndex = random.nextInt(visibleDaysOfWeek.length);
      final spanLength = 2 + random.nextInt(2); // 2-3 periods
      final maxStart = visiblePeriods.length - spanLength;

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

      final cellTop = _periodTopOffset(visiblePeriods, startIndex);
      final cellLeft = _stubWidth + (dayIndex * columnWidth);
      final cellHeight = _visiblePeriodSpanHeight(
        visiblePeriods,
        startIndex,
        spanLength,
      );
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

  List<Widget> _buildCourseCells(
    BuildContext context,
    List<DayOfWeek> visibleDaysOfWeek,
    List<Period> visiblePeriods,
  ) {
    const List<Color> cellColors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
      Colors.deepOrange,
      Colors.lightGreen,
      Colors.deepPurple,
      Colors.lightBlue,
      Colors.lime,
      Colors.brown,
      Colors.blueGrey,
      Colors.redAccent,
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.tealAccent,
      Colors.pinkAccent,
      Colors.indigoAccent,
      Colors.amberAccent,
      Colors.cyanAccent,
      Colors.deepOrangeAccent,
      Colors.lightGreenAccent,
      Colors.deepPurpleAccent,
      Colors.lightBlueAccent,
      Colors.limeAccent,
      Colors.yellow,
      Colors.grey,
      Colors.yellowAccent,
    ];

    final columnWidth = _dayColumnWidth;
    final random = Random();
    final availableColors = cellColors.reversed.toList(growable: true);
    final colorByCourseNumber = <String, Color>{};

    Color resolveCellColor(String courseNumber) {
      return colorByCourseNumber.putIfAbsent(courseNumber, () {
        if (availableColors.isEmpty) {
          availableColors.addAll(cellColors.reversed);
        }

        return availableColors.removeLast();
      });
    }

    final sortedEntries = courseTableData.entries.toList()
      ..sort((a, b) {
        final dayComparison = visibleDaysOfWeek
            .indexOf(a.key.day)
            .compareTo(visibleDaysOfWeek.indexOf(b.key.day));
        if (dayComparison != 0) return dayComparison;

        return visiblePeriods
            .indexOf(a.key.period)
            .compareTo(visiblePeriods.indexOf(b.key.period));
      });

    final cells = <Widget>[];
    for (var i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      final cell = entry.value;
      final dayIndex = visibleDaysOfWeek.indexOf(entry.key.day);
      final startIndex = visiblePeriods.indexOf(entry.key.period);

      if (dayIndex == -1 || startIndex == -1) {
        continue;
      }

      final cellTop = _periodTopOffset(visiblePeriods, startIndex);
      final cellLeft = _stubWidth + (dayIndex * columnWidth);
      final cellHeight = _courseCellHeight(visiblePeriods, startIndex, cell);
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
                  cellColor: resolveCellColor(cell.number),
                  onTap: () {
                    showCourseTableDetailSheet(context, cell: cell);
                  },
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
