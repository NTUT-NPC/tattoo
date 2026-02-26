import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/screens/main/score/score_providers.dart';
import 'package:tattoo/utils/shared_preferences.dart';

const _scoreLastUpdatedKeyPrefix = 'score.lastUpdatedAt';

String _lastUpdatedCacheKey(String studentId) {
  return '$_scoreLastUpdatedKeyPrefix.$studentId';
}

Future<DateTime?> loadScoreLastUpdatedFromCache(WidgetRef ref) async {
  final db = ref.read(databaseProvider);
  final prefs = ref.read(sharedPreferencesProvider);
  final user = await db.select(db.users).getSingleOrNull();
  if (user == null) return null;

  final raw = await prefs.getString(_lastUpdatedCacheKey(user.studentId));
  if (raw == null) return null;
  return DateTime.tryParse(raw);
}

Future<void> saveScoreLastUpdatedToCache(
  WidgetRef ref,
  DateTime dateTime,
) async {
  final db = ref.read(databaseProvider);
  final prefs = ref.read(sharedPreferencesProvider);
  final user = await db.select(db.users).getSingleOrNull();
  if (user == null) return;

  await prefs.setString(
    _lastUpdatedCacheKey(user.studentId),
    dateTime.toIso8601String(),
  );
}

typedef ScoreRefreshResult = ({
  bool refreshedFromNetwork,
  DateTime? updatedAt,
});

Future<ScoreRefreshResult> reloadScoresAndPersistTimestamp(
  WidgetRef ref,
) async {
  ref.invalidate(academicPerformanceProvider);
  final refreshedState = await ref.read(academicPerformanceProvider.future);

  if (!refreshedState.refreshedFromNetwork) {
    return (refreshedFromNetwork: false, updatedAt: null);
  }

  final now = DateTime.now();
  await saveScoreLastUpdatedToCache(ref, now);
  return (refreshedFromNetwork: true, updatedAt: now);
}
