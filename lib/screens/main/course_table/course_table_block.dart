import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:tattoo/components/app_skeleton.dart';
import 'package:tattoo/components/widget_preview_frame.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/repositories/course_repository.dart';
import 'package:auto_size_text/auto_size_text.dart';

class CourseTableBlock extends StatelessWidget {
  final CourseTableBlockObject courseBlock;
  final Color blockColor;

  const CourseTableBlock({
    required this.courseBlock,
    required this.blockColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final containerColor = HSLColor.fromColor(
      blockColor,
    ).withLightness(0.95).withSaturation(0.3).toColor();
    final borderColor = HSLColor.fromColor(
      blockColor,
    ).withLightness(0.3).withSaturation(0.8).toColor();
    final borderStyle = Border.all(
      color: borderColor,
      width: 1,
    );
    final theme = Theme.of(context);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Container(
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(8),
          border: borderStyle,
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: SizedBox(
          height: 64,
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AutoSizeText(
                courseBlock.courseNameZh ?? courseBlock.courseNumber,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                minFontSize: 10,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              AutoSizeText(
                courseBlock.classroomNameZh,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 8,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                minFontSize: 6,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CourseTableBlockSkeleton extends StatelessWidget {
  const CourseTableBlockSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = colorScheme.surfaceContainerHighest;
    final borderColor = colorScheme.outlineVariant;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
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
Widget courseTableBlockNamedPreview() {
  return WidgetPreviewFrame(
    child: Row(
      spacing: 4,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 50,
          height: 68,
          child: CourseTableBlock(
            courseBlock: _previewNamedCourseTableBlock,
            blockColor: Colors.blue,
          ),
        ),
        SizedBox(
          width: 50,
          height: 136,
          child: CourseTableBlock(
            courseBlock: _previewNamedCourseTableBlock,
            blockColor: Colors.red,
          ),
        ),
      ],
    ),
  );
}

@Preview(
  name: 'CourseTableBlockSkeleton',
  group: 'Course Table',
  size: Size(220, 150),
)
Widget courseTableBlockSkeletonPreview() {
  return WidgetPreviewFrame(
    child: Row(
      spacing: 4,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          width: 50,
          height: 68,
          child: CourseTableBlockSkeleton(),
        ),
        const SizedBox(
          width: 50,
          height: 136,
          child: CourseTableBlockSkeleton(),
        ),
      ],
    ),
  );
}

final CourseTableBlockObject _previewNamedCourseTableBlock = (
  courseNumber: 'CSIE3001',
  courseNameZh: '微處理機及自動控制應用實務',
  classroomNameZh: '六教305',
  dayOfWeek: DayOfWeek.monday,
  startSection: Period.third,
  endSection: Period.fourth,
);
