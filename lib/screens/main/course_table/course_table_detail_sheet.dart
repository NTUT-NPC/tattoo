import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tattoo/components/chip_tab_switcher.dart';
import 'package:tattoo/components/i_school_plus_network_guide.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/repositories/course_repository.dart';
import 'package:tattoo/repositories/preferences_repository.dart';
import 'package:tattoo/screens/main/course_table/course_materials_list.dart';
import 'package:tattoo/screens/main/course_table/course_table_providers.dart';
import 'package:tattoo/screens/main/i_school_plus_providers.dart';
import 'package:tattoo/screens/main/profile/preference_providers.dart';
import 'package:tattoo/shells/centered_max_width_frame.dart';
import 'package:tattoo/utils/auto_spacing.dart';
import 'package:tattoo/utils/localized.dart';

Future<void> showCourseTableDetailSheet(
  BuildContext context, {
  required String number,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
    builder: (context) => Align(
      alignment: Alignment.bottomCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: contentMaxWidth),
        child: CourseTableDetailSheet(number: number),
      ),
    ),
  );
}

class CourseTableDetailSheet extends ConsumerWidget {
  const CourseTableDetailSheet({super.key, required this.number});

  /// The course number (課號) identifying the offering to show.
  final String number;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(courseOfferingProvider(number));

    return SafeArea(
      top: false,
      child: Padding(
        padding: const .fromLTRB(16, 8, 16, 16),
        child: switch (detailAsync) {
          AsyncData(value: final detail?) => SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.85,
            child: _CourseDetailContent(detail: detail),
          ),
          AsyncData() => _DetailState(
            icon: Icons.search_off_outlined,
            message: t.courseTable.notFound,
          ),
          AsyncError(:final error) => _DetailState(
            icon: Icons.error_outline,
            message: 'Error: $error',
          ),
          _ => const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator()),
          ),
        },
      ),
    );
  }
}

class _CourseDetailContent extends ConsumerWidget {
  const _CourseDetailContent({required this.detail});

  final CourseOfferingDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final overview = detail.overview;
    final title =
        _normalizedText(localized(overview.nameZh, overview.nameEn)) ??
        _normalizedText(overview.number) ??
        t.general.unknown;
    final teachers = detail.teachers
        .map(
          (teacher) => _normalizedText(
            localized(teacher.nameZh, teacher.nameEn),
          ),
        )
        .nonNulls
        .join('、');
    final classrooms = detail.schedule
        .map(
          (slot) => _normalizedText(
            localized(slot.classroomNameZh, slot.classroomNameEn),
          ),
        )
        .nonNulls
        .toSet()
        .join('、');
    final periodsByDay = <DayOfWeek, List<String>>{};
    for (final slot in detail.schedule) {
      (periodsByDay[slot.day] ??= []).add(slot.period.code);
    }
    final periods = periodsByDay.entries
        .map(
          (entry) => '${_dayOfWeekLabel(entry.key)} ${entry.value.join('、')}',
        )
        .join('；');
    final syllabusAsync = switch (overview.number) {
      final courseNumber? => ref.watch(
        syllabusProvider((
          courseNumber: courseNumber,
          language: switch (LocaleSettings.currentLocale) {
            .zhTw => .zhTw,
            .enUs => .enUs,
          },
        )),
      ),
      null => null,
    };
    final syllabus = switch (syllabusAsync) {
      AsyncData(value: final syllabuses) => _SyllabusTabs(
        details: syllabuses,
      ),
      AsyncError(:final error) => _DetailState(
        icon: Icons.error_outline,
        message: 'Error: $error',
      ),
      AsyncLoading() => const Padding(
        padding: .symmetric(horizontal: 8),
        child: LinearProgressIndicator(),
      ),
      null => const SizedBox.shrink(),
    };
    final iSchoolKey = switch ((overview.id, overview.number)) {
      (final id, final number?) when id >= 0 => (
        courseOfferingId: id,
        courseNumber: number,
      ),
      _ => null,
    };
    final showCourseRoster =
        iSchoolKey != null && ref.pref(PrefKey.showCourseRoster);
    final showCourseMaterials =
        iSchoolKey != null && ref.pref(PrefKey.showCourseMaterials);

