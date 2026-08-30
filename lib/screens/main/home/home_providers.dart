import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/repositories/course_repository.dart';

/// Emits immediately and then once per minute so the focused course advances.
final homeClockProvider = StreamProvider.autoDispose<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream<DateTime>.periodic(
    const Duration(minutes: 1),
    (_) => DateTime.now(),
  );
});

/// Provides the course-table semesters available to the current user.
final homeSemestersProvider = StreamProvider.autoDispose<List<Semester>>((ref) {
  return ref.watch(courseRepositoryProvider).watchSemesters();
});

/// Provides repository-composed course-table data for the home screen.
final homeCourseTableProvider = StreamProvider.autoDispose
    .family<CourseTableData, int>((ref, semesterId) {
      return ref
          .watch(courseRepositoryProvider)
          .watchCourseTable(semesterId: semesterId);
    });
