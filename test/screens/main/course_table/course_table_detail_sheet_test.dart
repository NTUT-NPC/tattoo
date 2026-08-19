import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/course_repository.dart';
import 'package:tattoo/screens/main/course_table/course_table_detail_sheet.dart';
import 'package:tattoo/screens/main/course_table/course_table_providers.dart';

void main() {
  testWidgets('loads course detail by offering id', (tester) async {
    int? requestedOfferingId;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          courseOfferingProvider.overrideWith((ref, offeringId) {
            requestedOfferingId = offeringId;
            return Stream<CourseOfferingDetail?>.value(null);
          }),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: CourseTableDetailSheet.byOfferingId(offeringId: 42),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(requestedOfferingId, 42);
    expect(find.text(t.courseTable.notFound), findsOneWidget);
  });

  testWidgets('loads course detail by course number', (
    tester,
  ) async {
    String? requestedCourseNumber;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          courseOfferingByNumberProvider.overrideWith((ref, key) {
            requestedCourseNumber = key;
            return Stream<CourseOfferingDetail?>.value(null);
          }),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: CourseTableDetailSheet.byCourseNumber(
              courseNumber: '334546',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(requestedCourseNumber, '334546');
    expect(find.text(t.courseTable.notFound), findsOneWidget);
  });
}
