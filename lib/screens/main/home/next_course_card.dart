import 'package:flutter/material.dart';
import 'package:tattoo/utils/auto_spacing.dart';

const _nextCourseCardShadow = BoxShadow(
  color: Color(0x66000000),
  blurRadius: 16,
  offset: Offset(0, 4),
);

class NextCourse {
  const NextCourse({
    required this.title,
    required this.courseNumber,
    required this.teacher,
    required this.classroom,
    required this.time,
  });

  final String title;
  final String courseNumber;
  final String teacher;
  final String classroom;
  final String time;
}

class NextCourseCard extends StatelessWidget {
  const NextCourseCard({
    super.key,
    required this.course,
    this.onTap,
  });

  final NextCourse course;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final courseTitleTextStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: .w700,
      color: theme.colorScheme.onSurface,
      height: 1.2,
    );
    final courseTitleLineHeight =
        (courseTitleTextStyle?.fontSize ?? 22) *
        (courseTitleTextStyle?.height ?? 1.2);
    final infoTextStyle = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      height: 1.4,
    );

    const borderRadius = BorderRadius.all(Radius.circular(20));

    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: borderRadius,
          boxShadow: const [_nextCourseCardShadow],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: borderRadius,
          clipBehavior: .antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: .stretch,
                mainAxisSize: .min,
                spacing: 32,
                children: [
                  Text(
                    '今日 · 下一堂課'.spaced,
                    // TODO: 今日、明日、週X；進行中、下一堂課、無
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: .w600,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: .start,
                    spacing: 8,
                    children: [
                      SizedBox(
                        height: courseTitleLineHeight * 2,
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            course.title.spaced,
                            maxLines: 2,
                            overflow: .ellipsis,
                            style: courseTitleTextStyle,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: .start,
                        spacing: 2,
                        children: [
                          RichText(
                            maxLines: 1,
                            overflow: .ellipsis,
                            text: TextSpan(
                              style: infoTextStyle,
                              children: [
                                TextSpan(text: course.courseNumber),
                                const TextSpan(text: ' · '),
                                TextSpan(text: course.teacher.spaced),
                              ],
                            ),
                          ),
                          RichText(
                            maxLines: 1,
                            overflow: .ellipsis,
                            text: TextSpan(
                              style: infoTextStyle,
                              children: [
                                TextSpan(text: course.classroom.spaced),
                                const TextSpan(text: ' · '),
                                TextSpan(text: course.time.spaced),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
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
