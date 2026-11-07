import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tattoo/components/widget_preview_frame.dart';
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
                label: '老師',
                icon: Icons.person_outline,
                value: teachers,
              ),
              _InfoField(
                label: '上課時間',
                icon: Icons.calendar_today_outlined,
                value: periods,
              ),
              Wrap(
                alignment: .spaceBetween,
                spacing: 12,
                runSpacing: 12,
                children: [
                  _InfoField(
                    label: '學分',
                    icon: Icons.school_outlined,
                    value: credits,
                  ),
                  _InfoField(
                    label: '時數',
                    icon: Icons.schedule_outlined,
                    value: hours,
                  ),
                  _InfoField(
                    label: '類型',
                    icon: Icons.category_outlined,
                    value: courseType,
                    description:
                        '○ 系共同必修\n'
                        '△ 校共同必修\n'
                        '☆ 共同選修\n'
                        '● 系專業必修\n'
                        '▲ 校專業必修\n'
                        '★ 專業選修',
                  ),
                ],
              ),
              if (classrooms.isEmpty)
                const _InfoField(
                  label: '教室',
                  icon: Icons.room_outlined,
                  value: '-',
                )
              else
                for (final classroom in classrooms)
                  _InfoField(
                    label: '教室',
                    icon: Icons.room_outlined,
                    value: classroom,
                    action: () {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text('尋找教室功能即將推出'),
                            persist: false,
                          ),
                        );
                    },
                    actionIcon: Icons.map_outlined,
                    actionTooltip: '在地圖上尋找教室',
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
    this.description,
  });

  final String label;
  final String value;
  final IconData? icon;
  final IconData? actionIcon;
  final VoidCallback? action;
  final String? actionTooltip;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: .min,
      crossAxisAlignment: .center,
      spacing: 8,
      children: [
        if (icon case final icon?)
          Icon(
            icon,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),

        Flexible(
          child: Row(
            mainAxisSize: .min,
            crossAxisAlignment: .center,
            children: [
              Flexible(
                child: Text(
                  (value.isEmpty ? '-' : value).spaced,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              if (description case final description?
                  when description.trim().isNotEmpty)
                Tooltip(
                  message: description.spaced,
                  textAlign: TextAlign.left,
                  triggerMode: TooltipTriggerMode.tap,
                  showDuration: const Duration(seconds: 5),
                  child: Semantics(
                    button: true,
                    child: Icon(
                      Icons.help_outline,
                      size: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),

        if (actionIcon case final icon? when action != null)
          IconButton(
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
      ],
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
