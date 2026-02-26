import 'package:drift/drift.dart' hide Column;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/services/course_service.dart';
import 'package:tattoo/services/portal_service.dart';
import 'package:tattoo/services/student_query_service.dart';

typedef ScorePageState = ({
  List<SemesterScoreDto> semesters,
  Map<String, String> names,
  bool refreshedFromNetwork,
});

String _normalizeIdentifier(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? '' : normalized;
}

int _compareCourseIdentifiers(String left, String right) {
  if (left == right) return 0;

  final leftAsInt = int.tryParse(left);
  final rightAsInt = int.tryParse(right);
  if (leftAsInt != null && rightAsInt != null) {
    return leftAsInt.compareTo(rightAsInt);
  }

  return left.compareTo(right);
}

int _compareScoresByCourseNumber(ScoreDto left, ScoreDto right) {
  final leftNumber = _normalizeIdentifier(left.number);
  final rightNumber = _normalizeIdentifier(right.number);

  final leftHasNumber = leftNumber.isNotEmpty;
  final rightHasNumber = rightNumber.isNotEmpty;

  if (leftHasNumber && rightHasNumber) {
    final byNumber = _compareCourseIdentifiers(leftNumber, rightNumber);
    if (byNumber != 0) return byNumber;
  } else if (leftHasNumber != rightHasNumber) {
    return leftHasNumber ? -1 : 1;
  }

  final leftCode = _normalizeIdentifier(left.courseCode);
  final rightCode = _normalizeIdentifier(right.courseCode);
  return _compareCourseIdentifiers(leftCode, rightCode);
}

List<SemesterScoreDto> _sortScoresWithinSemesters(
  List<SemesterScoreDto> semesters,
) {
  return semesters.map((semester) {
    final sortedScores = [...semester.scores]
      ..sort(_compareScoresByCourseNumber);
    return (
      semester: semester.semester,
      scores: sortedScores,
      average: semester.average,
      conduct: semester.conduct,
      totalCredits: semester.totalCredits,
      creditsPassed: semester.creditsPassed,
      note: semester.note,
    );
  }).toList();
}

class _CachedSemesterState {
  final int year;
  final int term;
  double? average;
  double? conduct;
  double? totalCredits;
  double? creditsPassed;
  String? note;
  final List<ScoreDto> scores;

  _CachedSemesterState({required this.year, required this.term}) : scores = [];
}

Future<ScorePageState> _loadAcademicPerformanceFromDb({
  required AppDatabase db,
  required int userId,
}) async {
  final semesterStates = <int, _CachedSemesterState>{};
  final names = <String, String>{};

  final scoreRows =
      await (db.select(db.scores).join([
              innerJoin(
                db.semesters,
                db.semesters.id.equalsExp(db.scores.semester),
              ),
              innerJoin(db.courses, db.courses.id.equalsExp(db.scores.course)),
              leftOuterJoin(
                db.courseOfferings,
                db.courseOfferings.id.equalsExp(db.scores.courseOffering),
              ),
            ])
            ..where(db.scores.user.equals(userId))
            ..orderBy([
              OrderingTerm.desc(db.semesters.year),
              OrderingTerm.desc(db.semesters.term),
              OrderingTerm.asc(db.courses.code),
            ]))
          .get();

  for (final row in scoreRows) {
    final scoreRow = row.readTable(db.scores);
    final semester = row.readTable(db.semesters);
    final course = row.readTable(db.courses);
    final courseOffering = row.readTableOrNull(db.courseOfferings);

    final state =
        semesterStates[semester.id] ??
        _CachedSemesterState(year: semester.year, term: semester.term);

    state.scores.add((
      number: courseOffering?.number,
      courseCode: course.code,
      score: scoreRow.score,
      status: scoreRow.status,
    ));

    names[course.code] = course.nameZh ?? course.code;
    semesterStates[semester.id] = state;
  }

  if (semesterStates.isEmpty) {
    return (
      semesters: <SemesterScoreDto>[],
      names: names,
      refreshedFromNetwork: false,
    );
  }

  final summaryRows =
      await (db.select(db.userSemesterSummaries).join([
            innerJoin(
              db.semesters,
              db.semesters.id.equalsExp(db.userSemesterSummaries.semester),
            ),
          ])..where(
            db.userSemesterSummaries.user.equals(userId) &
                db.userSemesterSummaries.semester.isIn(
                  semesterStates.keys.toList(),
                ),
          ))
          .get();

  for (final row in summaryRows) {
    final summary = row.readTable(db.userSemesterSummaries);
    final semester = row.readTable(db.semesters);

    final state = semesterStates[semester.id];
    if (state == null) continue;
    state.average = summary.average;
    state.conduct = summary.conduct;
    state.totalCredits = summary.totalCredits;
    state.creditsPassed = summary.creditsPassed;
    state.note = summary.note;
  }

  final semesters = semesterStates.values.toList()
    ..sort((a, b) {
      final yearCompare = b.year.compareTo(a.year);
      if (yearCompare != 0) return yearCompare;
      return b.term.compareTo(a.term);
    });

  final hydratedSemesters = semesters
      .map(
        (semester) => (
          semester: (year: semester.year, term: semester.term),
          scores: semester.scores,
          average: semester.average,
          conduct: semester.conduct,
          totalCredits: semester.totalCredits,
          creditsPassed: semester.creditsPassed,
          note: semester.note,
        ),
      )
      .toList();

  return (
    semesters: _sortScoresWithinSemesters(hydratedSemesters),
    names: names,
    refreshedFromNetwork: false,
  );
}

