import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/repositories/student_repository.dart';

/// Provides score-available semesters for the current user.
///
/// Watches the DB directly — automatically updates when semester data changes.
/// Background-refreshes stale data automatically.
final scoreSemestersProvider = StreamProvider.autoDispose<List<Semester>>((
  ref,
) {
  return ref.watch(studentRepositoryProvider).watchScoreSemesters();
});

/// Provides semester records (scores, GPA, rankings) for the score screen.
///
/// Watches the DB directly — automatically updates when score data changes.
/// Background-refreshes stale data automatically.
final semesterRecordsProvider =
    StreamProvider.autoDispose<List<SemesterRecordData>>((ref) {
      return ref.watch(studentRepositoryProvider).watchSemesterRecords();
    });
