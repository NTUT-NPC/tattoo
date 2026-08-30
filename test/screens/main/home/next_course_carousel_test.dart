import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/screens/main/home/next_course_card.dart';
import 'package:tattoo/screens/main/home/next_course_carousel.dart';

void main() {
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
  state: .upcoming,
);
