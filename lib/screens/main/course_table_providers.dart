import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/repositories/course_repository.dart';

/// Provides the available course-table semesters for the current user.
///
/// Shared by the home and course-table screens so mounted tabs reuse the same
/// Drift stream and background refresh.
final courseTableSemestersProvider = StreamProvider.autoDispose<List<Semester>>(
  (ref) {
    return ref.watch(courseRepositoryProvider).watchSemesters();
  },
);

/// Provides course-table data for a semester.
///
/// Shared by the home and course-table screens so the same semester ID reuses
/// one Drift stream and background refresh. Keying by [Semester.id] avoids
/// recreating the provider when timestamp fields on the row change.
final courseTableProvider = StreamProvider.autoDispose
    .family<CourseTableData, int>((ref, semesterId) {
      return ref
          .watch(courseRepositoryProvider)
          .watchCourseTable(semesterId: semesterId);
    });