    return ListView(
      padding: .zero,
      children: [
        SizedBox(
          width: .infinity,
          child: Text(
            title.spaced,
            textAlign: .center,
            style: theme.textTheme.titleLarge,
          ),
        ),
        SizedBox(
          width: .infinity,
          child: Card(
            margin: const .all(8),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: .circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            color: theme.colorScheme.surfaceContainer,
            child: Padding(
              padding: const .all(12),
              child: Column(
                crossAxisAlignment: .start,
                spacing: 6,
                children: [
                  if (overview.number case final number?) Text('課號: $number'),
                  Text('老師: ${teachers.isEmpty ? '-' : teachers}'.spaced),
                  Text('上課地點: ${classrooms.isEmpty ? '-' : classrooms}'.spaced),
                  Text('上課節次: ${periods.isEmpty ? '-' : periods}'.spaced),
                  Text('學分: ${_formatDecimal(overview.credits)}'),
                  Text('時數: ${_formatInteger(overview.hours)}'),
                ],
              ),
            ),
          ),
        ),
        if (showCourseRoster || showCourseMaterials)
          _CourseDetailTabs(
            key: ValueKey((showCourseRoster, showCourseMaterials)),
            iSchoolKey: iSchoolKey,
            syllabus: syllabus,
            showRoster: showCourseRoster,
            showMaterials: showCourseMaterials,
          )
        else
          syllabus,
        SizedBox(height: MediaQuery.viewInsetsOf(context).bottom),
      ],
    );
  }
}

enum _CourseDetailTab { syllabus, roster, materials }

class _CourseDetailTabs extends StatefulWidget {
  const _CourseDetailTabs({
    super.key,
    required this.iSchoolKey,
    required this.syllabus,
    required this.showRoster,
    required this.showMaterials,
  });
  final bool showRoster;
  final bool showMaterials;

  final CourseISchoolKey iSchoolKey;
  final Widget syllabus;

  @override
  State<_CourseDetailTabs> createState() => _CourseDetailTabsState();
}

class _CourseDetailTabsState extends State<_CourseDetailTabs>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;
  late final List<_CourseDetailTab> _tabs;
  var _rosterVisited = false;
  var _materialsVisited = false;

  @override
  void initState() {
    super.initState();
    _tabs = [
      .syllabus,
      if (widget.showRoster) .roster,
      if (widget.showMaterials) .materials,
    ];
    _controller = TabController(length: _tabs.length, vsync: this)
      ..addListener(_handleTabChanged);
  }

  void _handleTabChanged() {
    if (!mounted) return;
    setState(() {
      if (_tabs[_controller.index] == .roster) _rosterVisited = true;
      if (_tabs[_controller.index] == .materials) _materialsVisited = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _controller,
          tabs: [
            for (final tab in _tabs)
              Tab(
                text: switch (tab) {
                  .syllabus => t.courseTable.detail.tabs.syllabus.spaced,
                  .roster => t.courseTable.detail.tabs.roster.spaced,
                  .materials => t.courseTable.detail.tabs.materials.spaced,
                },
              ),
          ],
        ),
        Offstage(
          offstage: _tabs[_controller.index] != .syllabus,
          child: Padding(
            padding: const .only(top: 8),
            child: widget.syllabus,
          ),
        ),
        if (_rosterVisited)
          Offstage(
            offstage: _tabs[_controller.index] != .roster,
            child: Padding(
              padding: const .only(top: 8),
              child: _CourseISchoolPane(iSchoolKey: widget.iSchoolKey),
            ),
          ),
        if (_materialsVisited)
          Offstage(
            offstage: _tabs[_controller.index] != .materials,
            child: Padding(
              padding: const .only(top: 8),
              child: _CourseISchoolPane(
                iSchoolKey: widget.iSchoolKey,
                isMaterials: true,
              ),
            ),
          ),
      ],
    );
  }
}

class _CourseISchoolPane extends ConsumerStatefulWidget {
  const _CourseISchoolPane({
    required this.iSchoolKey,
    this.isMaterials = false,
  });

  final bool isMaterials;

  final CourseISchoolKey iSchoolKey;

  @override
  ConsumerState<_CourseISchoolPane> createState() => _CourseISchoolPaneState();
}

