import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:tattoo/components/app_skeleton.dart';
import 'package:tattoo/components/widget_preview_frame.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/course_repository.dart';
import 'package:auto_size_text/auto_size_text.dart';

/// A single course block shown in the course table grid.
///
/// The cell renders the course title and, when available, the classroom name,
/// using a tinted background and bordered style derived from [cellColor].
/// Tapping the cell triggers [onTap].
///
/// The text scale is locked to avoid unpredictable row height changes from
/// system accessibility scaling, so the grid keeps stable visual alignment.
///
/// Layout constraint:
/// This widget should be laid out with a height of at least `52` logical
/// pixels. With smaller heights, the title/classroom text may overflow.
class CourseTableCell extends StatelessWidget {
  /// Course data rendered by this table cell.
  final CourseTableCellData courseTableCellData;

  /// Base accent color used to derive the background and border colors.
  final Color cellColor;

  /// Called when the user taps this cell.
  final VoidCallback? onTap;

  /// Creates a course table cell.
  const CourseTableCell({
    required this.courseTableCellData,
    required this.cellColor,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final containerColor = HSLColor.fromColor(
      cellColor,
    ).withLightness(0.9).withSaturation(0.4).toColor();
    final borderColor = HSLColor.fromColor(
      cellColor,
    ).withLightness(0.3).withSaturation(0.6).toColor();
    final borderStyle = Border.all(
      color: borderColor,
      width: 1,
    );
    final borderRadius = BorderRadius.circular(8);
    final theme = Theme.of(context);
    final courseTitle = courseTableCellData.courseName.isNotEmpty
        ? courseTableCellData.courseName
        : courseTableCellData.number ?? '';
    final classroomName = courseTableCellData.classroomName;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: containerColor,
            borderRadius: borderRadius,
            border: borderStyle,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final titleMaxLines = constraints.maxHeight > 100 ? 3 : 2;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 2,
                  ),
                  child: Column(
                    mainAxisAlignment: .center,
                    children: [
                      AutoSizeText(
                        courseTitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                          fontWeight: .w700,
                        ),
                        maxLines: titleMaxLines,
                        minFontSize: 8,
                        overflow: .ellipsis,
                        textAlign: .center,
                      ),
                      if (classroomName case final classroomName?
                          when classroomName.isNotEmpty)
                        AutoSizeText(
                          classroomName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 8,
                            fontWeight: .w400,
                          ),
                          maxLines: 1,
                          minFontSize: 6,
                          overflow: .ellipsis,
                          textAlign: .center,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// A card row used by the unscheduled course section under the grid.
///
/// It displays the course name/number and credits/hours, with a colored
/// leading indicator that matches the corresponding scheduled course color.
class CourseTableUnscheduledCell extends StatelessWidget {
  /// Creates an unscheduled-course list row.
  const CourseTableUnscheduledCell({
    required this.courseTableCellData,
    required this.indicatorColor,
    this.onTap,
    super.key,
  });

  /// Course data rendered by this list row.
  final CourseTableCellData courseTableCellData;

  /// Color of the leading indicator stripe.
  final Color indicatorColor;

  /// Called when the user taps this row.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: .zero,
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: .circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: .circular(12),
        onTap: onTap,
        child: Padding(
          padding: const .symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  borderRadius: .circular(999),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ListTile(
                  contentPadding: .zero,
                  dense: true,
                  visualDensity: .compact,
                  title: Text(
                    courseTableCellData.courseName.isNotEmpty
                        ? courseTableCellData.courseName
                        : courseTableCellData.number ?? t.general.unknown,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: .w600,
                    ),
                    maxLines: 1,
                    overflow: .ellipsis,
                  ),
                  subtitle: switch (courseTableCellData.number) {
                    final number? => Text(
                      number,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: .ellipsis,
                    ),
                    null => null,
                  },
                ),
              ),
              Text(
                '${courseTableCellData.credits} / ${courseTableCellData.hours}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: .w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton placeholder for [CourseTableCell] while loading.
///
/// This keeps the same rounded border silhouette as the real cell to reduce
/// layout shift between loading and loaded states.
class CourseTableCellSkeleton extends StatelessWidget {
  /// Creates a loading placeholder for a course table cell.
  const CourseTableCellSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = colorScheme.surfaceContainerHighest;
    final borderColor = colorScheme.outlineVariant;

    return Container(
      decoration: BoxDecoration(
        borderRadius: .circular(8),
        border: .all(color: borderColor, width: 1),
      ),
      clipBehavior: .antiAlias,
      child: AppSkeleton(
        child: Skeleton.leaf(
          child: Container(color: baseColor),
        ),
      ),
    );
  }
}

@Preview(
  name: 'Named Course',
  group: 'Course Table',
  size: Size(220, 150),
)
Widget courseTableCellNamedPreview() {
  return WidgetPreviewFrame(
    child: Row(
      spacing: 4,
      mainAxisAlignment: .center,
      crossAxisAlignment: .start,
      children: [
        SizedBox(
          width: 50,
          height: 52,
          child: CourseTableCell(
            courseTableCellData: _previewNamedCourseTableCell,
            cellColor: Colors.blue,
          ),
        ),
        SizedBox(
          width: 50,
          height: 104,
          child: CourseTableCell(
            courseTableCellData: _previewNamedCourseTableCell,
            cellColor: Colors.red,
          ),
        ),
      ],
    ),
  );
}

@Preview(
  name: 'CourseTableCellSkeleton',
  group: 'Course Table',
  size: Size(220, 150),
)
Widget courseTableCellSkeletonPreview() {
  return WidgetPreviewFrame(
    child: Row(
      spacing: 4,
      mainAxisAlignment: .center,
      crossAxisAlignment: .start,
      children: [
        const SizedBox(
          width: 50,
          height: 52,
          child: CourseTableCellSkeleton(),
        ),
        const SizedBox(
          width: 50,
          height: 104,
          child: CourseTableCellSkeleton(),
        ),
      ],
    ),
  );
}

const CourseTableCellData _previewNamedCourseTableCell = (
  id: 1,
  number: 'CSIE3001',
  span: 2,
  crossesNoon: false,
  courseName: '微處理機及自動控制應用實務',
  classroomName: '六教305',
  credits: 3.0,
  hours: 3,
);
