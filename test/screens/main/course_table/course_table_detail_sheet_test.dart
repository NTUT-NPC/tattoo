import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/course_repository.dart';
import 'package:tattoo/screens/main/course_table/course_table_detail_sheet.dart';
import 'package:tattoo/screens/main/course_table/course_table_providers.dart';

void main() {
  testWidgets('loads course detail by course number', (tester) async {
    String? requestedNumber;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          courseOfferingProvider.overrideWith((ref, number) {
            requestedNumber = number;
            return Stream<CourseOfferingDetail?>.value(null);
          }),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: CourseTableDetailSheet(number: '334546'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(requestedNumber, '334546');
    expect(find.text(t.courseTable.notFound), findsOneWidget);
  });
}
