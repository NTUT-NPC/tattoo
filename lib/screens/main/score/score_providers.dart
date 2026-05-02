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
/// Refresh is driven by [scoreSemestersProvider] because both providers read
/// data from the same network payload.
final semesterRecordsProvider =
    StreamProvider.autoDispose<List<SemesterRecordData>>((ref) {
      return ref.watch(studentRepositoryProvider).watchCachedSemesterRecords();
    });

/// Provides semester records indexed by [Semester.id].
///
/// Derived from [semesterRecordsProvider] to keep lookup/shape-conversion
/// logic outside of widgets.
final semesterRecordMapProvider =
    Provider.autoDispose<AsyncValue<Map<int, SemesterRecordData>>>((ref) {
      final semesterRecordsAsync = ref.watch(semesterRecordsProvider);
      return semesterRecordsAsync.whenData((records) {
        return {
          for (final record in records) record.summary.semester: record,
        };
      });
    });
