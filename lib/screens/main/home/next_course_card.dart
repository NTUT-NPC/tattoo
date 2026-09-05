import 'package:flutter/material.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/models/next_course.dart';
import 'package:tattoo/utils/auto_spacing.dart';

const _nextCourseCardShadow = BoxShadow(
  color: Color(0x66000000),
  blurRadius: 16,
  offset: Offset(0, 4),
);

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
    final isDark = theme.brightness == Brightness.dark;
    final gradientColors = isDark
        ? const [Color(0xFF25483F), Color(0xFF1D2936), Color(0xFF293B59)]
        : const [Color(0xFFD3FFE7), Color(0xFFF8FAFF), Color(0xFFDFEAFF)];
    const gradientStops = [0.0, 0.6, 1.0];
    final titleColor = isDark
        ? const Color(0xFFF0F5FF)
        : theme.colorScheme.onSurface;
    final infoColor = isDark
        ? const Color(0xFFBECBD9)
        : theme.colorScheme.onSurfaceVariant;
    final textScaler = MediaQuery.textScalerOf(context);
    final courseTitleTextStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: .w700,
      color: titleColor,
      height: 1.2,
    );
    final courseTitleLineHeight =
        textScaler.scale(courseTitleTextStyle?.fontSize ?? 22) *
        (courseTitleTextStyle?.height ?? 1.2);
    final infoTextStyle = theme.textTheme.labelMedium?.copyWith(
      color: infoColor,
      height: 1.4,
    );
    final stateLabel = switch (course.state) {
      .finished => null,
      .ongoing => t.home.courseStatus.ongoing,
      .imminent => t.home.courseStatus.imminent,
      .upcoming => t.home.courseStatus.next,
      .scheduled => null,
    };
    final header = [course.dayLabel, ?stateLabel].join(' · ');

    const BorderRadius borderRadius = .all(.circular(20));

    final card = SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: .bottomRight,
            radius: 1.35,
            colors: gradientColors,
            stops: gradientStops,
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
                      color: infoColor,
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
    return card;
  }
}
