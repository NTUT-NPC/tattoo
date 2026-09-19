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

/// Records the most recent explicit roster refresh request for each offering.
///
/// A retry must bypass the normal TTL, while an ordinary provider rebuild
/// should continue using a fresh cached roster.
final courseStudentRosterRefreshRequestedAtProvider = NotifierProvider
    .autoDispose
    .family<
      CourseStudentRosterRefreshRequestedAtNotifier,
      DateTime?,
      CourseRosterKey
    >(CourseStudentRosterRefreshRequestedAtNotifier.new);

class CourseStudentRosterRefreshRequestedAtNotifier
    extends Notifier<DateTime?> {
  CourseStudentRosterRefreshRequestedAtNotifier(CourseRosterKey _);

  DateTime? _completedRequest;

  /// Whether [request] is a retry that has not been served yet.
  ///
  /// Completion is tracked outside [state] so that recording it cannot rebuild
  /// the refresh provider that is publishing the success, which means callers
  /// pass in the request they read rather than reading it back from here.
  bool isPending(DateTime? request) => request != _completedRequest;

  void complete(DateTime? request) => _completedRequest = request;

  @override
  DateTime? build() => null;

  void request() => state = DateTime.now();
}

/// Refreshes an I-School Plus roster when its cache is missing or stale.
///
/// Keeping refresh separate from the cache stream lets the UI retain cached
/// students while also reacting to a failed background refresh.
///
/// Riverpod's automatic retry is disabled so an unreachable I-School Plus
/// fails once instead of replaying a twenty-second request — and its
/// re-authentication — behind the network guidance the UI already shows.
final courseStudentRosterRefreshProvider = FutureProvider.autoDispose
    .family<bool, CourseRosterKey>(retry: (_, _) => null, (ref, key) async {
      final refreshRequestedAt = ref.watch(
        courseStudentRosterRefreshRequestedAtProvider(key),
      );
      final repository = ref.watch(courseRepositoryProvider);
      final request = ref.read(
        courseStudentRosterRefreshRequestedAtProvider(key).notifier,
      );
      final isFresh =
          !request.isPending(refreshRequestedAt) &&
          await repository.isStudentRosterFresh(
            courseOfferingId: key.courseOfferingId,
          );
      if (!ref.mounted) return false;
      if (isFresh) return false;

      await repository.refreshStudentRoster(
        courseOfferingId: key.courseOfferingId,
        courseNumber: key.courseNumber,
      );
      if (!ref.mounted) return false;
      request.complete(refreshRequestedAt);
      return true;
    });
