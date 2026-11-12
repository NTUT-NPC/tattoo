import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tattoo/components/tap_to_copy.dart';
import 'package:tattoo/components/widget_preview_frame.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/repositories/course_repository.dart';
import 'package:tattoo/utils/auto_spacing.dart';
import 'package:tattoo/utils/course_schedule.dart';
import 'package:tattoo/utils/localized.dart';

class CourseDetailInfoCard extends StatelessWidget {
  const CourseDetailInfoCard({
    super.key,
    required this.detail,
  });

  final CourseOfferingDetail detail;

  @override
  Widget build(BuildContext context) {
    final overview = detail.overview;
    final teachers = detail.teachers
        .map(
          (teacher) => _normalizedText(
            localized(teacher.nameZh.spaced, teacher.nameEn?.spaced),
          ),
        )
        .nonNulls
        .map((name) => name.split('').join('\u{2060}'))
        .join('、\u{200B}'); // Prevent line breaks within teacher names.
    final classrooms = detail.schedule
        .map(
          (slot) => _normalizedText(
            localized(slot.classroomNameZh, slot.classroomNameEn),
          ),
        )
        .nonNulls
        .toSet()
        .toList();
    final periodsByDay = <DayOfWeek, List<Period>>{};
    for (final slot in detail.schedule) {
      (periodsByDay[slot.day] ??= []).add(slot.period);
    }
    final periods = periodsByDay.entries
        .map(
          (entry) =>
              '${_dayOfWeekLabel(entry.key)} ${formatPeriodTimeRanges(entry.value)}',
        )
        .join('\n');
    final credits = _formatDecimal(overview.credits);
    final hours = overview.hours?.toString() ?? '-';
    final phase = overview.phase;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: .fromLTRB(0, 4, 0, 8),
      child: Card(
        margin: const .all(8),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: .circular(12),
          side: BorderSide(color: colors.outlineVariant),
        ),
        color: colors.surfaceContainer,
        child: Padding(
          padding: const .all(16),
          child: Column(
            crossAxisAlignment: .stretch,
            spacing: 8,
            children: [
              _InfoField(
                label: t.courseDetail.infoCard.teacher,
                value: teachers,
              ),
              _InfoField(
                label: t.courseDetail.infoCard.period,
                value: periods,
              ),
              if (classrooms.isEmpty)
                _InfoField(
                  label: t.courseDetail.infoCard.classroom,
                  value: '-',
                )
              else
                for (final classroom in classrooms)
                  _InfoField(
                    label: t.courseDetail.infoCard.classroom,
                    // icon: Icons.room_outlined,
                    value: classroom,
                    action: () {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text(
                              t.courseDetail.infoCard.findClassroomComingSoon
                                  .spaced,
                            ),
                            persist: false,
                          ),
                        );
                    },
                    actionIcon: Icons.map_outlined,
                    actionTooltip: t.courseDetail.infoCard.findClassroomOnMap
                        .spaced,
                  ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compactFields = [
                    _InfoField(
                      label: t.courseDetail.infoCard.credits,
                      icon: Icons.school_outlined,
                      value: credits,
                      compact: true,
                      tapToCopy: false,
                    ),
                    _InfoField(
                      label: t.courseDetail.infoCard.hours,
                      icon: Icons.schedule_outlined,
                      value: hours,
                      compact: true,
                      tapToCopy: false,
                    ),
                    _InfoField(
                      label: t.courseDetail.infoCard.phase,
                      icon: Icons.flag_outlined,
                      value: phase.toString(),
                      compact: true,
                      tapToCopy: false,
                    ),
                  ];

                  if (constraints.maxWidth < 240) {
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: compactFields,
                    );
                  }

                  return Row(
                    children: [
                      for (final field in compactFields) Expanded(child: field),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String? _normalizedText(String? value) => switch (value?.trim()) {
  final value? when value.isNotEmpty => value,
  _ => null,
};

String _formatDecimal(double? value) => switch (value) {
  final value? when value == value.roundToDouble() => value.toInt().toString(),
  final value? => value.toString(),
  null => '-',
};

String _dayOfWeekLabel(DayOfWeek day) => switch (day) {
  .sunday => '星期日',
  .monday => '星期一',
  .tuesday => '星期二',
  .wednesday => '星期三',
  .thursday => '星期四',
  .friday => '星期五',
  .saturday => '星期六',
};

class _InfoField extends StatelessWidget {
  const _InfoField({
    required this.label,
    required this.value,
    this.icon,
    this.actionIcon,
    this.action,
    this.actionTooltip,
    this.compact = false,
    this.tapToCopy = true,
  });

  final String label;
  final String value;
  final IconData? icon;
  final IconData? actionIcon;
  final VoidCallback? action;
  final String? actionTooltip;
  final bool compact;
  final bool tapToCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconWidget = switch (icon) {
      final icon? => Icon(
        icon,
        size: 18,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      null => null,
    };
    final labelWidget = Text(
      label.spaced,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
    final valueText = Text(
      (value.isEmpty ? '-' : value).spaced,
      style: theme.textTheme.bodyMedium,
    );
    final valueWidget = Row(
      mainAxisSize: .min,
      crossAxisAlignment: .center,
      children: [
        Flexible(
          child: tapToCopy
              ? TapToCopy(
                  copyText: value.isEmpty ? '-' : value,
                  child: valueText,
                )
              : valueText,
        ),
      ],
    );
    final actionWidget = switch ((actionIcon, action)) {
      (final icon?, final action?) => IconButton(
        onPressed: action,
        icon: Icon(icon, size: 16),
        tooltip: actionTooltip,
        style: IconButton.styleFrom(
          tapTargetSize: .shrinkWrap,
          minimumSize: const Size.square(32),
          maximumSize: const Size.square(32),
          visualDensity: VisualDensity.standard,
          padding: const .all(8),
          shape: const CircleBorder(),
          foregroundColor: theme.colorScheme.primary,
          backgroundColor: theme.colorScheme.surfaceContainerLowest,
        ),
      ),
      _ => null,
    };

    if (compact) {
      return Row(
        mainAxisSize: .min,
        crossAxisAlignment: .center,
        spacing: 8,
        children: [
          ?iconWidget,
          labelWidget,
          Flexible(child: valueWidget),
          ?actionWidget,
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 240;
        final labelWidth = (constraints.maxWidth * .25).clamp(72.0, 112.0);
        final trailing = Row(
          crossAxisAlignment: .center,
          children: [
            Expanded(child: valueWidget),
            ?actionWidget,
          ],
        );
        if (stacked) {
          return Column(
            crossAxisAlignment: .stretch,
            children: [
              Row(
                spacing: 8,
                children: [
                  ?iconWidget,
                  Expanded(child: labelWidget),
                ],
              ),
              Padding(
                padding: EdgeInsetsDirectional.only(
                  start: iconWidget == null ? 0 : 26,
                ),
                child: trailing,
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: .center,
          spacing: 8,
          children: [
            ?iconWidget,
            SizedBox(width: labelWidth, child: labelWidget),
            Expanded(child: trailing),
          ],
        );
      },
    );
  }
}

@Preview(
  name: 'Course detail info',
  group: 'Course Table',
  size: Size(360, 420),
)
Widget courseDetailInfoCardPreview() => WidgetPreviewFrame(
  child: CourseDetailInfoCard(
    detail: (
      overview: CourseOfferingOverview(
        id: 1,
        semester: 1,
        credits: 3,
        hours: 3,
      ),
      teachers: [
        (code: '1', nameZh: '王小明', nameEn: null),
        (code: '2', nameZh: '陳小華', nameEn: null),
      ],
      schedule: [],
      classes: [],
    ),
  ),
);
