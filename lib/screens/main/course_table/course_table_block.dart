import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:tattoo/repositories/course_repository.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'course_table_providers.dart';

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
              '${courseInfo.classroomNamesZh[0]} +${courseInfo.classroomNamesZh.length > 1 ? '${courseInfo.classroomNamesZh.length - 1}' : ''}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
              minFontSize: 8,
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
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Theme(
      data: ThemeData(useMaterial3: true),
      child: Material(
        child: SizedBox(
          width: 70,
          height: 70,
          child: CourseTableBlock(
            courseBlock: mockCourseTableBlock,
            blockColor: Colors.blue,
          ),
        ),
      ),
    ),
  );
}
