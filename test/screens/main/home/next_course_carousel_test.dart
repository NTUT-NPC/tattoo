import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/screens/main/home/next_course_card.dart';
import 'package:tattoo/screens/main/home/next_course_carousel.dart';

void main() {
  testWidgets('shows the coffee notice when the selected date has no courses', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NextCourseCarousel(courses: [], initialCourseIndex: null),
        ),
      ),
    );

    expect(find.byType(PageView), findsOneWidget);
    expect(find.byIcon(Icons.coffee_outlined), findsNWidgets(2));
    expect(
      tester
          .widget<Opacity>(find.byKey(const Key('course-ended-notice')))
          .opacity,
      1,
    );
  });

  testWidgets('requests adjacent course dates from empty state edges', (
    tester,
  ) async {
    var previousRequests = 0;
    var nextRequests = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NextCourseCarousel(
            courses: const [],
            initialCourseIndex: null,
            onPreviousDate: () => previousRequests++,
            onNextDate: () => nextRequests++,
          ),
        ),
      ),
    );

    var controller = tester.widget<PageView>(find.byType(PageView)).controller!;
    unawaited(
      controller.animateToPage(
        2,
        duration: const Duration(milliseconds: 300),
        curve: Curves.linear,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(nextRequests, 1);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NextCourseCarousel(
            courses: const [],
            initialCourseIndex: null,
            onPreviousDate: () => previousRequests++,
          ),
        ),
      ),
    );
    controller = tester.widget<PageView>(find.byType(PageView)).controller!;
    unawaited(
      controller.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.linear,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(previousRequests, 1);
  });

  testWidgets('opens on the repository-selected course', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NextCourseCarousel(
            courses: [_course('First'), _course('Second')],
            initialCourseIndex: 1,
          ),
        ),
      ),
    );

    final pageView = tester.widget<PageView>(find.byType(PageView));
    expect(pageView.controller?.page, 2);
  });

  testWidgets('automatically advances when the selected course changes', (
    tester,
  ) async {
    var selectedIndex = 0;
    late StateSetter setState;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, stateSetter) {
              setState = stateSetter;
              return NextCourseCarousel(
                courses: [_course('First'), _course('Second')],
                initialCourseIndex: selectedIndex,
              );
            },
          ),
        ),
      ),
    );

    setState(() => selectedIndex = 1);
    await tester.pump();
    await tester.pumpAndSettle();

    final pageView = tester.widget<PageView>(find.byType(PageView));
    expect(pageView.controller?.page, 2);
  });

  testWidgets('reports the tapped course to its caller', (tester) async {
    NextCourse? tappedCourse;
    final course = _course('Course');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NextCourseCarousel(
            courses: [course],
            initialCourseIndex: 0,
            onCourseTap: (course) => tappedCourse = course,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Course').hitTestable());

    expect(tappedCourse, same(course));
  });
}

NextCourse _course(String title) => NextCourse(
  title: title,
  courseNumber: '123456',
  teacher: 'Teacher',
  classroom: 'Room',
  time: '09:10 - 12:00',
  dayLabel: 'Today',
  state: .upcoming,
);