class _CourseISchoolPaneState extends ConsumerState<_CourseISchoolPane> {
  var _showNetworkGuide = false;
  var _probeSnackbarShown = false;
  var _isInitialAttempt = true;

  void _retry() {
    final refresh = ref.read(
      widget.isMaterials
          ? courseMaterialsRefreshProvider(widget.iSchoolKey)
          : courseStudentRosterRefreshProvider(widget.iSchoolKey),
    );
    final availability = ref.read(
      widget.isMaterials
          ? courseMaterialsAvailabilityProvider(widget.iSchoolKey)
          : courseStudentRosterAvailabilityProvider(widget.iSchoolKey),
    );
    if (refresh.isLoading || availability.isLoading) return;
    setState(() {
      _showNetworkGuide = false;
      _probeSnackbarShown = false;
      _isInitialAttempt = false;
    });
    ref
      ..invalidate(iSchoolPlusAvailabilityProvider)
      ..invalidate(
        widget.isMaterials
            ? courseMaterialsProvider(widget.iSchoolKey)
            : courseStudentRosterProvider(widget.iSchoolKey),
      )
      ..invalidate(
        widget.isMaterials
            ? courseMaterialsAvailabilityProvider(widget.iSchoolKey)
            : courseStudentRosterAvailabilityProvider(widget.iSchoolKey),
      )
      ..invalidate(
        widget.isMaterials
            ? courseMaterialsRefreshProvider(widget.iSchoolKey)
            : courseStudentRosterRefreshProvider(widget.iSchoolKey),
      );
  }

