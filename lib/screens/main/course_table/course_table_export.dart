import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/repositories/course_repository.dart';
import 'package:tattoo/router/app_router.dart';
import 'package:tattoo/screens/main/course_table/course_table_cell.dart';
import 'package:tattoo/screens/main/course_table/course_table_colors.dart';
import 'package:tattoo/screens/main/course_table/course_table_grid.dart';
import 'package:tattoo/services/course_widget_platform.dart';
import 'package:tattoo/services/course_widget_sync.dart';

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
  Future<void> _sessionTransition = Future.value();
  var _sessionGeneration = 0;

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
      (_, authenticated) => _queueSessionTransition(authenticated),
      fireImmediately: true,
    );
  }

  void _queueSessionTransition(bool authenticated) {
    final generation = ++_sessionGeneration;
    final previous = _sessionTransition;
    _sessionTransition = () async {
      await previous;
      if (!mounted) return;
      try {
        if (authenticated) {
          if (generation != _sessionGeneration || !ref.read(sessionProvider)) {
            return;
          }
          await _startAfterThemedFrame();
        } else {
          await _controller?.stopAndClear();
        }
      } catch (error, stackTrace) {
        debugPrint(
          'Course widget authentication transition failed: '
          '$error\n$stackTrace',
        );
      }
    }();
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
    return Positioned(
      left: -logicalSize.width - 1,
      top: 0,
      width: logicalSize.width,
      height: logicalSize.height,
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: TickerMode(
            enabled: false,
            child: Theme(
              data: ThemeData(colorScheme: input.colors),
              child: RepaintBoundary(
                key: _boundaryKey,
                child: CourseTableExport(
                  courseTable: input.cache.courseTable,
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
      clipBehavior: .none,
      children: [
        widget.child,
        if (_renderInput case final input?) _buildExport(input),
      ],
    );
  }
}

/// Timetable surface whose aspect ratio follows its visible days and periods.
///
/// Shared [CourseTableCell] widgets are laid out at a supported size and scaled
/// into the fixed export geometry without changing the interactive table.
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

  // Lay out the shared cell above its minimum height before scaling it down.
  static const _cellLayoutScale = 56.0 / (_periodRowHeight - 2);

  static CourseTableGridMetrics _metricsFor(
    CourseTableData courseTable,
    CourseTableGridRange range,
  ) => CourseTableGridMetrics(
    visiblePeriods: range.visiblePeriods,
    hasNoonCourse: courseTable.hasNoonCourse,
    rowHeight: _periodRowHeight,
  );

  /// Preserves stable cell geometry while omitting unused rows and columns.
  static Size logicalSizeFor(CourseTableData courseTable) {
    final range = courseTableGridRange(courseTable);
    return Size(
      _outerPadding * 2 +
          _periodStubWidth +
          _dayColumnWidth * range.visibleDaysOfWeek.length,
      _outerPadding * 2 +
          _weekdayHeaderHeight +
          _metricsFor(courseTable, range).gridHeight,
    );
  }

  final CourseTableData courseTable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final range = courseTableGridRange(courseTable);
    final days = range.visibleDaysOfWeek;
    final metrics = _metricsFor(courseTable, range);
    const dayWidth = _dayColumnWidth;
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
                  height: metrics.gridHeight,
                  child: Stack(
                    children: [
                      _PeriodLabels(metrics: metrics),
                      for (final entry in courseTable.scheduled.entries)
                        if (days.contains(entry.key.day) &&
                            metrics.visiblePeriods.contains(entry.key.period))
                          _courseCell(
                            entry: entry,
                            metrics: metrics,
                            days: days,
                            dayWidth: dayWidth,
                            baseColor: colorByCourseId[entry.value.id]!,
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
    required CourseTableGridMetrics metrics,
    required List<DayOfWeek> days,
    required double dayWidth,
    required Color baseColor,
  }) {
    final cell = entry.value;
    final dayIndex = days.indexOf(entry.key.day);
    final periodIndex = metrics.visiblePeriods.indexOf(entry.key.period);
    final cellWidth = dayWidth - 2;
    final cellHeight = metrics.courseCellHeight(periodIndex, cell) - 2;

    return Positioned(
      left: _periodStubWidth + dayIndex * dayWidth + 1,
      top: metrics.periodTopOffset(periodIndex) + 1,
      width: cellWidth,
      height: cellHeight,
      child: FittedBox(
        child: SizedBox(
          width: cellWidth * _cellLayoutScale,
          height: cellHeight * _cellLayoutScale,
          child: CourseTableCell(
            courseTableCellData: cell,
            cellColor: baseColor,
          ),
        ),
      ),
    );
  }
}

class _PeriodLabels extends StatelessWidget {
  const _PeriodLabels({required this.metrics});

  final CourseTableGridMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CourseTableExport._periodStubWidth,
      child: Column(
        children: [
          for (final period in metrics.visiblePeriods)
            SizedBox(
              height: metrics.periodHeight(period),
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
