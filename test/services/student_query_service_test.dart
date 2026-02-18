import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/models/ranking.dart';
import 'package:tattoo/models/score.dart';
import 'package:tattoo/models/user.dart';
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

      await portalService.login(
        TestCredentials.username,
        TestCredentials.password,
      );
      await portalService.sso(PortalServiceCode.studentQueryService);

      await respectfulDelay();
    });

    group('getStudentProfile', () {
      test('should return non-empty Chinese name', () async {
        final status = await studentQueryService.getStudentProfile();

        expect(status.chineseName, isNotEmpty);
      });

      test('should parse date of birth as DateTime', () async {
        final status = await studentQueryService.getStudentProfile();

        expect(status.dateOfBirth, isNotNull);
        expect(status.dateOfBirth!.year, greaterThanOrEqualTo(1900));
        expect(status.dateOfBirth!.month, inInclusiveRange(1, 12));
        expect(status.dateOfBirth!.day, inInclusiveRange(1, 31));
      });

      test('should split program into Chinese and English', () async {
        final status = await studentQueryService.getStudentProfile();

        expect(status.programZh, isNotNull);
        expect(status.programEn, isNotNull);
        expect(
          status.programZh,
          isNot(contains(RegExp(r'[A-Za-z]'))),
          reason: 'Chinese part should not contain Latin characters',
        );
        expect(
          status.programEn,
          matches(RegExp(r'^[A-Za-z]')),
          reason: 'English part should start with a Latin character',
        );
      });

      test('should split department into Chinese and English', () async {
        final status = await studentQueryService.getStudentProfile();

        expect(status.departmentZh, isNotNull);
        expect(status.departmentEn, isNotNull);
        expect(
          status.departmentZh,
          isNot(contains(RegExp(r'[A-Za-z]'))),
          reason: 'Chinese part should not contain Latin characters',
        );
        expect(
          status.departmentEn,
          matches(RegExp(r'^[A-Za-z]')),
          reason: 'English part should start with a Latin character',
        );
      });

      test('should parse English name without inline notes', () async {
        final status = await studentQueryService.getStudentProfile();

        if (status.englishName != null) {
          expect(
            status.englishName,
            isNot(contains('申請')),
            reason: 'English name should not contain the inline note text',
          );
        }
      });
    });

    group('getRegistrationRecords', () {
      test('should return records with valid semesters', () async {
        final records = await studentQueryService.getRegistrationRecords();

        expect(
          records,
          isNotEmpty,
          reason: 'Should have at least one registration record',
        );

        for (final record in records) {
          expect(record.semester.year, greaterThan(80));
          expect(record.semester.term, isIn([0, 1, 2, 3]));
        }
      });

      test('should have class name and enrollment status', () async {
        final records = await studentQueryService.getRegistrationRecords();

        for (final record in records) {
          expect(
            record.className,
            isNotNull,
            reason:
                'Semester ${record.semester.year}-${record.semester.term} should have a class name',
          );
          expect(
            record.enrollmentStatus,
            isIn(EnrollmentStatus.values),
            reason:
                'Semester ${record.semester.year}-${record.semester.term} should have a valid enrollment status',
          );
        }
      });

      test('should have at least one tutor per semester', () async {
        final records = await studentQueryService.getRegistrationRecords();

        for (final record in records) {
          expect(
            record.tutors,
            isNotEmpty,
            reason:
                'Semester ${record.semester.year}-${record.semester.term} should have at least one tutor',
          );

          for (final tutor in record.tutors) {
            expect(
              tutor.id,
              isNotNull,
              reason: 'Tutor ${tutor.name} should have an ID from the link',
            );
            expect(
              tutor.name,
              isNotNull,
              reason: 'Tutor should have a name',
            );
          }
        }
      });

      test('should return records in descending order', () async {
        final records = await studentQueryService.getRegistrationRecords();

        for (var i = 0; i < records.length - 1; i++) {
          final current = records[i].semester;
          final next = records[i + 1].semester;
          final currentValue = current.year! * 10 + current.term!;
          final nextValue = next.year! * 10 + next.term!;
          expect(
            currentValue,
            greaterThan(nextValue),
            reason: 'Records should be ordered most recent first',
          );
        }
      });
    });

    group('getGradeRanking', () {
      test('should return rankings with valid semesters', () async {
        final rankings = await studentQueryService.getGradeRanking();

        expect(
          rankings,
          isNotEmpty,
          reason: 'Should have at least one semester of rankings',
        );

        for (final ranking in rankings) {
          expect(ranking.semester.year, greaterThan(80));
          expect(ranking.semester.term, isIn([0, 1, 2, 3]));
        }
      });

      test('should have three ranking types per semester', () async {
        final rankings = await studentQueryService.getGradeRanking();

        for (final ranking in rankings) {
          final types = ranking.entries.map((e) => e.type).toSet();
          expect(
            types,
            containsAll(RankingType.values),
            reason:
                'Semester ${ranking.semester.year}-${ranking.semester.term} '
                'should have class, group, and department rankings',
          );
        }
      });

      test('should have valid rank and total values', () async {
        final rankings = await studentQueryService.getGradeRanking();
        final allEntries = rankings.expand((r) => r.entries);

        for (final entry in allEntries) {
          expect(entry.semesterRank, greaterThan(0));
          expect(entry.semesterTotal, greaterThan(0));
          expect(entry.semesterRank, lessThanOrEqualTo(entry.semesterTotal));

          expect(entry.grandTotalRank, greaterThan(0));
          expect(entry.grandTotalTotal, greaterThan(0));
          expect(
            entry.grandTotalRank,
            lessThanOrEqualTo(entry.grandTotalTotal),
          );
        }
      });

      test('should return rankings in descending order', () async {
        final rankings = await studentQueryService.getGradeRanking();

        for (var i = 0; i < rankings.length - 1; i++) {
          final current = rankings[i].semester;
          final next = rankings[i + 1].semester;
          final currentValue = current.year! * 10 + current.term!;
          final nextValue = next.year! * 10 + next.term!;
          expect(
            currentValue,
            greaterThan(nextValue),
            reason: 'Rankings should be ordered most recent first',
          );
        }
      });
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
          expect(semester.semester.term, isIn([0, 1, 2, 3]));
          expect(
            semester.scores,
            isNotEmpty,
            reason:
                'Semester ${semester.semester.year}-${semester.semester.term} should have courses',
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
                'Semester ${semester.semester.year}-${semester.semester.term} should have an average',
          );
          expect(
            semester.totalCredits,
            isNotNull,
            reason:
                'Semester ${semester.semester.year}-${semester.semester.term} should have total credits',
          );
          expect(
            semester.creditsPassed,
            isNotNull,
            reason:
                'Semester ${semester.semester.year}-${semester.semester.term} should have credits passed',
          );
          // creditsPassed can exceed totalCredits when credit transfers are included
        }
      });

      test('should return semesters in descending order', () async {
        final semesters = await studentQueryService.getAcademicPerformance();

        for (var i = 0; i < semesters.length - 1; i++) {
          final current = semesters[i].semester;
          final next = semesters[i + 1].semester;
          final currentValue = current.year! * 10 + current.term!;
          final nextValue = next.year! * 10 + next.term!;
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
