import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tattoo/components/option_entry_tile.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/course_repository.dart';
import 'package:tattoo/repositories/preferences_repository.dart';
import 'package:tattoo/router/app_router.dart';
import 'package:tattoo/screens/main/profile/preference_providers.dart';
import 'package:tattoo/services/update_service.dart';
import 'package:tattoo/screens/main/course_table/course_table_detail_sheet.dart';
import 'package:tattoo/screens/main/course_table_providers.dart';
import 'package:tattoo/screens/main/home/home_providers.dart';
import 'package:tattoo/screens/main/home/next_course_card.dart';
import 'package:tattoo/screens/main/home/next_course_carousel.dart';
import 'package:tattoo/utils/auto_spacing.dart';
import 'package:tattoo/utils/course_schedule.dart';
import 'package:tattoo/utils/launch_url.dart';

class MainHomeScreen extends ConsumerStatefulWidget {
  const MainHomeScreen({super.key});

  @override
  ConsumerState<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends ConsumerState<MainHomeScreen> {
  bool _updateSnackbarCheckScheduled = false;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    ref.listenManual(updateConfigProvider, (_, _) {
      _scheduleUpdateSnackbarCheck();
    });
    _scheduleUpdateSnackbarCheck();
  }

  /// Schedules the snackbar check after the current frame so
  /// [ScaffoldMessenger] is available.
  void _scheduleUpdateSnackbarCheck() {
    if (_updateSnackbarCheckScheduled) return;
    _updateSnackbarCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSnackbarCheckScheduled = false;
      _maybeShowUpdateSnackbar();
    });
  }

  /// Shows a floating snackbar when an optional update is pending and the user
  /// has not already dismissed it this session.
  void _maybeShowUpdateSnackbar() {
    if (!mounted) return;
    final config = ref.read(updateConfigProvider);

    // Clear an obsolete optional snackbar when the update is removed or forced.
    if (config == null || config.isForcedUpdate) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      return;
    }

    final dismissed = ref.read(optionalUpdateDismissedProvider);
    if (dismissed) return;

    // Mark as dismissed so the snackbar isn't re-shown on hot-reload / re-entry.
    ref.read(optionalUpdateDismissedProvider.notifier).dismiss();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t.forceUpdate.title),
        behavior: .fixed,
        duration: const Duration(seconds: 8),
        // Breaking change in Flutter 3.38, when snack bar with action, auto-dismiss will be disaable unless set persist=false.
        persist: false,
        action: SnackBarAction(
          label: t.forceUpdate.view,
          onPressed: () => context.push(AppRoutes.update),
        ),
      ),
    );
  }

  void _showAdjacentCourseDate(
    CourseTableData? courseTable,
    DateTime displayedDate,
    CourseDateDirection direction,
  ) {
    if (courseTable == null) return;
    if (adjacentCourseDate(
          courseTable,
          date: displayedDate,
          direction: direction,
        )
        case final date?) {
      setState(() => _selectedDate = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(homeClockProvider).asData?.value ?? DateTime.now();
    final today = DateUtils.dateOnly(now);
    final displayedDate = _selectedDate ?? today;
    final semestersAsync = ref.watch(courseTableSemestersProvider);
    final latestSemesterId = switch (semestersAsync) {
      AsyncValue(value: final semesters?, hasValue: true)
          when semesters.isNotEmpty =>
        semesters.first.id,
      _ => null,
    };
    final courseTableAsync = switch (latestSemesterId) {
      final latestSemesterId? => ref.watch(
        courseTableProvider(latestSemesterId),
      ),
      null => null,
    };
    final courseTable = switch (courseTableAsync) {
      AsyncValue(value: final courseTable, hasValue: true) => courseTable,
      _ => null,
    };
    final isCourseScheduleLoading =
        (semestersAsync.isLoading && !semestersAsync.hasValue) ||
        switch (courseTableAsync) {
          final courseTableAsync? =>
            courseTableAsync.isLoading && !courseTableAsync.hasValue,
          null => false,
        };
    final meetings = switch (courseTable) {
      final courseTable? => courseMeetingsForDate(
        courseTable,
        date: displayedDate,
        now: now,
      ),
      null => <CourseScheduleMeeting>[],
    };
    final dayLabel = _courseDateLabel(displayedDate, today: today);
    final nextCoursePosition = switch (courseTable) {
      final courseTable? => nextCourseMeetingPosition(courseTable, now: now),
      null => null,
    };
    final courses = [
      for (final (index, meeting) in meetings.indexed)
        _toNextCourse(
          meeting,
          dayLabel: dayLabel,
          now: now,
          isNextCourse:
              nextCoursePosition?.index == index &&
              DateUtils.isSameDay(nextCoursePosition?.date, displayedDate),
        ),
    ];
    final initialCourseIndex = switch ((meetings.isEmpty, displayedDate)) {
      (true, _) => null,
      (false, final date) when DateUtils.isSameDay(date, today) =>
        preferredTodayCourseIndex(meetings, now: now),
      (false, _) => 0,
    };
    final options = [
      OptionEntryTile.svg(
        svgIconAsset: "assets/tat_icon.svg",
        actionIcon: .exitToApp,
        title: t.home.projectTattoo.title.spaced,
        description: t.home.projectTattoo.description,
        onTap: () => launchUrl(.parse(t.home.projectTattoo.url)),
      ),
      OptionEntryTile.icon(
        icon: Icons.explore_outlined,
        actionIcon: .exitToApp,
        title: t.home.ideation.title.spaced,
        description: t.home.ideation.description,
        onTap: () => launchUrl(
          .parse(t.home.ideation.url),
        ),
      ),
      OptionEntryTile.svg(
        svgIconAsset: "assets/npc_logo.svg",
        actionIcon: .exitToApp,
        title: t.home.npcClub.title,
        description: t.home.npcClub.description,
        onTap: () => launchUrl(.parse(t.home.npcClub.url)),
      ),
      ...(_showVoteEntry()
          ? <Widget>[
              OptionEntryTile.icon(
                icon: Icons.how_to_vote_outlined,
                title: t.nav.vote,
                description: t.home.vote.description.spaced,
                onTap: () => context.push(AppRoutes.kioskLoginQr),
              ),
            ]
          : <Widget>[]),
      OptionEntryTile.icon(
        icon: Icons.qr_code_scanner,
        title: t.scanner.loginIStudy.spaced,
        onTap: () => context.push(AppRoutes.scanner),
      ),
      OptionEntryTile.icon(
        icon: Icons.switch_access_shortcut_outlined,
        title: t.nav.portal,
        onTap: () => context.push(AppRoutes.portal),
      ),
      OptionEntryTile.icon(
        icon: Icons.calendar_month,
        title: t.nav.calendar,
        onTap: () => context.push(AppRoutes.calendar),
      ),
      if (Theme.of(context).platform == TargetPlatform.android &&
          ref.pref(PrefKey.showWifiButton))
        OptionEntryTile.icon(
          icon: Icons.wifi,
          title: t.home.campusWifi.spaced,
          onTap: () => context.push(AppRoutes.ntutWifi),
        ),
    ];

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const .all(16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  spacing: 16,
                  children: [
                    NextCourseCarousel(
                      courses: courses,
                      initialCourseIndex: initialCourseIndex,
                      loading: isCourseScheduleLoading,
                      onPreviousDate: () => _showAdjacentCourseDate(
                        courseTable,
                        displayedDate,
                        .previous,
                      ),
                      onNextDate: () => _showAdjacentCourseDate(
                        courseTable,
                        displayedDate,
                        .next,
                      ),
                      onCourseTap: (course) {
                        if (course.courseNumber case final number?) {
                          showCourseTableDetailSheet(context, number: number);
                        }
                      },
                    ),
                    Column(
                      spacing: 8,
                      children: options,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

NextCourse _toNextCourse(
  CourseScheduleMeeting meeting, {
  required String dayLabel,
  required DateTime now,
  required bool isNextCourse,
}) {
  final NextCourseState state = switch ((meeting.start, meeting.end)) {
    (final start, _)
        when start.isAfter(now) &&
            !start.isAfter(now.add(const Duration(minutes: 30))) =>
      .imminent,
    _ when meeting.isOngoing => .ongoing,
    (_, final end) when !end.isAfter(now) => .finished,
    _ when isNextCourse => .upcoming,
    _ => .scheduled,
  };
  return NextCourse(
    title: meeting.course.courseName,
    courseNumber: meeting.course.number,
    teacher: meeting.course.teacherNames.isEmpty
        ? '-'
        : meeting.course.teacherNames.join('、'),
    classroom: meeting.course.classroomName ?? '-',
    time: '${_formatTime(meeting.start)} - ${_formatTime(meeting.end)}',
    dayLabel: dayLabel,
    state: state,
  );
}

String _courseDateLabel(DateTime date, {required DateTime today}) {
  if (DateUtils.isSameDay(date, today)) return t.home.today;
  if (DateUtils.isSameDay(date, today.add(const Duration(days: 1)))) {
    return t.home.tomorrow;
  }
  if (DateUtils.isSameDay(date, today.subtract(const Duration(days: 1)))) {
    return t.home.yesterday;
  }

  final dayKey = switch (date.weekday) {
    DateTime.monday => 'monday',
    DateTime.tuesday => 'tuesday',
    DateTime.wednesday => 'wednesday',
    DateTime.thursday => 'thursday',
    DateTime.friday => 'friday',
    DateTime.saturday => 'saturday',
    DateTime.sunday => 'sunday',
    _ => throw StateError('Unsupported weekday: ${date.weekday}'),
  };
  return t.home.weekday(day: t.courseTable.dayOfWeek[dayKey]!);
}

String _formatTime(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}';

bool _showVoteEntry() => DateTime.now()
    .toUtc()
    .add(const Duration(hours: 8))
    .isBefore(.utc(2026, 5, 16));
