import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/models/course.dart';
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

/// Provides the detailed data for a single course offering, keyed by its
/// course number (課號).
///
/// Reads composed offering detail (overview + schedule + teachers + classes)
/// directly from the database; [refreshCourseTable] keeps it current. No
/// network fetch — submitted syllabuses are fetched lazily and separately via
/// [syllabusProvider]. Emits `null` until the offering exists.
final courseOfferingProvider = StreamProvider.autoDispose
    .family<CourseOfferingDetail?, String>((ref, number) {
      return ref.watch(courseRepositoryProvider).watchCourseOffering(number);
    });

/// Provides every submitted syllabus for a course in the requested language,
/// fetched lazily on the first cache miss.
///
/// Keyed by the globally unique course number and source-page language. Each
/// language is cached independently and section titles remain exactly as
/// returned by NTUT.
final syllabusProvider = StreamProvider.autoDispose
    .family<
      List<TeacherSyllabusDetail>,
      ({String courseNumber, SyllabusLanguage language})
    >((ref, key) {
      return ref
          .watch(courseRepositoryProvider)
          .watchSyllabuses(
            courseNumber: key.courseNumber,
            language: key.language,
          );
    });
