import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tattoo/components/widget_preview_frame.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/utils/auto_spacing.dart';

class CourseDetailInfoCard extends StatelessWidget {
  const CourseDetailInfoCard({
    super.key,
    required this.teachers,
    required this.periods,
    required this.credits,
    required this.hours,
    required this.courseType,
    required this.classrooms,
  });

  final String teachers;
  final String periods;
  final String credits;
  final String hours;
  final String courseType;
  final List<String> classrooms;

  @override
  Widget build(BuildContext context) {
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
                              t.courseDetail.infoCard.findClassroomComingSoon,
                            ),
                            persist: false,
                          ),
                        );
                    },
                    actionIcon: Icons.map_outlined,
                    actionTooltip: t.courseDetail.infoCard.findClassroomOnMap,
                  ),
              Wrap(
                alignment: .spaceBetween,
                spacing: 12,
                runSpacing: 12,
                children: [
                  _InfoField(
                    label: t.courseDetail.infoCard.credits,
                    icon: Icons.school_outlined,
                    value: credits,
                    compact: true,
                  ),
                  _InfoField(
                    label: t.courseDetail.infoCard.hours,
                    icon: Icons.schedule_outlined,
                    value: hours,
                    compact: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  const _InfoField({
    required this.label,
    required this.value,
    this.icon,
    this.actionIcon,
    this.action,
    this.actionTooltip,
    this.compact = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final IconData? actionIcon;
  final VoidCallback? action;
  final String? actionTooltip;
  final bool compact;

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
      label,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
    final valueWidget = Row(
      mainAxisSize: .min,
      crossAxisAlignment: .center,
      children: [
        Flexible(
          child: Text(
            (value.isEmpty ? '-' : value).spaced,
            style: theme.textTheme.bodyMedium,
          ),
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
    teachers: '王小明、陳小華',
    periods: '星期一 10:10 - 12:00\n星期三 13:10 - 14:00',
    credits: '3',
    hours: '3',
    courseType: '●',
    classrooms: const ['六教305', '共同科館201'],
  ),
);
