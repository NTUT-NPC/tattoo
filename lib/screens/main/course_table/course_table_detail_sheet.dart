import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/components/chip_tab_switcher.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/repositories/course_repository.dart';
import 'package:tattoo/screens/main/course_table/course_table_providers.dart';
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
    builder: (context) => CourseTableDetailSheet(number: number),
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
    // TODO: replace with course name when available
    final title =
        _normalizedText(localized(overview.nameZh, overview.nameEn)) ??
        _normalizedText(overview.number) ??
        t.general.unknown;
    final teachers = detail.teachers
        .map((teacher) => _normalizedText(teacher.nameZh))
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
        if (syllabusAsync case final syllabusAsync?)
          switch (syllabusAsync) {
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
          },
        SizedBox(height: MediaQuery.viewInsetsOf(context).bottom),
      ],
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
  const _DetailState({required this.icon, required this.message});

  final IconData icon;
  final String message;

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