  void _openNetworkGuide() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() => _showNetworkGuide = true);
  }

  void _showUpdateSnackbar(String message, String actionLabel) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message.spaced),
          persist: false,
          action: SnackBarAction(
            label: actionLabel,
            onPressed: _openNetworkGuide,
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final refreshProvider = widget.isMaterials
        ? courseMaterialsRefreshProvider(widget.iSchoolKey)
        : courseStudentRosterRefreshProvider(widget.iSchoolKey);
    final availabilityProvider = widget.isMaterials
        ? courseMaterialsAvailabilityProvider(widget.iSchoolKey)
        : courseStudentRosterAvailabilityProvider(widget.iSchoolKey);
    final cacheAsync = widget.isMaterials
        ? ref
              .watch(courseMaterialsProvider(widget.iSchoolKey))
              .whenData(
                (list) => (
                  fetchedAt: list.fetchedAt,
                  isEmpty: list.materials.isEmpty,
                  content: CourseMaterialsList(
                    materials: list.materials,
                    onLearnMore: _openNetworkGuide,
                  ),
                ),
              )
        : ref
              .watch(courseStudentRosterProvider(widget.iSchoolKey))
              .whenData(
                (roster) => (
                  fetchedAt: roster.fetchedAt,
                  isEmpty: roster.students.isEmpty,
                  content:
                      _CourseRosterTable(students: roster.students) as Widget,
                ),
              );
    bool hasCacheNow() => widget.isMaterials
        ? ref
                  .read(courseMaterialsProvider(widget.iSchoolKey))
                  .value
                  ?.fetchedAt !=
              null
        : ref
                  .read(courseStudentRosterProvider(widget.iSchoolKey))
                  .value
                  ?.fetchedAt !=
              null;
    final refreshAsync = ref.watch(refreshProvider);
    final availabilityAsync = ref.watch(availabilityProvider);
    final rosterStrings = Translations.of(context).courseTable.detail.roster;
    final materialStrings = Translations.of(context)
        .courseTable
        .detail
        .materials;
    final strings = widget.isMaterials
        ? (
            empty: materialStrings.empty,
            loadFailed: materialStrings.loadFailed,
            networkSnackbar: materialStrings.networkSnackbar,
            updateFailed: materialStrings.updateFailed,
            updateSuccess: materialStrings.updateSuccess,
            backToList: materialStrings.backToMaterials,
          )
        : (
            empty: rosterStrings.empty,
            loadFailed: rosterStrings.loadFailed,
            networkSnackbar: rosterStrings.networkSnackbar,
            updateFailed: rosterStrings.updateFailed,
            updateSuccess: rosterStrings.updateSuccess,
            backToList: rosterStrings.backToRoster,
          );
    final networkStrings = Translations.of(context).iSchoolPlus.network;

    ref.listen(availabilityProvider, (previous, next) {
      if (!_hasNewError(previous, next)) return;
      final hasCache = hasCacheNow();
      final refresh = ref.read(refreshProvider);
      if (!hasCache ||
          refresh.value?.refreshed == true ||
          _probeSnackbarShown) {
        return;
      }
      _probeSnackbarShown = true;
      _showUpdateSnackbar(
        strings.networkSnackbar,
        networkStrings.learnMore,
      );
    });

    ref.listen(refreshProvider, (previous, next) {
      if (_hasNewError(previous, next)) {
        final hasCache = hasCacheNow();
        if (hasCache) {
          _showUpdateSnackbar(
            strings.updateFailed,
            networkStrings.learnMore,
          );
        }
        return;
      }
      final result = next.value;
      if (result == null || !result.refreshed) return;
      if (_showNetworkGuide && mounted) {
        setState(() => _showNetworkGuide = false);
      }
      if (!result.hadCacheAtStart || !mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(strings.updateSuccess.spaced),
            persist: false,
          ),
        );
    });

    final guideUrl = iSchoolPlusNetworkGuideUri(
      ref.pref(PrefKey.iSchoolPlusNetworkGuideUrl),
    );
    final roster = cacheAsync.value;
    final hasCache = roster?.fetchedAt != null;
    final attemptRunning =
        refreshAsync.isLoading || availabilityAsync.isLoading;
    final retryEnabled = canRetryCourseISchool(
      refreshAsync,
      availabilityAsync,
    );

    if (cacheAsync.isLoading) {
      return _CourseISchoolLoading(
        onLearnMore: _openNetworkGuide,
      );
    }
    if (cacheAsync.hasError) {
      return _DetailState(
        icon: Icons.error_outline,
        message: strings.loadFailed,
        onRetry: _retry,
      );
    }

    final presentation = courseISchoolPresentation(
      hasCache: hasCache,
      showNetworkGuide: _showNetworkGuide,
      allowEarlyNetworkGuide: _isInitialAttempt,
      refresh: refreshAsync.whenData((result) => result.refreshed),
      availability: availabilityAsync,
    );
    switch (presentation) {
      case .guide:
        return ISchoolPlusNetworkGuide(
          guideUrl: guideUrl,
          onBack: hasCache
              ? (
                  label: strings.backToList,
                  onPressed: () => setState(() => _showNetworkGuide = false),
                )
              : null,
          onRetry: _retry,
          retryEnabled: retryEnabled,
          retryInProgress: attemptRunning,
        );
      case .genericFailure:
        return _DetailState(
          icon: Icons.error_outline,
          message: strings.loadFailed,
          onRetry: retryEnabled ? _retry : null,
        );
      case .loading:
        return _CourseISchoolLoading(onLearnMore: _openNetworkGuide);
      case .content:
        if (roster!.isEmpty) {
          return _DetailState(
            icon: widget.isMaterials
                ? Icons.folder_off_outlined
                : Icons.group_off_outlined,
            message: strings.empty,
          );
        }
        return roster.content;
    }
  }
}

bool _hasNewError<T>(AsyncValue<T>? previous, AsyncValue<T> next) {
  return next.hasError &&
      (previous?.hasError != true ||
          !identical(previous?.error, next.error) ||
          !identical(previous?.stackTrace, next.stackTrace));
}

class _CourseISchoolLoading extends StatelessWidget {
  const _CourseISchoolLoading({required this.onLearnMore});

