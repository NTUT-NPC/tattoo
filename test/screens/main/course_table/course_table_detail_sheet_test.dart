import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tattoo/components/i_school_plus_network_guide.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/course_repository.dart';
import 'package:tattoo/repositories/preferences_repository.dart';
import 'package:tattoo/screens/main/course_table/course_table_detail_sheet.dart';
import 'package:tattoo/screens/main/course_table/course_table_providers.dart';
import 'package:tattoo/screens/main/profile/preference_providers.dart';

void main() {
  const CourseOfferingDetail detail = (
    overview: CourseOfferingOverview(
      id: 1,
      semester: 1,
      number: '352902',
      nameZh: 'Course',
    ),
    schedule: [],
    teachers: [],
    classes: [],
  );
  for (final showRoster in [true, false]) {
    testWidgets('materials load lazily with roster enabled: $showRoster', (
      tester,
    ) async {
      const key = (courseOfferingId: 1, courseNumber: '352902');
      var materialSubscriptions = 0;
      var manualRefreshCalls = 0;
      final manualRefresh = Completer<CourseISchoolRefreshResult>();
      final failedRefresh = Completer<CourseISchoolRefreshResult>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferenceValueProvider.overrideWith(
              (ref, key) => key == PrefKey.showCourseRoster
                  ? showRoster
                  : key.defaultValue,
            ),
            courseOfferingProvider('352902')
                .overrideWith((ref) async => detail),
            syllabusProvider.overrideWith((ref, key) => Stream.value([])),
            courseMaterialsProvider(key).overrideWith((ref) {
              materialSubscriptions++;
              return Stream.value((
                materials: const <CourseMaterial>[],
                fetchedAt: DateTime(2026),
              ));
            }),
            courseMaterialsRefreshProvider(key).overrideWith(
              (ref) async => (refreshed: false, hadCacheAtStart: true),
            ),
            courseMaterialsAvailabilityProvider(key)
                .overrideWith((ref) async {}),
            courseMaterialsManualRefreshProvider(key).overrideWith((ref) async {
              manualRefreshCalls++;
              return manualRefreshCalls == 1
                  ? manualRefresh.future
                  : failedRefresh.future;
            }),
            courseMaterialsManualAvailabilityProvider(key)
                .overrideWith((ref) async {}),
          ],
          child: TranslationProvider(
            child: const MaterialApp(
              home: Scaffold(body: CourseTableDetailSheet(number: '352902')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(t.courseTable.detail.tabs.materials), findsOneWidget);
      expect(
        find.text(t.courseTable.detail.tabs.roster),
        showRoster ? findsOneWidget : findsNothing,
      );
      expect(materialSubscriptions, 0);
      expect(find.text(t.courseTable.detail.materials.refresh), findsNothing);
      await tester.tap(find.text(t.courseTable.detail.tabs.materials));
      await tester.pumpAndSettle();
      expect(materialSubscriptions, 1);
      expect(find.text(t.courseTable.detail.materials.empty), findsOneWidget);
      final refreshButton = find.widgetWithText(
        OutlinedButton,
        t.courseTable.detail.materials.refresh,
      );
      expect(refreshButton, findsOneWidget);
      expect(
        tester.getTopLeft(refreshButton).dy,
        greaterThan(
          tester
              .getBottomLeft(find.text(t.courseTable.detail.materials.empty))
              .dy,
        ),
      );
      await tester.ensureVisible(refreshButton);
      await tester.tap(refreshButton);
      await tester.pump();
      await tester.tap(refreshButton);
      await tester.pump();
      expect(manualRefreshCalls, 1);
      expect(tester.widget<OutlinedButton>(refreshButton).onPressed, isNull);
      manualRefresh.complete((refreshed: true, hadCacheAtStart: true));
      await tester.pumpAndSettle();
      expect(tester.widget<OutlinedButton>(refreshButton).onPressed, isNotNull);
      await tester.tap(find.text(t.courseTable.detail.tabs.syllabus));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.courseTable.detail.tabs.materials));
      await tester.pumpAndSettle();
      expect(materialSubscriptions, 1);
      expect(manualRefreshCalls, 1);
      await tester.ensureVisible(refreshButton);
      await tester.tap(refreshButton);
      await tester.pump();
      failedRefresh.completeError(
        DioException(
          requestOptions: RequestOptions(path: 'materials'),
          type: .connectionError,
        ),
      );
      await tester.pumpAndSettle();
      expect(manualRefreshCalls, 2);
      expect(find.text(t.courseTable.detail.materials.empty), findsOneWidget);
      expect(
        find.text(t.courseTable.detail.materials.updateFailed),
        findsOneWidget,
      );
      await tester.tap(find.text(t.iSchoolPlus.network.learnMore));
      await tester.pumpAndSettle();
      expect(find.byType(ISchoolPlusNetworkGuide), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
