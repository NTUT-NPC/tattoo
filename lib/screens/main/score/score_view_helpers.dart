import 'package:flutter/material.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/i18n/strings.g.dart';
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
