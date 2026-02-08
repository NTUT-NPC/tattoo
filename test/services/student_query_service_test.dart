import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/models/score.dart';
import 'package:tattoo/services/portal_service.dart';
import 'package:tattoo/services/student_query_service.dart';

import '../test_helpers.dart';

void main() {
  group('StudentQueryService Integration Tests', () {
    late PortalService portalService;
    late StudentQueryService studentQueryService;

    setUpAll(() {
      TestCredentials.validate();
    });

    setUp(() async {
      portalService = PortalService();
      studentQueryService = StudentQueryService();

      if (!await portalService.isLoggedIn()) {
        await portalService.login(
          TestCredentials.username,
          TestCredentials.password,
        );
      }
      await portalService.sso(PortalServiceCode.studentQueryService);

      await respectfulDelay();
    });

    group('getAcademicPerformance', () {
      test('should return semesters with scores', () async {
        final semesters = await studentQueryService.getAcademicPerformance();

        expect(
          semesters,
          isNotEmpty,
          reason: 'Should have at least one semester',
        );

        for (final semester in semesters) {
          expect(semester.semester.year, greaterThan(80));
          expect(semester.semester.semester, isIn([1, 2, 3]));
          expect(
            semester.scores,
            isNotEmpty,
            reason:
                'Semester ${semester.semester.year}-${semester.semester.semester} should have courses',
          );
        }
      });

      test('should parse score entries with required fields', () async {
        final semesters = await studentQueryService.getAcademicPerformance();
        final allScores = semesters.expand((s) => s.scores).toList();

        for (final score in allScores) {
          // courseCode should always be present
          expect(
            score.courseCode,
            isNotNull,
            reason: 'Course code should always be present',
          );

          // score and status are mutually exclusive
          final hasScore = score.score != null;
          final hasStatus = score.status != null;
          expect(
            hasScore || hasStatus,
            isTrue,
            reason:
                'Course ${score.courseCode} should have either a numeric score or a status',
          );
          expect(
            hasScore && hasStatus,
            isFalse,
            reason:
                'Course ${score.courseCode} should not have both score and status',
          );
        }
      });

      test('should have valid numeric scores', () async {
        final semesters = await studentQueryService.getAcademicPerformance();
        final numericScores = semesters
            .expand((s) => s.scores)
            .where((s) => s.score != null);

        expect(numericScores, isNotEmpty);

        for (final score in numericScores) {
          expect(
            score.score,
            inInclusiveRange(0, 100),
            reason:
                'Score for ${score.courseCode} should be 0-100, got ${score.score}',
          );
        }
      });

      test('should have valid special statuses', () async {
        final semesters = await studentQueryService.getAcademicPerformance();
        final statusScores = semesters
            .expand((s) => s.scores)
            .where((s) => s.status != null);

        for (final score in statusScores) {
          expect(
            score.status,
            isIn(ScoreStatus.values),
            reason: 'Status for ${score.courseCode} should be a valid enum',
          );
        }
      });

      test('should parse semester summary statistics', () async {
        final semesters = await studentQueryService.getAcademicPerformance();

        for (final semester in semesters) {
          expect(
            semester.average,
            isNotNull,
            reason:
                'Semester ${semester.semester.year}-${semester.semester.semester} should have an average',
          );
          expect(
            semester.totalCredits,
            isNotNull,
            reason:
                'Semester ${semester.semester.year}-${semester.semester.semester} should have total credits',
          );
          expect(
            semester.creditsPassed,
            isNotNull,
            reason:
                'Semester ${semester.semester.year}-${semester.semester.semester} should have credits passed',
          );
          // creditsPassed can exceed totalCredits when credit transfers are included
        }
      });

      test('should return semesters in descending order', () async {
        final semesters = await studentQueryService.getAcademicPerformance();

        for (var i = 0; i < semesters.length - 1; i++) {
          final current = semesters[i].semester;
          final next = semesters[i + 1].semester;
          final currentValue = current.year! * 10 + current.semester!;
          final nextValue = next.year! * 10 + next.semester!;
          expect(
            currentValue,
            greaterThan(nextValue),
            reason: 'Semesters should be ordered most recent first',
          );
        }
      });
    });
  });
}
