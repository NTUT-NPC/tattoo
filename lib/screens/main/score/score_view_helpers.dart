import 'package:flutter/material.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/models/ranking.dart';
import 'package:tattoo/models/score.dart';

Color getScoreColor(BuildContext context, ScoreDetail score) {
  final passingColor = Colors.green.shade600;
  final failingColor = Theme.of(context).colorScheme.error;
  final neutralColor = Theme.of(context).colorScheme.onSurfaceVariant;

  if (score.score case final scoreValue?) {
    return scoreValue >= 60 ? passingColor : failingColor;
  }

  return switch (score.status) {
    .pass || .creditTransfer => passingColor,
    .fail => failingColor,
    _ => neutralColor,
  };
}

String getScoreStatusText(ScoreStatus? status) {
  return switch (status) {
    .notEntered => t.score.status.notEntered,
    .withdraw => t.score.status.withdraw,
    .undelivered => t.score.status.undelivered,
    .pass => t.score.status.pass,
    .fail => t.score.status.fail,
    .creditTransfer => t.score.status.creditTransfer,
    _ => '-',
  };
}

/// Computes the award quota based on group size according to NTUT regulations.
///
/// 20 students or fewer -> 1 award (rank 1)
/// 21-40 students -> 2 awards (ranks 1, 2)
/// 41-60 students -> 3 awards (ranks 1, 2, 3)
/// Formula: `quota = (totalStudents - 1) ~/ 20 + 1`.
int getAwardQuota(int totalStudents) {
  if (totalStudents <= 0) return 0;
  return (totalStudents - 1) ~/ 20 + 1;
}

/// Returns whether a specific [rank] out of [total] qualifies for the academic award.
///
/// Requires positive [rank] and [total], and [rank] must be within the award quota:
/// `rank <= (total - 1) ~/ 20 + 1`.
bool isGoldenRanking({required int rank, required int total}) {
  if (total <= 0 || rank <= 0) return false;
  return rank <= getAwardQuota(total);
}

/// Returns whether a list of [UserSemesterRanking] entries qualifies for the golden award.
///
/// Prioritizes checking the class-level ranking ([RankingType.classLevel]) semester rank,
/// which is the standard scope for academic excellence awards. If no class-level ranking
/// exists, falls back to checking whether any ranking entry qualifies.
bool hasGoldenRanking(List<UserSemesterRanking> rankings) {
  if (rankings.isEmpty) return false;

  final classRanking = rankings.cast<UserSemesterRanking?>().firstWhere(
    (r) => r?.rankingType == RankingType.classLevel,
    orElse: () => null,
  );

  if (classRanking != null) {
    return isGoldenRanking(
      rank: classRanking.semesterRank,
      total: classRanking.semesterTotal,
    );
  }

  return rankings.any(
    (r) => isGoldenRanking(rank: r.semesterRank, total: r.semesterTotal),
  );
}
