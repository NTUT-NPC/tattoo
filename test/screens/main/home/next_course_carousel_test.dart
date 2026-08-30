import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/screens/main/home/next_course_carousel.dart';

void main() {
  testWidgets('shows next-date progress and switches from an empty date', (
    tester,
  ) async {
    var nextRequests = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NextCourseCarousel(
            courses: const [],
            initialCourseIndex: null,
            onNextDate: () => nextRequests++,
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(PageView)),
    );
    await gesture.moveBy(const Offset(-300, 0));
    await tester.pump();

    expect(
      find.byKey(const Key('next-week-progress-indicator')),
      findsOneWidget,
    );

    await gesture.up();
    await tester.pumpAndSettle();

    expect(nextRequests, 1);
  });

  testWidgets('does not overlap notices when swiping back from an empty date', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NextCourseCarousel(courses: [], initialCourseIndex: null),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(PageView)),
    );
    await gesture.moveBy(const Offset(100, 0));
    await tester.pump();

    expect(
      tester
          .widget<Opacity>(
            find.byKey(const Key('previous-week-loading-notice')),
          )
          .opacity,
      1,
    );
    expect(
      tester
          .widget<Opacity>(find.byKey(const Key('course-ended-notice')))
          .opacity,
      0,
    );

    await gesture.up();
  });
}
