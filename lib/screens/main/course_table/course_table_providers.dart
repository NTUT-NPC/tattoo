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

/// Provides the detailed data for a single course offering, keyed by its
/// course number (課號).
///
/// Reads composed offering detail (overview + schedule + teachers + classes)
/// directly from the database; [refreshCourseTable] keeps it current. No
/// network fetch — a teacher's syllabus is fetched lazily and separately via
/// [syllabusProvider]. Emits `null` until the offering exists.
final courseOfferingProvider = StreamProvider.autoDispose
    .family<CourseOfferingDetail?, String>((ref, number) {
      return ref.watch(courseRepositoryProvider).watchCourseOffering(number);
    });

/// Provides a teacher's syllabus aggregate for an offering, fetched lazily on
/// first watch.
///
/// Keyed by the offering id and the authoring teacher's code (from
/// [CourseOfferingDetail.teachers]). Emits cached content immediately when
/// present, blocks on the first fetch otherwise, and emits `null` when the
/// teacher hasn't submitted a syllabus. Section titles remain raw source data;
/// render them with
/// `tryLocalizeSyllabusSectionTitle(section.title) ?? section.title`.
final syllabusProvider = StreamProvider.autoDispose
    .family<SyllabusDetail?, ({int offeringId, String teacherId})>((ref, key) {
      return ref
          .watch(courseRepositoryProvider)
          .watchSyllabus(
            offeringId: key.offeringId,
            teacherId: key.teacherId,
          );
    });
