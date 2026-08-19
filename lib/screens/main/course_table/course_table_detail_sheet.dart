import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/i18n/strings.g.dart';
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
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
    constraints: BoxConstraints(
      minWidth: MediaQuery.sizeOf(context).width,
      maxWidth: MediaQuery.sizeOf(context).width,
    ),
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
          AsyncData(value: final detail?) => _CourseDetailContent(
            detail: detail,
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

class _CourseDetailContent extends StatelessWidget {
  const _CourseDetailContent({required this.detail});

  final CourseOfferingDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overview = detail.overview;
    final title =
        _normalizedText(localized(overview.nameZh, overview.nameEn)) ??
        _normalizedText(overview.number) ??
        t.general.unknown;
    final classrooms = detail.schedule
        .map(
          (slot) => _normalizedText(
            localized(slot.classroomNameZh, slot.classroomNameEn),
          ),
        )
        .nonNulls
        .toSet()
        .join('、');
    final maxSpan = _maxConsecutiveSpan(detail);

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      spacing: 16,
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
                  Text('教室: ${classrooms.isEmpty ? '-' : classrooms}'.spaced),
                  Text('學分: ${_formatDecimal(overview.credits)}'),
                  Text('時數: ${_formatInteger(overview.hours)}'),
                  Text('連續節數: ${maxSpan == 0 ? '-' : maxSpan}'),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: MediaQuery.viewInsetsOf(context).bottom),
      ],
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

int _maxConsecutiveSpan(CourseOfferingDetail detail) {
  final slots = [...detail.schedule]
    ..sort((a, b) {
      final dayComparison = a.day.index.compareTo(b.day.index);
      return dayComparison != 0
          ? dayComparison
          : a.period.index.compareTo(b.period.index);
    });
  var maxSpan = 0;
  var currentSpan = 0;

  for (var index = 0; index < slots.length; index++) {
    final current = slots[index];
    final continuesPrevious =
        index > 0 &&
        slots[index - 1].day == current.day &&
        slots[index - 1].period.index + 1 == current.period.index;
    currentSpan = continuesPrevious ? currentSpan + 1 : 1;
    if (currentSpan > maxSpan) maxSpan = currentSpan;
  }

  return maxSpan;
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
