import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/models/ranking.dart';
import 'package:tattoo/screens/main/score/score_view_helpers.dart';

void main() {
  group('getAwardQuota', () {
    test('returns 0 for non-positive student counts', () {
      expect(getAwardQuota(0), 0);
      expect(getAwardQuota(-1), 0);
      expect(getAwardQuota(-20), 0);
    });

    test('returns 1 for class sizes up to 20', () {
      expect(getAwardQuota(1), 1);
      expect(getAwardQuota(10), 1);
      expect(getAwardQuota(15), 1);
      expect(getAwardQuota(20), 1);
    });

    test('returns 2 for class sizes between 21 and 40', () {
      expect(getAwardQuota(21), 2);
      expect(getAwardQuota(30), 2);
      expect(getAwardQuota(40), 2);
    });

    test('returns 3 for class sizes between 41 and 60', () {
      expect(getAwardQuota(41), 3);
      expect(getAwardQuota(45), 3);
      expect(getAwardQuota(50), 3);
      expect(getAwardQuota(60), 3);
    });

    test('returns 4 for class sizes between 61 and 80', () {
      expect(getAwardQuota(61), 4);
      expect(getAwardQuota(75), 4);
      expect(getAwardQuota(80), 4);
    });

    test('scales correctly for larger classes', () {
      expect(getAwardQuota(100), 5);
      expect(getAwardQuota(101), 6);
    });
  });

  group('isGoldenRanking', () {
    test('returns false for invalid rank or total', () {
      expect(isGoldenRanking(rank: 0, total: 20), isFalse);
      expect(isGoldenRanking(rank: -1, total: 20), isFalse);
      expect(isGoldenRanking(rank: 1, total: 0), isFalse);
      expect(isGoldenRanking(rank: 1, total: -5), isFalse);
    });

    test('evaluates ranks correctly for class of 15', () {
      expect(isGoldenRanking(rank: 1, total: 15), isTrue);
      expect(isGoldenRanking(rank: 2, total: 15), isFalse);
    });

    test('evaluates ranks correctly for class of 20 boundary', () {
      expect(isGoldenRanking(rank: 1, total: 20), isTrue);
      expect(isGoldenRanking(rank: 2, total: 20), isFalse);
    });

    test('evaluates ranks correctly for class of 21 boundary', () {
      expect(isGoldenRanking(rank: 1, total: 21), isTrue);
      expect(isGoldenRanking(rank: 2, total: 21), isTrue);
      expect(isGoldenRanking(rank: 3, total: 21), isFalse);
    });

    test('evaluates ranks correctly for class of 40 boundary', () {
      expect(isGoldenRanking(rank: 2, total: 40), isTrue);
      expect(isGoldenRanking(rank: 3, total: 40), isFalse);
    });

    test('evaluates ranks correctly for class of 45', () {
      expect(isGoldenRanking(rank: 1, total: 45), isTrue);
      expect(isGoldenRanking(rank: 2, total: 45), isTrue);
      expect(isGoldenRanking(rank: 3, total: 45), isTrue);
      expect(isGoldenRanking(rank: 4, total: 45), isFalse);
    });

    test('evaluates ranks correctly for class of 60 boundary', () {
      expect(isGoldenRanking(rank: 3, total: 60), isTrue);
      expect(isGoldenRanking(rank: 4, total: 60), isFalse);
    });

    test('evaluates ranks correctly for class of 61 boundary', () {
      expect(isGoldenRanking(rank: 4, total: 61), isTrue);
      expect(isGoldenRanking(rank: 5, total: 61), isFalse);
    });
  });

  group('hasGoldenRanking', () {
    test('returns false when rankings list is empty', () {
      expect(hasGoldenRanking(const []), isFalse);
    });

    test('prioritizes classLevel ranking when present', () {
      final qualifyingClassRankings = [
        UserSemesterRanking(
          summary: 1,
          rankingType: RankingType.classLevel,
          semesterRank: 2,
          semesterTotal: 50,
          grandTotalRank: 10,
          grandTotalTotal: 50,
        ),
        UserSemesterRanking(
          summary: 1,
          rankingType: RankingType.departmentLevel,
          semesterRank: 20,
          semesterTotal: 100,
          grandTotalRank: 30,
          grandTotalTotal: 100,
        ),
      ];
      expect(hasGoldenRanking(qualifyingClassRankings), isTrue);

      final nonQualifyingClassRankings = [
        UserSemesterRanking(
          summary: 1,
          rankingType: RankingType.classLevel,
          semesterRank: 10,
          semesterTotal: 50,
          grandTotalRank: 10,
          grandTotalTotal: 50,
        ),
        // Department rank 1 should not override failing classLevel rank
        UserSemesterRanking(
          summary: 1,
          rankingType: RankingType.departmentLevel,
          semesterRank: 1,
          semesterTotal: 100,
          grandTotalRank: 1,
          grandTotalTotal: 100,
        ),
      ];
      expect(hasGoldenRanking(nonQualifyingClassRankings), isFalse);
    });

    test('falls back to other ranking types if classLevel is absent', () {
      final fallbackRankings = [
        UserSemesterRanking(
          summary: 1,
          rankingType: RankingType.groupLevel,
          semesterRank: 1,
          semesterTotal: 30,
          grandTotalRank: 5,
          grandTotalTotal: 30,
        ),
      ];
      expect(hasGoldenRanking(fallbackRankings), isTrue);

      final nonQualifyingFallback = [
        UserSemesterRanking(
          summary: 1,
          rankingType: RankingType.groupLevel,
          semesterRank: 15,
          semesterTotal: 30,
          grandTotalRank: 15,
          grandTotalTotal: 30,
        ),
      ];
      expect(hasGoldenRanking(nonQualifyingFallback), isFalse);
    });
  });
}
