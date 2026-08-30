import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/screens/main/home/next_course_card.dart';
import 'package:tattoo/screens/main/home/next_course_carousel.dart';

void main() {
  testWidgets('does not build an overscroll indicator', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NextCourseCarousel(
              courses: [
                NextCourse(
                  title: 'Course',
                  courseNumber: '123456',
                  teacher: 'Teacher',
                  classroom: 'Room',
                  time: '09:10 - 12:00',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(StretchingOverscrollIndicator), findsNothing);
      expect(find.byType(GlowingOverscrollIndicator), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