Future<int> _getOrCreateCourseId(AppDatabase db, String code) async {
  return (await db
          .into(db.courses)
          .insertReturning(
            CoursesCompanion.insert(code: code, credits: 0, hours: 0),
            onConflict: DoUpdate(
              (old) => CoursesCompanion(code: Value(code)),
              target: [db.courses.code],
            ),
          ))
      .id;
}

Future<int> _getOrCreateCourseOfferingId({
  required AppDatabase db,
  required int courseId,
  required int semesterId,
  required String number,
}) async {
  final existing =
      await (db.select(db.courseOfferings)
            ..where((t) => t.number.equals(number))
            ..limit(1))
          .getSingleOrNull();
  if (existing != null) return existing.id;

  return (await db
          .into(db.courseOfferings)
          .insertReturning(
            CourseOfferingsCompanion.insert(
              course: courseId,
              semester: semesterId,
              number: number,
              phase: 0,
              courseType: CourseType.commonElective,
            ),
            onConflict: DoUpdate(
              (old) => CourseOfferingsCompanion(
                course: Value(courseId),
                semester: Value(semesterId),
              ),
              target: [db.courseOfferings.number],
            ),
          ))
      .id;
}

String? _resolveScoreCourseCode(ScoreDto score) {
  final normalizedCode = score.courseCode?.trim();
  if (normalizedCode != null && normalizedCode.isNotEmpty) {
    return normalizedCode;
  }

  final fallback = score.number?.trim();
  if (fallback != null && fallback.isNotEmpty) {
    return fallback;
  }
  return null;
}

Future<void> _persistAcademicPerformance({
  required AppDatabase db,
  required int userId,
  required List<SemesterScoreDto> semesters,
}) async {
  await db.transaction(() async {
    final semesterIds = <String, int>{};
    final courseIds = <String, int>{};
    final fetchedSemesterIds = <int>{};
    final emptySemesterIds = <int>{};

    for (final semesterData in semesters) {
      final year = semesterData.semester.year;
      final term = semesterData.semester.term;
      if (year == null || term == null) {
        continue;
      }

      final semesterKey = '$year-$term';
      final semesterId =
          semesterIds[semesterKey] ?? await db.getOrCreateSemester(year, term);
      semesterIds[semesterKey] = semesterId;
      fetchedSemesterIds.add(semesterId);

      final hasScoreRows = semesterData.scores
          .map(_resolveScoreCourseCode)
          .whereType<String>()
          .isNotEmpty;

      if (!hasScoreRows) {
        emptySemesterIds.add(semesterId);
      }

      await db
          .into(db.userSemesterSummaries)
          .insert(
            UserSemesterSummariesCompanion.insert(
              user: userId,
              semester: semesterId,
              average: Value(semesterData.average),
              conduct: Value(semesterData.conduct),
              totalCredits: Value(semesterData.totalCredits),
              creditsPassed: Value(semesterData.creditsPassed),
              note: Value(semesterData.note),
            ),
            onConflict: DoUpdate(
              (old) => UserSemesterSummariesCompanion(
                average: Value(semesterData.average),
                conduct: Value(semesterData.conduct),
                totalCredits: Value(semesterData.totalCredits),
                creditsPassed: Value(semesterData.creditsPassed),
                note: Value(semesterData.note),
              ),
              target: [
                db.userSemesterSummaries.user,
                db.userSemesterSummaries.semester,
              ],
            ),
          );

      await (db.delete(db.scores)..where(
            (t) => t.user.equals(userId) & t.semester.equals(semesterId),
          ))
          .go();

      for (final score in semesterData.scores) {
        final courseCode = _resolveScoreCourseCode(score);
        if (courseCode == null) {
          continue;
        }

        var courseId = courseIds[courseCode];
        if (courseId == null) {
          courseId = await _getOrCreateCourseId(db, courseCode);
          courseIds[courseCode] = courseId;
        }

        int? offeringId;
        final number = score.number?.trim();
        if (number != null && number.isNotEmpty) {
          offeringId = await _getOrCreateCourseOfferingId(
            db: db,
            courseId: courseId,
            semesterId: semesterId,
            number: number,
          );
        }

        await db
            .into(db.scores)
            .insert(
              ScoresCompanion.insert(
                user: userId,
                semester: semesterId,
                course: courseId,
                courseOffering: Value(offeringId),
                score: Value(score.score),
                status: Value(score.status),
              ),
              onConflict: DoUpdate(
                (old) => ScoresCompanion(
                  courseOffering: Value(offeringId),
                  score: Value(score.score),
                  status: Value(score.status),
                ),
                target: [db.scores.user, db.scores.course, db.scores.semester],
              ),
            );
      }
    }

    if (fetchedSemesterIds.isEmpty) {
      await (db.delete(db.scores)..where((t) => t.user.equals(userId))).go();
    } else {
      await (db.delete(db.scores)..where(
            (t) =>
                t.user.equals(userId) &
                t.semester.isNotIn(fetchedSemesterIds.toList()),
          ))
          .go();
    }

    if (emptySemesterIds.isNotEmpty) {
      await (db.delete(db.userSemesterSummaries)..where(
            (t) =>
                t.user.equals(userId) &
                t.semester.isIn(emptySemesterIds.toList()) &
                t.className.isNull() &
                t.enrollmentStatus.isNull() &
                t.registered.isNull() &
                t.graduated.isNull(),
          ))
          .go();
    }

    if (fetchedSemesterIds.isNotEmpty) {
      await (db.delete(db.userSemesterSummaries)..where(
            (t) =>
                t.user.equals(userId) &
                t.semester.isNotIn(fetchedSemesterIds.toList()) &
                t.className.isNull() &
                t.enrollmentStatus.isNull() &
                t.registered.isNull() &
                t.graduated.isNull(),
          ))
          .go();
    }
  });
}

