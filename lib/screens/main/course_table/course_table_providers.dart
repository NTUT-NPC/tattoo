import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/repositories/course_repository.dart';

/// Provides the available semesters for the current user.
///
/// Watches the DB directly — automatically updates when semester data changes.
/// Background-refreshes stale data automatically.
final courseTableSemestersProvider = StreamProvider.autoDispose<List<Semester>>(
  (ref) {
    return ref.watch(courseRepositoryProvider).watchSemesters();
  },
);

/// Provides course table cells for a semester.
///
/// Watches the DB directly — automatically updates when course table data
/// changes. Background-refreshes stale data automatically.
///
/// Keyed by [Semester.id] (not the full object) so that timestamp updates
/// on the semester row don't recreate the provider.
final courseTableProvider = StreamProvider.autoDispose
    .family<CourseTableData, int>((ref, semesterId) {
      return ref
          .watch(courseRepositoryProvider)
          .watchCourseTable(semesterId: semesterId);
    });
