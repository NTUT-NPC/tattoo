import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/repositories/course_repository.dart';
import 'package:auto_size_text/auto_size_text.dart';

/// 課程時間區塊 Widget，呈現單一課程在課表中的視覺化表現。
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
    final courseInfo = courseBlock.courseInfo;

    final containerColor = HSLColor.fromColor(
      blockColor,
    ).withLightness(0.95).withSaturation(1).toColor();
    final borderColor = HSLColor.fromColor(
      blockColor,
    ).withLightness(0.4).withSaturation(0.8).toColor();
    final borderStyle = Border.all(
      color: borderColor,
      width: 1.5,
    );
    final theme = Theme.of(context);

    return Container(
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
              courseInfo.courseNameZh ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              minFontSize: 10,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            AutoSizeText(
              courseInfo.classroomNamesZh.join(', '),
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 8,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 2,
              minFontSize: 6,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

@Preview(name: 'CourseTableBlock', size: Size(70, 140))
Widget previewCourseTableBlock() {
  final CourseTableInfoObject previewCourseTableInfo = (
    number: 'CSIE3001',
    courseNameZh: '微處理機及自動控制應用實務',
    teacherNamesZh: ['王小明', '李小華'],
    credits: 3,
    hours: 3,
    classroomNamesZh: ['六教 305'],
    schedule: [
      (dayOfWeek: DayOfWeek.monday, period: Period.third),
      (dayOfWeek: DayOfWeek.monday, period: Period.fourth),
    ],
    classNamesZh: ['資工三甲'],
  );

  final CourseTableBlockObject previewCourseTableBlock = (
    courseInfo: previewCourseTableInfo,
    dayOfWeek: DayOfWeek.monday,
    startSection: Period.third,
    endSection: Period.fourth,
  );

  return Directionality(
    textDirection: TextDirection.ltr,
    child: Theme(
      data: ThemeData(useMaterial3: true),
      child: Material(
        child: SizedBox(
          width: 70,
          height: 70,
          child: CourseTableBlock(
            courseBlock: previewCourseTableBlock,
            blockColor: Colors.blue,
          ),
        ),
      ),
    ),
  );
}