/// Provides score screen state using a cache-first, revalidate-on-demand flow.
///
/// This provider is the single integration point between UI rendering, local
/// persistence, and remote NTUT systems. On normal screen entry, it reads from
/// Drift and emits quickly so users can see cached scores without waiting for
/// network round-trips. It then attempts authenticated SSO fetches, resolves
/// missing course metadata, persists normalized results back to the database,
/// and emits refreshed data. During explicit pull-to-refresh, the provider
/// intentionally does not emit cached data first, so the loading indicator only
/// finishes after the full refresh pipeline completes. If remote fetch fails but
/// cached data exists, it emits that fallback instead of throwing, allowing the
/// screen to recover gracefully while clearly distinguishing offline fallback
/// from a true network refresh through `refreshedFromNetwork`.
final academicPerformanceProvider = StreamProvider.autoDispose<ScorePageState>(
  (ref) async* {
    final authRepo = ref.watch(authRepositoryProvider);
    final portalService = ref.watch(portalServiceProvider);
    final queryService = ref.watch(studentQueryServiceProvider);
    final courseService = ref.watch(courseServiceProvider);
    final db = ref.watch(databaseProvider);

    final user = await db.select(db.users).getSingleOrNull();
    if (user == null) {
      throw StateError('User not found. Please login again.');
    }

    final cached = await _loadAcademicPerformanceFromDb(
      db: db,
      userId: user.id,
    );
    final shouldEmitCachedFirst = !ref.isRefresh;
    if (shouldEmitCachedFirst && cached.semesters.isNotEmpty) {
      yield cached;
    }

    try {
      final refreshed = await authRepo.withAuth(() async {
        await portalService.sso(PortalServiceCode.studentQueryService);
        final semesters = _sortScoresWithinSemesters(
          await queryService.getAcademicPerformance(),
        );

        final allCodes = semesters
            .expand((s) => s.scores)
            .map((s) => s.courseCode)
            .whereType<String>()
            .map((code) => code.trim())
            .where((code) => code.isNotEmpty)
            .toSet();

        final existingCourses = await (db.select(
          db.courses,
        )..where((t) => t.code.isIn(allCodes.toList()))).get();

        final Map<String, String> courseNames = {
          for (final c in existingCourses) c.code: c.nameZh ?? c.code,
        };

        final missingCodes = allCodes
            .where((code) => !courseNames.containsKey(code))
            .toList();

        if (missingCodes.isNotEmpty) {
          await portalService.sso(PortalServiceCode.courseService);

          await Future.wait(
            missingCodes.map((code) async {
              try {
                final dto = await courseService.getCourse(code);
                if (dto.nameZh != null) {
                  await db
                      .into(db.courses)
                      .insertOnConflictUpdate(
                        CoursesCompanion.insert(
                          code: code,
                          credits: dto.credits ?? 0,
                          hours: dto.hours ?? 0,
                          nameZh: Value(dto.nameZh),
                          nameEn: Value(dto.nameEn),
                          fetchedAt: Value(DateTime.now()),
                        ),
                      );
                  courseNames[code] = dto.nameZh!;
                }
              } catch (e) {
                debugPrint(
                  'Failed to fetch course metadata for code ($code): $e',
                );
              }
            }),
          );
        }

        await _persistAcademicPerformance(
          db: db,
          userId: user.id,
          semesters: semesters,
        );

        return (
          semesters: semesters,
          names: courseNames,
          refreshedFromNetwork: true,
        );
      });
      yield refreshed;
    } catch (error) {
      if (cached.semesters.isEmpty) {
        rethrow;
      }
      debugPrint('Score refresh failed, showing cached data: $error');
      yield cached;
    }
  },
);
