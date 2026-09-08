import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/repositories/course_repository.dart';

/// Provides the detailed data for a single course offering, keyed by its
/// course number (課號).
///
/// Reads composed offering detail (overview + schedule + teachers + classes)
/// from the database; [refreshCourseTable] keeps it current. A number the
/// database does not hold is looked up over the network and served without
/// being cached. Submitted syllabuses are fetched lazily and separately via
/// [syllabusProvider]. Resolves to `null` only when the course system reports
/// that the number does not exist.
final courseOfferingProvider = FutureProvider.autoDispose
    .family<CourseOfferingDetail?, String>((ref, number) {
      return ref.watch(courseRepositoryProvider).getCourseOffering(number);
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

typedef CourseRosterKey = ({int courseOfferingId, String courseNumber});

/// Watches the locally cached I-School Plus roster for one course offering.
final courseStudentRosterProvider = StreamProvider.autoDispose
    .family<CourseStudentRoster, CourseRosterKey>((ref, key) {
      return ref
          .watch(courseRepositoryProvider)
          .watchStudentRoster(key.courseOfferingId);
    });

/// Refreshes an I-School Plus roster once for the provider's lifecycle.
///
/// Keeping refresh separate from the cache stream lets the UI retain cached
/// students while also reacting to a failed background refresh.
final courseStudentRosterRefreshProvider = FutureProvider.autoDispose
    .family<void, CourseRosterKey>((ref, key) {
      return ref
          .watch(courseRepositoryProvider)
          .refreshStudentRoster(
            courseOfferingId: key.courseOfferingId,
            courseNumber: key.courseNumber,
          );
    });
