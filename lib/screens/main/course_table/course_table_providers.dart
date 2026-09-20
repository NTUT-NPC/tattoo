import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/repositories/course_repository.dart';
import 'package:tattoo/screens/main/i_school_plus_providers.dart';

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

/// Refreshes a roster only when its timestamp is missing or stale.
///
/// Keeping refresh separate from the cache stream lets the UI retain cached
/// students while also reacting to a failed background refresh.
final courseStudentRosterRefreshProvider = FutureProvider.autoDispose
    .family<bool, CourseRosterKey>(retry: (_, _) => null, (ref, key) async {
      final keepAlive = ref.keepAlive();
      try {
        final repository = ref.watch(courseRepositoryProvider);
        if (await repository.isStudentRosterFresh(key.courseOfferingId)) {
          return false;
        }
        await repository.refreshStudentRoster(
          courseOfferingId: key.courseOfferingId,
          courseNumber: key.courseNumber,
        );
        return true;
      } finally {
        keepAlive.close();
      }
    });

/// Runs the public probe in parallel with a stale or missing roster refresh.
final courseStudentRosterAvailabilityProvider = FutureProvider.autoDispose
    .family<void, CourseRosterKey>(retry: (_, _) => null, (ref, key) async {
      final keepAlive = ref.keepAlive();
      try {
        final repository = ref.watch(courseRepositoryProvider);
        if (await repository.isStudentRosterFresh(key.courseOfferingId)) return;
        await ref.watch(iSchoolPlusAvailabilityProvider.future);
      } finally {
        keepAlive.close();
      }
    });

/// Retry is safe only after both halves of the current attempt have settled.
bool canRetryCourseStudentRoster(
  AsyncValue<bool> refresh,
  AsyncValue<void> availability,
) => refresh.hasError && !refresh.isLoading && !availability.isLoading;

enum CourseRosterPresentation { loading, guide, genericFailure, content }

CourseRosterPresentation courseRosterPresentation({
  required bool hasCache,
  required bool showNetworkGuide,
  required bool allowEarlyNetworkGuide,
  required AsyncValue<bool> refresh,
  required AsyncValue<void> availability,
}) {
  final refreshSucceeded = refresh.value == true;
  if (hasCache) {
    return showNetworkGuide && !refreshSucceeded ? .guide : .content;
  }
  final availabilityFailed = availability.hasError && !availability.isLoading;
  final refreshFailed = refresh.hasError && !refresh.isLoading;
  if ((showNetworkGuide ||
          (availabilityFailed && (allowEarlyNetworkGuide || refreshFailed))) &&
      !refreshSucceeded) {
    return .guide;
  }
  if (refreshFailed && !availability.isLoading) {
    return .genericFailure;
  }
  return .loading;
}
