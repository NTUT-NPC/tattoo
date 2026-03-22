import 'package:flutter/material.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/models/score.dart';
import 'package:tattoo/repositories/student_repository.dart';

String semesterKey(SemesterRecordData record) {
  return '${record.summary.year}-${record.summary.term}';
}

String formatLastUpdated(DateTime dateTime) {
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  final year = dateTime.year;
  final month = twoDigits(dateTime.month);
  final day = twoDigits(dateTime.day);
  final hour = twoDigits(dateTime.hour);
  final minute = twoDigits(dateTime.minute);
  return '$year/$month/$day $hour:$minute';
}

Color getScoreColor(BuildContext context, ScoreDetail score) {
  if (score.score != null) {
    return score.score! >= 60
        ? Colors.green.shade600
        : Theme.of(context).colorScheme.error;
  }
  if (score.status == ScoreStatus.pass ||
      score.status == ScoreStatus.creditTransfer) {
    return Colors.green.shade600;
  }
  return Theme.of(context).colorScheme.onSurfaceVariant;
}

String getScoreStatusText(ScoreStatus? status) {
  return switch (status) {
    ScoreStatus.notEntered => '未輸入',
    ScoreStatus.withdraw => '撤選',
    ScoreStatus.undelivered => '未送成績',
    ScoreStatus.pass => '通過',
    ScoreStatus.fail => '不通過',
    ScoreStatus.creditTransfer => '抵免',
    _ => '-',
  };
}
