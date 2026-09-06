import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/components/chip_tab_switcher.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/repositories/course_repository.dart';
import 'package:tattoo/repositories/preferences_repository.dart';
import 'package:tattoo/screens/main/course_table/course_table_providers.dart';
import 'package:tattoo/screens/main/profile/preference_providers.dart';
import 'package:tattoo/shells/centered_max_width_frame.dart';
import 'package:tattoo/utils/auto_spacing.dart';
import 'package:tattoo/utils/launch_url.dart';
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
    final rosterKey = switch ((overview.id, overview.number)) {
      (final id, final number?) when id >= 0 => (
        courseOfferingId: id,
        courseNumber: number,
      ),
      _ => null,
    };
    final showCourseRoster =
        rosterKey != null && ref.pref(PrefKey.showCourseRoster);

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
        if (showCourseRoster)
          _CourseDetailTabs(rosterKey: rosterKey, syllabus: syllabus)
        else
          syllabus,
        SizedBox(height: MediaQuery.viewInsetsOf(context).bottom),
      ],
    );
  }
}

class _CourseDetailTabs extends StatefulWidget {
  const _CourseDetailTabs({required this.rosterKey, required this.syllabus});

  final CourseRosterKey rosterKey;
  final Widget syllabus;

  @override
  State<_CourseDetailTabs> createState() => _CourseDetailTabsState();
}

class _CourseDetailTabsState extends State<_CourseDetailTabs>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;
  var _rosterVisited = false;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 2, initialIndex: 1, vsync: this)
      ..addListener(_handleTabChanged);
  }

  void _handleTabChanged() {
    if (!mounted) return;
    setState(() {
      if (_controller.index == 0) _rosterVisited = true;
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
            Tab(text: t.courseTable.detail.tabs.roster.spaced),
            Tab(text: t.courseTable.detail.tabs.syllabus.spaced),
          ],
        ),
        if (_rosterVisited)
          Offstage(
            offstage: _controller.index != 0,
            child: _CourseRosterPane(rosterKey: widget.rosterKey),
          ),
        Offstage(
          offstage: _controller.index != 1,
          child: widget.syllabus,
        ),
      ],
    );
  }
}

class _CourseRosterPane extends ConsumerStatefulWidget {
  const _CourseRosterPane({required this.rosterKey});

  final CourseRosterKey rosterKey;

  @override
  ConsumerState<_CourseRosterPane> createState() => _CourseRosterPaneState();
}

class _CourseRosterPaneState extends ConsumerState<_CourseRosterPane> {
  var _showNetworkGuide = false;

  @override
  Widget build(BuildContext context) {
    final cacheProvider = courseStudentRosterProvider(widget.rosterKey);
    final refreshProvider = courseStudentRosterRefreshProvider(
      widget.rosterKey,
    );
    final cacheAsync = ref.watch(cacheProvider);
    final refreshAsync = ref.watch(refreshProvider);
    final strings = Translations.of(context).courseTable.detail.roster;

    ref.listen(refreshProvider, (previous, next) {
      if (previous?.hasError == true || !next.hasError) return;
      final cachedStudents =
          ref.read(cacheProvider).value?.students ?? const [];
      if (cachedStudents.isEmpty) return;

      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              (next.error is DioException
                      ? strings.networkSnackbar
                      : strings.loadFailed)
                  .spaced,
            ),
            persist: false,
            action: next.error is DioException
                ? SnackBarAction(
                    label: strings.learnMore,
                    onPressed: () {
                      if (mounted) setState(() => _showNetworkGuide = true);
                    },
                  )
                : null,
          ),
        );
    });

    final guideUrl = courseRosterGuideUri(
      ref.pref(PrefKey.courseRosterGuideUrl),
    );
    if (_showNetworkGuide) {
      return _CourseRosterNetworkGuide(
        guideUrl: guideUrl,
        onBack: () => setState(() => _showNetworkGuide = false),
      );
    }

    final roster = cacheAsync.value;
    final refreshError = refreshAsync.error;
    if (cacheAsync.isLoading ||
        (roster?.fetchedAt == null && refreshAsync.isLoading)) {
      return const _DetailState(
        icon: Icons.groups_outlined,
        message: '',
        loading: true,
      );
    }
    if (cacheAsync.hasError) {
      return _DetailState(
        icon: Icons.error_outline,
        message: strings.loadFailed,
      );
    }
    if ((roster?.students.isEmpty ?? true) && refreshError is DioException) {
      return _CourseRosterNetworkGuide(guideUrl: guideUrl);
    }
    if ((roster?.students.isEmpty ?? true) && refreshError != null) {
      return _DetailState(
        icon: Icons.error_outline,
        message: strings.loadFailed,
      );
    }
    if (roster == null || roster.students.isEmpty) {
      return _DetailState(
        icon: Icons.group_off_outlined,
        message: strings.empty,
      );
    }
    return _CourseRosterTable(students: roster.students);
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

class _CourseRosterNetworkGuide extends StatelessWidget {
  const _CourseRosterNetworkGuide({required this.guideUrl, this.onBack});

  final Uri guideUrl;
  final VoidCallback? onBack;

  Future<void> _openGuide(BuildContext context) async {
    try {
      await launchUrl(guideUrl);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              t.courseTable.detail.roster.openGuideFailed.spaced,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = Translations.of(context).courseTable.detail.roster;
    return Padding(
      padding: const .fromLTRB(16, 32, 16, 8),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        children: [
          Icon(
            Icons.vpn_lock_outlined,
            size: 64,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            strings.networkTitle.spaced,
            style: theme.textTheme.headlineSmall,
            textAlign: .center,
          ),
          const SizedBox(height: 12),
          Text(
            strings.networkDescription.spaced,
            style: theme.textTheme.bodyLarge,
            textAlign: .center,
          ),
          if (onBack case final onBack?) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onBack,
              child: Text(strings.backToRoster.spaced),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _openGuide(context),
            icon: const Icon(Icons.open_in_new),
            label: Text(strings.openGuide.spaced),
          ),
        ],
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
    this.loading = false,
  });

  final IconData icon;
  final String message;
  final bool loading;

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
            if (loading)
              const CircularProgressIndicator()
            else ...[
              Icon(icon, color: colorScheme.onSurfaceVariant),
              Text(
                message.spaced,
                textAlign: .center,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Returns a safe course-roster guide URL, falling back from invalid config.
Uri courseRosterGuideUri(String configuredUrl) {
  final configured = Uri.tryParse(configuredUrl);
  if (configured != null &&
      (configured.scheme == 'http' || configured.scheme == 'https') &&
      configured.host.isNotEmpty) {
    return configured;
  }
  return Uri.parse(defaultCourseRosterGuideUrl);
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