  final VoidCallback onLearnMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = Translations.of(context).iSchoolPlus.network;
    final hintStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return SizedBox(
      height: 160,
      child: Center(
        child: Column(
          mainAxisSize: .min,
          spacing: 16,
          children: [
            const CircularProgressIndicator(),
            Wrap(
              alignment: .center,
              crossAxisAlignment: .center,
              children: [
                Text(strings.loadingNetworkHint.spaced, style: hintStyle),
                Semantics(
                  link: true,
                  child: GestureDetector(
                    behavior: .opaque,
                    onTap: onLearnMore,
                    child: Text(
                      strings.learnMore.spaced,
                      style: hintStyle?.copyWith(
                        color: theme.colorScheme.primary,
                        decoration: .underline,
                        decorationColor: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseRosterTable extends StatelessWidget {
  const _CourseRosterTable({required this.students});

  final List<Student> students;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = Translations.of(context).courseTable.detail.roster;
    return Card(
      margin: const .all(8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: .circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      color: theme.colorScheme.surfaceContainer,
      clipBehavior: .antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: .horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              columns: [
                DataColumn(label: Text(strings.studentId.spaced)),
                DataColumn(label: Text(strings.name.spaced)),
              ],
              rows: [
                for (final student in students)
                  DataRow(
                    cells: [
                      DataCell(Text(student.studentId.spaced)),
                      DataCell(Text((student.name ?? '-').spaced)),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SyllabusTabs extends StatefulWidget {
  const _SyllabusTabs({required this.details});

  final List<TeacherSyllabusDetail> details;

  @override
  State<_SyllabusTabs> createState() => _SyllabusTabsState();
}

class _SyllabusTabsState extends State<_SyllabusTabs>
    with SingleTickerProviderStateMixin {
  late TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _createController();
  }

  @override
  void didUpdateWidget(_SyllabusTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.details.length == widget.details.length) {
      return;
    }

    final previousTeacherCode = oldWidget.details.isEmpty
        ? null
        : oldWidget.details[_controller.index].teacher.code;
    final updatedIndex = previousTeacherCode == null
        ? -1
        : widget.details.indexWhere(
            (detail) => detail.teacher.code == previousTeacherCode,
          );
    _controller.dispose();
    _controller = _createController(
      initialIndex: updatedIndex < 0 ? 0 : updatedIndex,
    );
  }

  TabController _createController({int initialIndex = 0}) {
    final controller = TabController(
      length: widget.details.length,
      initialIndex: initialIndex,
      vsync: this,
    );
    controller.addListener(_handleTabChanged);
    return controller;
  }

  void _handleTabChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.details.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (widget.details.length > 1)
          ChipTabSwitcher(
            controller: _controller,
            padding: const .symmetric(horizontal: 8),
            tabs: [
              for (final detail in widget.details)
                (_normalizedText(
                          localized(
                            detail.teacher.nameZh,
                            detail.teacher.nameEn,
                          ),
                        ) ??
                        t.general.unknown)
                    .spaced,
            ],
          ),
        _SyllabusSections(detail: widget.details[_controller.index]),
      ],
    );
  }
}

class _SyllabusSections extends StatelessWidget {
  const _SyllabusSections({required this.detail});

  final TeacherSyllabusDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const .all(8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: .circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      color: theme.colorScheme.surfaceContainer,
      child: SelectionArea(
        child: Padding(
          padding: const .all(12),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              for (final (index, section)
                  in detail.syllabus.sections.indexed) ...[
                if (index > 0) const Divider(height: 24),
                Text(
                  section.title.spaced,
                  style: theme.textTheme.titleMedium,
                ),
                if (_normalizedText(section.content) case final content?)
                  Padding(
                    padding: const .only(top: 6),
                    child: Text(content.spaced),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailState extends StatelessWidget {
  const _DetailState({
    required this.icon,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 160,
      child: Center(
        child: Column(
          mainAxisSize: .min,
          spacing: 8,
          children: [
            Icon(icon, color: colorScheme.onSurfaceVariant),
            Text(
              message.spaced,
              textAlign: .center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            if (onRetry case final onRetry?)
              TextButton(
                onPressed: onRetry,
                child: Text(t.general.retry.spaced),
              ),
          ],
        ),
      ),
    );
  }
}

String? _normalizedText(String? value) {
  return switch (value?.trim()) {
    final value? when value.isNotEmpty => value,
    _ => null,
  };
}

String _formatDecimal(double? value) {
  return switch (value) {
    final value? when value == value.roundToDouble() =>
      value.toInt().toString(),
    final value? => value.toString(),
    null => '-',
  };
}

String _formatInteger(int? value) => value?.toString() ?? '-';

String _dayOfWeekLabel(DayOfWeek day) => switch (day) {
  .sunday => '星期日',
  .monday => '星期一',
  .tuesday => '星期二',
  .wednesday => '星期三',
  .thursday => '星期四',
  .friday => '星期五',
  .saturday => '星期六',
};
