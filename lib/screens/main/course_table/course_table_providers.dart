import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/repositories/course_repository.dart';
import 'package:tattoo/screens/main/i_school_plus_providers.dart';
import 'package:tattoo/services/i_school_plus/i_school_plus_service.dart';

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

typedef CourseISchoolKey = ({int courseOfferingId, String courseNumber});
typedef CourseISchoolRefreshResult = ({
  bool refreshed,
  bool hadCacheAtStart,
});

/// Watches the locally cached I-School Plus roster for one course offering.
final courseStudentRosterProvider = StreamProvider.autoDispose
    .family<CourseStudentRoster, CourseISchoolKey>((ref, key) {
      return ref
          .watch(courseRepositoryProvider)
          .watchStudentRoster(key.courseOfferingId);
    });

/// Refreshes a roster only when its timestamp is missing or stale.
///
/// Keeping refresh separate from the cache stream lets the UI retain cached
/// students while also reacting to a failed background refresh.
final courseStudentRosterRefreshProvider = FutureProvider.autoDispose
    .family<CourseISchoolRefreshResult, CourseISchoolKey>(
      retry: (_, _) => null,
      (ref, key) async {
        final keepAlive = ref.keepAlive();
        try {
          final repository = ref.watch(courseRepositoryProvider);
          final hadCacheAtStart =
              (await repository.watchStudentRoster(key.courseOfferingId).first)
                  .fetchedAt !=
              null;
          if (await repository.isStudentRosterFresh(key.courseOfferingId)) {
            return (refreshed: false, hadCacheAtStart: hadCacheAtStart);
          }
          await repository.refreshStudentRoster(
            courseOfferingId: key.courseOfferingId,
            courseNumber: key.courseNumber,
          );
          return (refreshed: true, hadCacheAtStart: hadCacheAtStart);
        } finally {
          keepAlive.close();
        }
      },
    );

/// Runs the public probe in parallel with a stale or missing roster refresh.
final courseStudentRosterAvailabilityProvider = FutureProvider.autoDispose
    .family<void, CourseISchoolKey>(retry: (_, _) => null, (ref, key) async {
      final keepAlive = ref.keepAlive();
      try {
        final repository = ref.watch(courseRepositoryProvider);
        if (await repository.isStudentRosterFresh(key.courseOfferingId)) return;
        await ref.watch(iSchoolPlusAvailabilityProvider.future);
      } finally {
        keepAlive.close();
      }
    });

final courseMaterialsProvider = StreamProvider.autoDispose
    .family<CourseMaterialList, CourseISchoolKey>((ref, key) {
      return ref
          .watch(courseRepositoryProvider)
          .watchMaterials(key.courseOfferingId);
    });

final courseMaterialsRefreshProvider = FutureProvider.autoDispose
    .family<CourseISchoolRefreshResult, CourseISchoolKey>(
      retry: (_, _) => null,
      (ref, key) => _refreshMaterials(ref, key, force: false),
    );

final courseMaterialsManualRefreshProvider = FutureProvider.autoDispose
    .family<CourseISchoolRefreshResult, CourseISchoolKey>(
      retry: (_, _) => null,
      (ref, key) => _refreshMaterials(ref, key, force: true),
    );

Future<CourseISchoolRefreshResult> _refreshMaterials(
  Ref ref,
  CourseISchoolKey key, {
  required bool force,
}) async {
  final keepAlive = ref.keepAlive();
  try {
    final repository = ref.watch(courseRepositoryProvider);
    final hadCacheAtStart =
        (await repository.watchMaterials(key.courseOfferingId).first)
            .fetchedAt !=
        null;
    if (!force && await repository.areMaterialsFresh(key.courseOfferingId)) {
      return (refreshed: false, hadCacheAtStart: hadCacheAtStart);
    }
    await repository.refreshMaterials(
      courseOfferingId: key.courseOfferingId,
      courseNumber: key.courseNumber,
    );
    return (refreshed: true, hadCacheAtStart: hadCacheAtStart);
  } finally {
    keepAlive.close();
  }
}

final courseMaterialsAvailabilityProvider = FutureProvider.autoDispose
    .family<void, CourseISchoolKey>(
      retry: (_, _) => null,
      (ref, key) => _checkMaterialsAvailability(ref, key, force: false),
    );

final courseMaterialsManualAvailabilityProvider = FutureProvider.autoDispose
    .family<void, CourseISchoolKey>(
      retry: (_, _) => null,
      (ref, key) => _checkMaterialsAvailability(ref, key, force: true),
    );

Future<void> _checkMaterialsAvailability(
  Ref ref,
  CourseISchoolKey key, {
  required bool force,
}) async {
  final keepAlive = ref.keepAlive();
  try {
    if (!force &&
        await ref
            .watch(courseRepositoryProvider)
            .areMaterialsFresh(key.courseOfferingId)) {
      return;
    }
    if (force) {
      // A manual materials attempt must not restart a mounted roster probe.
      await ref.watch(iSchoolPlusServiceProvider).checkAvailability();
    } else {
      await ref.watch(iSchoolPlusAvailabilityProvider.future);
    }
  } finally {
    keepAlive.close();
  }
}

/// Retry is safe only after both halves of the current attempt have settled.
bool canRetryCourseISchool<T>(
  AsyncValue<T> refresh,
  AsyncValue<void> availability,
) => refresh.hasError && !refresh.isLoading && !availability.isLoading;

enum CourseISchoolPresentation { loading, guide, genericFailure, content }

CourseISchoolPresentation courseISchoolPresentation({
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
