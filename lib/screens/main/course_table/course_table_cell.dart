import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:tattoo/components/app_skeleton.dart';
import 'package:tattoo/components/widget_preview_frame.dart';
import 'package:tattoo/repositories/course_repository.dart';
import 'package:auto_size_text/auto_size_text.dart';

class CourseTableCell extends StatelessWidget {
  final CourseTableCellData courseTableCellData;
  final Color cellColor;
  final VoidCallback? onTap;

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
        : courseTableCellData.number;
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: Column(
                mainAxisAlignment: .center,
                children: [
                  AutoSizeText(
                    courseTitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      fontWeight: .w700,
                    ),
                    maxLines: 2,
                    minFontSize: 12,
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
                      minFontSize: 8,
                      overflow: .ellipsis,
                      textAlign: .center,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CourseTableCellSkeleton extends StatelessWidget {
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
      child: Skeletonizer(
        effect: PulseEffect(
          from: baseColor,
          to: borderColor,
          duration: const Duration(milliseconds: 800),
        ),
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
