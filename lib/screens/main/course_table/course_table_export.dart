import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/repositories/course_repository.dart';
import 'package:tattoo/router/app_router.dart';
import 'package:tattoo/screens/main/course_table/course_table_colors.dart';
import 'package:tattoo/screens/main/course_table/course_table_grid.dart';
import 'package:tattoo/services/course_widget_platform.dart';
import 'package:tattoo/services/course_widget_sync.dart';
import 'package:tattoo/utils/auto_spacing.dart';

/// Keeps the fixed export surface painted outside the visible application
/// viewport and services serialized bitmap requests from the sync controller.
class CourseWidgetRenderHost extends ConsumerStatefulWidget {
  const CourseWidgetRenderHost({
    required this.lightColorScheme,
    required this.darkColorScheme,
    required this.child,
    super.key,
  });

  final ColorScheme lightColorScheme;
  final ColorScheme darkColorScheme;
  final Widget child;
  @override
  ConsumerState<CourseWidgetRenderHost> createState() =>
      _CourseWidgetRenderHostState();
}

class _CourseWidgetRenderHostState
    extends ConsumerState<CourseWidgetRenderHost> {
  final _boundaryKey = GlobalKey();
  ProviderSubscription<CourseWidgetSyncController>? _controllerSubscription;
  ProviderSubscription<bool>? _sessionSubscription;
  late final CourseWidgetPlatform _platform;
  CourseWidgetSyncController? _controller;
  CourseWidgetRenderInput? _renderInput;

  @override
  void initState() {
    super.initState();
    _platform = ref.read(courseWidgetPlatformProvider)
      ..setRouteHandler(_handleRoute);
    _controllerSubscription = ref.listenManual(
      courseWidgetSyncControllerProvider,
      (previous, next) {
        previous?.attachRenderer(null);
        _controller = next;
        next.attachRenderer(_render);
      },
      fireImmediately: true,
    );
    _sessionSubscription = ref.listenManual(
      sessionProvider,
      (_, authenticated) {
        if (authenticated) {
          unawaited(_startAfterThemedFrame());
        } else {
          unawaited(_controller?.stopAndClear());
        }
      },
      fireImmediately: true,
    );
  }

  void _handleRoute(String route) {
    if (!mounted || route != AppRoutes.courseTable) return;
    ref.read(pendingAppRouteProvider.notifier).set(route);
    rootNavigatorKey.currentContext?.go(route);
  }

  Future<void> _startAfterThemedFrame() async {
    await WidgetsBinding.instance.endOfFrame;
    final controller = _controller;
    if (!mounted || controller == null || !ref.read(sessionProvider)) return;
    await controller.start();
    if (!mounted || !ref.read(sessionProvider)) return;
    await controller.reconcile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller?.setPresentation((
      locale: Localizations.localeOf(context).toLanguageTag(),
      lightColors: widget.lightColorScheme,
      darkColors: widget.darkColorScheme,
    ));
  }

  @override
  void dispose() {
    _platform.setRouteHandler(null);
    _controller?.attachRenderer(null);
    _controllerSubscription?.close();
    _sessionSubscription?.close();
    super.dispose();
  }

  Future<Uint8List> _render(CourseWidgetRenderInput input) async {
    if (!mounted) throw StateError('Course widget render host is disposed');
    setState(() => _renderInput = input);
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) throw StateError('Course widget render host is disposed');
      final boundary =
          _boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null || boundary.debugNeedsPaint) {
        throw StateError('Course widget export was not fully painted');
      }
      final image = await boundary.toImage(
        pixelRatio: CourseTableExport.pixelRatio,
      );
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        if (data == null) {
          throw StateError('Unable to encode course widget PNG');
        }
        return data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
      } finally {
        image.dispose();
      }
    } finally {
      if (mounted) setState(() => _renderInput = null);
    }
  }

  Widget _buildExport(CourseWidgetRenderInput input) {
    final logicalSize = CourseTableExport.logicalSizeFor(
      input.cache.courseTable,
    );
    return Transform.translate(
      offset: Offset(-logicalSize.width - 1, 0),
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: TickerMode(
            enabled: false,
            child: Theme(
              data: ThemeData(colorScheme: input.colors),
              child: RepaintBoundary(
                key: _boundaryKey,
                child: SizedBox.fromSize(
                  size: logicalSize,
                  child: CourseTableExport(
                    courseTable: input.cache.courseTable,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (_renderInput case final input?) _buildExport(input),
      ],
    );
  }
}

/// Timetable surface whose aspect ratio follows its visible days and periods.
class CourseTableExport extends StatelessWidget {
  const CourseTableExport({
    required this.courseTable,
    super.key,
  });

  static const pixelRatio = 4.0;

  static const _outerPadding = 4.0;
  static const _weekdayHeaderHeight = 20.0;
  static const _periodStubWidth = 18.0;
  static const _dayColumnWidth = 44.8;
  static const _periodRowHeight = 32.0;

  /// Preserves stable cell geometry while omitting unused rows and columns.
  static Size logicalSizeFor(CourseTableData courseTable) {
    final range = courseTableGridRange(courseTable);
    return Size(
      _outerPadding * 2 +
          _periodStubWidth +
          _dayColumnWidth * range.visibleDaysOfWeek.length,
      _outerPadding * 2 +
          _weekdayHeaderHeight +
          _periodRowHeight * range.visiblePeriods.length,
    );
  }

  final CourseTableData courseTable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final range = courseTableGridRange(courseTable);
    final days = range.visibleDaysOfWeek;
    final periods = range.visiblePeriods;
    const rowHeight = _periodRowHeight;
    const dayWidth = _dayColumnWidth;
    final gridHeight = rowHeight * periods.length;
    final colorByCourseId = buildCourseTableColorMap(courseTable);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: .noScaling),
      child: ColoredBox(
        color: colors.surface,
        child: Padding(
          padding: const EdgeInsets.all(_outerPadding),
          child: DefaultTextStyle(
            style: TextStyle(color: colors.onSurface),
            child: Column(
              children: [
                SizedBox(
                  height: _weekdayHeaderHeight,
                  child: Row(
                    children: [
                      const SizedBox(width: _periodStubWidth),
                      for (final day in days)
                        SizedBox(
                          width: dayWidth,
                          child: Text(
                            t.courseTable.dayOfWeek[day.name]!,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: gridHeight,
                  child: Stack(
                    children: [
                      _PeriodLabels(
                        periods: periods,
                        rowHeight: rowHeight,
                      ),
                      for (final entry in courseTable.scheduled.entries)
                        if (days.contains(entry.key.day) &&
                            periods.contains(entry.key.period))
                          _courseCell(
                            entry: entry,
                            periods: periods,
                            days: days,
                            rowHeight: rowHeight,
                            dayWidth: dayWidth,
                            baseColor: colorByCourseId[entry.value.id]!,
                            brightness: theme.brightness,
                          ),
                      if (courseTable.scheduled.isEmpty)
                        Positioned(
                          left: _periodStubWidth,
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: Text(
                              t.courseTable.notFound,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _courseCell({
    required MapEntry<({DayOfWeek day, Period period}), CourseTableCellData>
    entry,
    required List<Period> periods,
    required List<DayOfWeek> days,
    required double rowHeight,
    required double dayWidth,
    required Color baseColor,
    required Brightness brightness,
  }) {
    final cell = entry.value;
    final dayIndex = days.indexOf(entry.key.day);
    final periodIndex = periods.indexOf(entry.key.period);
    final palette = courseTableCellPalette(baseColor, brightness);
    final courseTitle = cell.courseName.isNotEmpty
        ? cell.courseName
        : cell.number ?? '';
    final representedRows = cell.span + (cell.crossesNoon ? 1 : 0);

    return Positioned(
      left: _periodStubWidth + dayIndex * dayWidth + 1,
      top: periodIndex * rowHeight + 1,
      width: dayWidth - 2,
      height: representedRows * rowHeight - 2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
        decoration: BoxDecoration(
          color: palette.container,
          border: Border.all(color: palette.border, width: 1),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AutoSizeText(
              courseTitle.spaced,
              style: TextStyle(
                color: palette.foreground,
                fontSize: 8,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
              minFontSize: 6,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            if (cell.classroomName case final classroom?
                when classroom.isNotEmpty)
              AutoSizeText(
                classroom.spaced,
                style: TextStyle(
                  color: palette.foreground,
                  fontSize: 7,
                  height: 1,
                ),
                minFontSize: 6,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}

class _PeriodLabels extends StatelessWidget {
  const _PeriodLabels({
    required this.periods,
    required this.rowHeight,
  });

  final List<Period> periods;
  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CourseTableExport._periodStubWidth,
      child: Column(
        children: [
          for (final period in periods)
            SizedBox(
              height: rowHeight,
              child: Center(
                child: Text(
                  period.code,
                  style: const TextStyle(fontSize: 7),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
