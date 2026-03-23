import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/repositories/course_repository.dart';
import 'package:tattoo/screens/main/user_providers.dart';

/// Provides the available semesters for the current user.
///
/// Returns an empty list if the user is not logged in.
final courseTableSemestersProvider = FutureProvider.autoDispose<List<Semester>>(
  (ref) async {
    final user = await ref.watch(userProfileProvider.future);
    if (user == null) return [];

    return await ref.watch(courseRepositoryProvider).getSemesters();
  },
);

/// Provides course table cells for a semester.
///
/// Returns an empty table if the user is not logged in.
final courseTableProvider = FutureProvider.autoDispose
    .family<CourseTableData, Semester>((
      ref,
      semester,
    ) async {
      final user = await ref.watch(userProfileProvider.future);
      if (user == null) return CourseTableData();

      return await ref
          .watch(courseRepositoryProvider)
          .getCourseTable(user: user, semester: semester);
    });
