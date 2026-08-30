import 'package:flutter/material.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/utils/auto_spacing.dart';

const _nextCourseCardShadow = BoxShadow(
  color: Color(0x66000000),
  blurRadius: 16,
  offset: Offset(0, 4),
);
const _nextCourseCardBlue = Color.fromARGB(255, 223, 234, 255);
const _nextCourseCardSurface = Color(0xFFF8FAFF);
const _nextCourseCardMint = Color.fromARGB(255, 211, 255, 231);

enum NextCourseState { finished, ongoing, imminent, upcoming }

class NextCourse {
  const NextCourse({
    required this.title,
    required this.courseNumber,
    required this.teacher,
    required this.classroom,
    required this.time,
    required this.dayLabel,
    required this.state,
  });

  final String title;
  final String? courseNumber;
  final String teacher;
  final String classroom;
  final String time;
  final String dayLabel;
  final NextCourseState state;
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
    final stateLabel = switch (course.state) {
      .finished => null,
      .ongoing => t.home.courseStatus.ongoing,
      .imminent => t.home.courseStatus.imminent,
      .upcoming => t.home.courseStatus.next,
    };
    final header = [course.dayLabel, ?stateLabel].join(' · ');

    const BorderRadius borderRadius = .all(.circular(20));

    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const RadialGradient(
            center: .bottomRight,
            radius: 1.35,
            colors: [
              _nextCourseCardMint,
              _nextCourseCardSurface,
              _nextCourseCardBlue,
            ],
            stops: [0, 0.6, 1],
          ),
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
              padding: const .all(16),
              child: Column(
                crossAxisAlignment: .stretch,
                mainAxisSize: .min,
                spacing: 32,
                children: [
                  Text(
                    header.spaced,
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
                          alignment: .bottomLeft,
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
                                TextSpan(text: course.courseNumber ?? '-'),
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
