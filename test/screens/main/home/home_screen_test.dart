import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/repositories/course_repository.dart';
import 'package:tattoo/screens/main/course_table_providers.dart';
import 'package:tattoo/screens/main/home/home_screen.dart';

void main() {
  testWidgets('preserves loading until the course table emits data', (
    tester,
  ) async {
    final semesters = StreamController<List<Semester>>();
    final courseTable = StreamController<CourseTableData>();
    addTearDown(semesters.close);
    addTearDown(courseTable.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          courseTableSemestersProvider.overrideWith(
            (ref) => semesters.stream,
          ),
          courseTableProvider.overrideWith(
            (ref, semesterId) => courseTable.stream,
          ),
        ],
        child: const MaterialApp(home: MainHomeScreen()),
      ),
    );

    expect(find.byKey(const Key('course-carousel-loading')), findsOneWidget);
    expect(find.byIcon(Icons.coffee_outlined), findsNothing);

    semesters.add([
      const Semester(
        id: 1,
        year: 115,
        term: 1,
        inCourseSemesterList: true,
        inScoreSemesterList: false,
      ),
    ]);
    await tester.pump();

    expect(find.byKey(const Key('course-carousel-loading')), findsOneWidget);
    expect(find.byIcon(Icons.coffee_outlined), findsNothing);

    courseTable.add(emptyCourseTableData);
    await tester.pump();

    expect(find.byKey(const Key('course-carousel-loading')), findsNothing);
    expect(find.byIcon(Icons.coffee_outlined), findsNWidgets(2));
  });
}
