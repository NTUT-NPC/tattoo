// ignore_for_file: unused_field

import 'dart:async';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/models/classroom.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/services/course/course_service.dart';
import 'package:tattoo/services/firebase_service.dart';
import 'package:tattoo/services/i_school_plus/i_school_plus_service.dart';
import 'package:tattoo/services/portal/portal_service.dart';
import 'package:tattoo/utils/localized.dart';

/// Detailed data for a single course offering, sufficient to populate the
/// course-table detail bottom sheet. Composes the [CourseOfferingOverview]
/// view row (single-value offering+catalog fields) with the offering's
/// many-side relations (schedule slots, teachers, classes).
///
/// Future iSchool-sourced lists (roster, assignments) will be added as
/// additional fields on this record.
typedef CourseOfferingDetail = ({
  CourseOfferingOverview overview,
  List<
    ({
      DayOfWeek day,
      Period period,
      String? classroomNameZh,
      String? classroomNameEn,
    })
  >
  schedule,
  List<({String code, String nameZh, String? nameEn})> teachers,
  List<({String code, String nameZh, String? nameEn})> classes,
});

/// Data for a single cell in the course table grid.
typedef CourseTableCellData = ({
  /// [CourseOfferings] primary key, for navigating to detail view.
  int id,

  /// [CourseOfferings.number], null for special entries.
  String? number,

  /// Number of consecutive period rows this cell spans (excluding noon).
  int span,

  /// Whether this cell spans across the noon period, meaning the UI must
  /// account for the noon row's height when calculating the cell's size.
  bool crossesNoon,

  /// Localized course name.
  String courseName,

  /// Localized classroom name for this timeslot.
  String? classroomName,

  /// Number of credits for this course.
  double credits,

  /// Number of class hours per week.
  int hours,
});

/// Scheduled course table grid data and unscheduled courses, with
/// pre-computed layout metadata for the course table UI.
typedef CourseTableData = ({
  /// Maps `(dayOfWeek, period)` grid positions to cell data.
  ///
  /// Only the start slot of a multi-period block has an entry; subsequent
  /// slots covered by [CourseTableCellData.span] are absent from the map.
  Map<({DayOfWeek day, Period period}), CourseTableCellData> scheduled,

  /// Courses with no assigned schedule slots (e.g., thesis, internship).
  List<CourseTableCellData> unscheduled,

  /// Whether any course falls on a weekday (Mon-Fri).
  bool hasWeekdayCourse,

  /// Whether any course falls on Saturday.
  bool hasSaturdayCourse,

  /// Whether any course falls on Sunday.
  bool hasSundayCourse,

  /// Whether any course falls in the morning period (1-4).
  bool hasAMCourse,

  /// Whether any course falls in the afternoon period (5-9).
  bool hasPMCourse,

  /// Whether any course falls in the noon period (N).
  bool hasNoonCourse,

  /// Whether any course falls in the evening period (A-D).
  bool hasEveningCourse,

  /// Earliest period that has a course, or null if empty.
  Period? earliestPeriod,

  /// Latest period that has a course (accounting for span), or null if empty.
  Period? latestPeriod,

  /// Sum of credits across all distinct courses (scheduled + unscheduled).
  double totalCredits,

  /// Sum of hours across all distinct courses (scheduled + unscheduled).
  int totalHours,
});

/// An empty [CourseTableData] with no courses.
const emptyCourseTableData = (
  scheduled: <({DayOfWeek day, Period period}), CourseTableCellData>{},
  unscheduled: <CourseTableCellData>[],
  hasWeekdayCourse: false,
  hasSaturdayCourse: false,
  hasSundayCourse: false,
  hasAMCourse: false,
  hasPMCourse: false,
  hasNoonCourse: false,
  hasEveningCourse: false,
  earliestPeriod: null,
  latestPeriod: null,
  totalCredits: 0.0,
  totalHours: 0,
);

/// Provides the [CourseRepository] instance.
final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  ref.watch(sessionProvider);
  return CourseRepository(
    portalService: ref.watch(portalServiceProvider),
    courseService: ref.watch(courseServiceProvider),
    iSchoolPlusService: ref.watch(iSchoolPlusServiceProvider),
    database: ref.watch(databaseProvider),
    authRepository: ref.watch(authRepositoryProvider),
    firebaseService: firebaseService,
  );
});

/// Provides course schedules, catalog, materials, and student rosters.
///
/// ```dart
/// final repo = ref.watch(courseRepositoryProvider);
///
/// // Observe available semesters (auto-refreshes when stale)
/// final stream = repo.watchSemesters();
///
/// // Force refresh (for pull-to-refresh)
/// await repo.refreshSemesters();
///
/// // Observe course schedule for a semester
/// final courseStream = repo.watchCourseTable(semester: semesters.first);
/// ```
class CourseRepository {
  final PortalService _portalService;
  final CourseService _courseService;
  final ISchoolPlusService _iSchoolPlusService;
  final AppDatabase _database;
  final AuthRepository _authRepository;
  final FirebaseService _firebaseService;

  CourseRepository({
    required this._portalService,
    required this._courseService,
    required this._iSchoolPlusService,
    required this._database,
    required this._authRepository,
    required this._firebaseService,
  });

  /// Watches available semesters for the authenticated student.
  ///
  /// Emits cached data immediately, then triggers a background network fetch
  /// if data is empty or stale. The stream re-emits automatically when the
  /// DB is updated.
  ///
  /// Network errors during background refresh are absorbed — the stream
  /// continues showing stale (or empty) data rather than erroring.
  Stream<List<Semester>> watchSemesters() async* {
    const ttl = Duration(days: 3);

    final query = _database.select(_database.semesters)
      ..where((s) => s.inCourseSemesterList.equals(true))
      ..orderBy([
        (s) => OrderingTerm.desc(s.year),
        (s) => OrderingTerm.desc(s.term),
      ]);

    await for (final semesters in query.watch()) {
      if (semesters.isEmpty) {
        try {
          await refreshSemesters();
        } catch (_) {
          // Absorb: yield empty below so UI exits loading state
        }
      }

      yield semesters;

      final user = await _database.select(_database.users).getSingleOrNull();
      final age = switch (user?.semestersFetchedAt) {
        final t? => DateTime.now().difference(t),
        null => ttl,
      };
      if (age >= ttl) {
        try {
          await refreshSemesters();
        } catch (_) {
          // Absorb: stale data is shown via stream
        }
      }
    }
  }

  /// Fetches fresh semester data from network and writes to DB.
  ///
  /// The [watchSemesters] stream automatically emits the updated value.
  /// Network errors propagate to the caller.
  Future<void> refreshSemesters() async {
    final dtos = await _authRepository.withAuth(
      _courseService.getCourseSemesterList,
      sso: [.courseService],
    );

    await _database.transaction(() async {
      final fetchedSemesterIds = <int>{};
      for (final dto in dtos) {
        if (dto case (year: final year?, term: final term?)) {
          final semester = await _database.getOrCreateSemester(
            year,
            term,
            inCourseSemesterList: true,
          );
          fetchedSemesterIds.add(semester.id);
        }
      }

      // Keep membership flag in sync with the latest course semester response.
      // Skip on empty.
      if (fetchedSemesterIds.isNotEmpty) {
        await (_database.update(_database.semesters)..where(
              (s) =>
                  s.inCourseSemesterList.equals(true) &
                  s.id.isNotIn(fetchedSemesterIds),
            ))
            .write(
              const SemestersCompanion(inCourseSemesterList: Value(false)),
            );
      }

      await (_database.update(_database.users)).write(
        UsersCompanion(semestersFetchedAt: Value(DateTime.now())),
      );
    });
  }

  /// Watches the course schedule for a semester with automatic background refresh.
  ///
  /// Emits cached data immediately, then triggers a background network fetch
  /// if data is empty or stale. The stream re-emits automatically when the
  /// DB is updated.
  ///
  /// Use [watchCourseOffering] for related data (teachers, classrooms, schedules).
  Stream<CourseTableData> watchCourseTable({required int semesterId}) async* {
    const ttl = Duration(days: 3);

    final query = _database.select(_database.courseTableSlots)
      ..where((s) => s.semester.equals(semesterId));

    await for (final rows in query.watch()) {
      final allOfferingRows =
          await (_database.select(
            _database.courseOfferings,
          )..where((o) => o.semester.equals(semesterId))).join([
            leftOuterJoin(
              _database.courses,
              _database.courses.code.equalsExp(
                _database.courseOfferings.courseCode,
              ),
            ),
          ]).get();
      final allOfferings = allOfferingRows.map((row) {
        final offering = row.readTable(_database.courseOfferings);
        final course = row.readTableOrNull(_database.courses);
        return (offering: offering, course: course);
      }).toList();
      final data = _buildCourseTableData(rows, allOfferings);

      if (data.scheduled.isEmpty && data.unscheduled.isEmpty) {
        try {
          await refreshCourseTable(semesterId: semesterId);
        } catch (_) {
          // Absorb: yield empty below so UI exits loading state
        }
      }

      yield data;

      final semesterRow = await (_database.select(
        _database.semesters,
      )..where((s) => s.id.equals(semesterId))).getSingleOrNull();
      if (semesterRow == null) return;

      final age = switch (semesterRow.courseTableFetchedAt) {
        final t? => DateTime.now().difference(t),
        null => ttl,
      };

      if (age >= ttl) {
        try {
          await refreshCourseTable(semesterId: semesterId);
        } catch (_) {
          // Absorb: stale data is shown via stream
        }
      }
    }
  }

  /// Fetches fresh course table data from network and writes to DB.
  ///
  /// The [watchCourseTable] stream automatically emits the updated value.
  /// Network errors propagate to the caller.
  Future<void> refreshCourseTable({required int semesterId}) async {
    final user = await _database.select(_database.users).getSingle();
    final semester = await (_database.select(
      _database.semesters,
    )..where((s) => s.id.equals(semesterId))).getSingle();

    final dtos = await _authRepository.withAuth(
      () => _courseService.getCourseTable(
        username: user.studentId,
        semester: (year: semester.year, term: semester.term),
      ),
      sso: [.courseService],
    );

    final freshNumbers = dtos.map((d) => d.number).nonNulls.toSet();

    // Deduplicate Crashlytics reports for unknown classroom prefixes,
    // since the same classroom can appear in multiple schedule slots.
    final reportedUnknownClassrooms = <String>{};

    // Persist to database
    await _database.transaction(() async {
      // Remove numbered offerings no longer in the response (e.g. dropped
      // courses). Junction/child rows are cascade-deleted by FK constraints.
      await (_database.delete(_database.courseOfferings)..where(
            (o) =>
                o.semester.equals(semester.id) &
                o.number.isNotNull() &
                o.number.isNotIn(freshNumbers),
          ))
          .go();

      // Delete all special entries (null number) — they're re-inserted below.
      await (_database.delete(_database.courseOfferings)..where(
            (o) => o.semester.equals(semester.id) & o.number.isNull(),
          ))
          .go();

      for (final dto in dtos) {
        final courseCode = dto.course?.id;
        final courseNameZh = dto.course?.nameZh;

        if (courseNameZh == null) {
          _firebaseService.recordNonFatal(
            'Skipped offering with no name: '
            'number=${dto.number}, courseCode=$courseCode',
          );
          continue;
        }

        final offeringId = await _database.upsertCourseOffering(
          courseCode: courseCode,
          semesterId: semester.id,
          number: dto.number,
          nameZh: courseNameZh,
          nameEn: dto.course?.nameEn,
          credits: dto.credits,
          hours: dto.hours,
          phase: dto.phase,
          status: dto.status,
          language: dto.language,
          remarks: dto.remarks,
          syllabusId: dto.syllabusId,
        );

        // Clear old junctions and schedules for this offering
        await (_database.delete(
          _database.courseOfferingTeachers,
        )..where((t) => t.courseOffering.equals(offeringId))).go();
        await (_database.delete(
          _database.courseOfferingClasses,
        )..where((t) => t.courseOffering.equals(offeringId))).go();
        await (_database.delete(
          _database.schedules,
        )..where((t) => t.courseOffering.equals(offeringId))).go();

        // Teachers
        if (dto.teachers case final teachers?) {
          for (final t in teachers) {
            if (t case LocalizedRefDto(:final id?, :final nameZh?)) {
              final teacherSemesterId = await _database.upsertTeacherSemester(
                code: id,
                semesterId: semester.id,
                nameZh: nameZh,
                nameEn: t.nameEn,
              );
              await _database
                  .into(_database.courseOfferingTeachers)
                  .insert(
                    CourseOfferingTeachersCompanion.insert(
                      courseOffering: offeringId,
                      teacherSemester: teacherSemesterId,
                    ),
                    mode: .insertOrIgnore,
                  );
            }
          }
        }

        // Classes
        if (dto.classes case final classes?) {
          for (final c in classes) {
            if (c case LocalizedRefDto(:final id?, :final nameZh?)) {
              final classId = await _database.upsertClass(
                code: id,
                semesterId: semester.id,
                nameZh: nameZh,
                nameEn: c.nameEn,
              );
              await _database
                  .into(_database.courseOfferingClasses)
                  .insert(
                    CourseOfferingClassesCompanion.insert(
                      courseOffering: offeringId,
                      classEntity: classId,
                    ),
                    mode: .insertOrIgnore,
                  );
            }
          }
        }

        // Schedules
        if (dto.schedule case final slots?) {
          for (final slot in slots) {
            int? classroomId;
            if (slot.classroom case (id: final id?, name: final name?)) {
              final nameEn = translateClassroomName(name);
              if (nameEn == null && reportedUnknownClassrooms.add(id)) {
                _firebaseService.crashlytics?.recordError(
                  Exception('Unknown classroom prefix: $name (code: $id)'),
                  .current,
                  fatal: false,
                );
              }
              classroomId = await _database.upsertClassroom(
                code: id,
                nameZh: name,
                nameEn: nameEn,
              );
            }
            await _database
                .into(_database.schedules)
                .insert(
                  SchedulesCompanion.insert(
                    courseOffering: offeringId,
                    dayOfWeek: slot.day,
                    period: slot.period,
                    classroom: Value(classroomId),
                  ),
                  mode: .insertOrReplace,
                );
          }
        }
      }

      // Update the fetch timestamp on the semester
      await (_database.update(
        _database.semesters,
      )..where((s) => s.id.equals(semester.id))).write(
        SemestersCompanion(
          courseTableFetchedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  /// Builds [CourseTableData] from scheduled view rows and all offerings for
  /// the semester, computing multi-period spans and layout metadata.
  static CourseTableData _buildCourseTableData(
    List<CourseTableSlot> rows,
    List<({CourseOffering offering, Course? course})> allOfferings,
  ) {
    final scheduled = <({DayOfWeek day, Period period}), CourseTableCellData>{};

    for (final row in rows) {
      final key = (day: row.dayOfWeek, period: row.period);
      if (scheduled.containsKey(key)) continue;

      final courseName = localized(row.nameZh, row.nameEn);
      scheduled[key] = (
        id: row.id,
        number: row.number,
        span: 1,
        crossesNoon: false,
        courseName: courseName,
        classroomName: switch ((row.classroomNameZh, row.classroomNameEn)) {
          (final zh?, final en) => localized(zh, en),
          _ => null,
        },
        credits: row.credits ?? 0,
        hours: row.hours ?? 0,
      );
    }

    // Compute spans: for each slot, look ahead at consecutive periods on the
    // same day. Matching offerings are tracked in a consumed set, and the
    // starting slot gets the total span. Consumed slots are removed at the end.
    //
    // When no course occupies the noon period on any day, courses that span
    // across noon (e.g. period 4 → 5) are merged. The noon period is skipped
    // (not counted in span) and crossesNoon is set for UI height calculation.
    final hasNoon = scheduled.keys.any((s) => s.period == .nPeriod);
    final consumed = <({DayOfWeek day, Period period})>{};
    for (final entry in scheduled.entries) {
      if (consumed.contains(entry.key)) continue;
      var span = 1;
      var crossesNoon = false;
      var lookIndex = entry.key.period.index + 1;

      while (lookIndex < Period.values.length) {
        final nextPeriod = Period.values[lookIndex];
        // Skip noon if no courses use it
        if (nextPeriod == .nPeriod && !hasNoon) {
          lookIndex++;
          continue;
        }
        final nextKey = (day: entry.key.day, period: nextPeriod);
        if (scheduled[nextKey] case final next?
            when next.id == entry.value.id) {
          consumed.add(nextKey);
          span++;
          crossesNoon = entry.key.period.isAM && nextPeriod.isPM;
          lookIndex++;
        } else {
          break;
        }
      }

      if (span > 1 || crossesNoon) {
        scheduled[entry.key] = (
          id: entry.value.id,
          number: entry.value.number,
          span: span,
          crossesNoon: crossesNoon,
          courseName: entry.value.courseName,
          classroomName: entry.value.classroomName,
          credits: entry.value.credits,
          hours: entry.value.hours,
        );
      }
    }

    scheduled.removeWhere((key, _) => consumed.contains(key));

    // Filter offerings not present in the scheduled map.
    final scheduledIds = scheduled.values.map((c) => c.id).toSet();
    final unscheduled = allOfferings
        .where((row) => !scheduledIds.contains(row.offering.id))
        .map((row) {
          final courseName = localized(
            row.offering.nameZh,
            row.offering.nameEn ?? row.course?.nameEn,
          );
          return (
            id: row.offering.id,
            number: row.offering.number,
            span: 0,
            crossesNoon: false,
            courseName: courseName,
            classroomName: null,
            credits: row.offering.credits ?? row.course?.credits ?? 0.0,
            hours: row.offering.hours ?? row.course?.hours ?? 0,
          );
        })
        .toList(growable: false);

    // Compute layout metadata from the scheduled map.
    final allEntryPeriods = scheduled.entries
        .expand((e) {
          final noonIndex = Period.nPeriod.index;
          final start = e.key.period.index;
          return List.generate(e.value.span, (i) {
            final raw = start + i;
            return Period.values[raw >= noonIndex && e.value.crossesNoon
                ? raw + 1
                : raw];
          });
        })
        .toList(growable: false);

    // Unique courses by ID for credit/hour aggregation.
    final seen = <int>{};
    final uniqueCourses = [
      ...scheduled.values.where((c) => seen.add(c.id)),
      ...unscheduled.where((c) => seen.add(c.id)),
    ];

    return (
      scheduled: scheduled,
      unscheduled: unscheduled,
      hasWeekdayCourse: scheduled.keys.any((s) => s.day.isWeekday),
      hasSaturdayCourse: scheduled.keys.any((s) => s.day == .saturday),
      hasSundayCourse: scheduled.keys.any((s) => s.day == .sunday),
      hasAMCourse: allEntryPeriods.any((p) => p.isAM),
      hasPMCourse: allEntryPeriods.any((p) => p.isPM),
      hasNoonCourse: allEntryPeriods.any((p) => p == .nPeriod),
      hasEveningCourse: allEntryPeriods.any((p) => p.isEvening),
      earliestPeriod: scheduled.isEmpty
          ? null
          : Period.values[scheduled.keys
                .map((s) => s.period.index)
                .reduce(min)],
      latestPeriod: allEntryPeriods.isEmpty
          ? null
          : allEntryPeriods.reduce((a, b) => a.index > b.index ? a : b),
      totalCredits: uniqueCourses.fold(0.0, (sum, c) => sum + c.credits),
      totalHours: uniqueCourses.fold(0, (sum, c) => sum + c.hours),
    );
  }

  /// Watches a course offering's joined detail (overview + schedule + teachers
  /// + classes).
  ///
  /// Assumes [refreshCourseTable] has already populated the offering and its
  /// junctions. Emits `null` when the offering is missing; the stream stays
  /// open so a later insert can surface it.
  ///
  /// Refresh behavior on the first non-null emission, gated by
  /// [CourseOfferings.fetchedAt]:
  /// - **Never fetched** (`fetchedAt == null`): blocks on [refreshCourseOffering]
  ///   before yielding so consumers don't render null syllabus fields
  ///   (`courseType`, `enrolled`, `withdrawn`, `syllabusRemarks`, …). If the
  ///   refresh fails, falls through and emits the cached row (with whatever's
  ///   there).
  /// - **Previously fetched**: yields cached data immediately and fires
  ///   [refreshCourseOffering] in the background. When that write lands, the
  ///   view's `.watch()` re-emits with fresh fields.
  ///
  /// The refresh decision happens inside the stream loop (rather than as a
  /// pre-check), so an offering that is inserted *after* subscription still
  /// gets the blocking first-load behavior on its first appearance.
  Stream<CourseOfferingDetail?> watchCourseOffering(int id) async* {
    final query = _database.select(_database.courseOfferingOverviews)
      ..where((o) => o.id.equals(id));

    var refreshTriggered = false;
    await for (final overview in query.watchSingleOrNull()) {
      if (overview == null) {
        yield null;
        continue;
      }

      if (!refreshTriggered) {
        refreshTriggered = true;
        final raw = await (_database.select(
          _database.courseOfferings,
        )..where((o) => o.id.equals(id))).getSingleOrNull();
        if (raw?.fetchedAt == null) {
          try {
            await refreshCourseOffering(id);
            // Wait for the resulting DB write to re-emit a populated row.
            continue;
          } catch (_) {
            // Absorb: fall through and emit the cached row below.
          }
        } else {
          unawaited(refreshCourseOffering(id).catchError((_) {}));
        }
      }

      final (schedule, teachers, classes) = await (
        _readOfferingSchedule(id),
        _readOfferingTeachers(id),
        _readOfferingClasses(id),
      ).wait;
      yield (
        overview: overview,
        schedule: schedule,
        teachers: teachers,
        classes: classes,
      );
    }
  }

  /// Fetches a course offering's syllabus from the network and writes it to
  /// the [CourseOfferings] row.
  ///
  /// The [watchCourseOffering] stream automatically emits the updated value.
  /// Network errors propagate to the caller. No-ops when the offering is
  /// missing or has no `syllabusId` / `number`.
  Future<void> refreshCourseOffering(int id) async {
    final raw = await (_database.select(
      _database.courseOfferings,
    )..where((o) => o.id.equals(id))).getSingleOrNull();
    if (raw == null) return;
    if (raw.syllabusId == null || raw.number == null) return;

    final syllabus = await _authRepository.withAuth(
      () => _courseService.getSyllabus(
        courseNumber: raw.number!,
        syllabusId: raw.syllabusId!,
      ),
      sso: [.courseService],
    );

    await (_database.update(
      _database.courseOfferings,
    )..where((o) => o.id.equals(id))).write(
      CourseOfferingsCompanion(
        courseType: Value(syllabus.type),
        enrolled: Value(syllabus.enrolled),
        withdrawn: Value(syllabus.withdrawn),
        syllabusUpdatedAt: Value(syllabus.lastUpdated),
        objective: Value(syllabus.objective),
        weeklyPlan: Value(syllabus.weeklyPlan),
        evaluation: Value(syllabus.evaluation),
        textbooks: Value(syllabus.materials),
        syllabusRemarks: Value(syllabus.remarks),
        fetchedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<
    List<
      ({
        DayOfWeek day,
        Period period,
        String? classroomNameZh,
        String? classroomNameEn,
      })
    >
  >
  _readOfferingSchedule(int id) async {
    final rows =
        await (_database.select(_database.schedules).join([
                leftOuterJoin(
                  _database.classrooms,
                  _database.classrooms.id.equalsExp(
                    _database.schedules.classroom,
                  ),
                ),
              ])
              ..where(_database.schedules.courseOffering.equals(id))
              ..orderBy([
                OrderingTerm.asc(_database.schedules.dayOfWeek),
                OrderingTerm.asc(_database.schedules.period),
              ]))
            .get();
    return [
      for (final row in rows)
        (
          day: row.readTable(_database.schedules).dayOfWeek,
          period: row.readTable(_database.schedules).period,
          classroomNameZh: row.readTableOrNull(_database.classrooms)?.nameZh,
          classroomNameEn: row.readTableOrNull(_database.classrooms)?.nameEn,
        ),
    ];
  }

  Future<List<({String code, String nameZh, String? nameEn})>>
  _readOfferingTeachers(int id) async {
    final rows =
        await (_database.select(_database.courseOfferingTeachers).join([
              innerJoin(
                _database.teacherSemesters,
                _database.teacherSemesters.id.equalsExp(
                  _database.courseOfferingTeachers.teacherSemester,
                ),
              ),
              innerJoin(
                _database.teachers,
                _database.teachers.id.equalsExp(
                  _database.teacherSemesters.teacher,
                ),
              ),
            ])..where(
              _database.courseOfferingTeachers.courseOffering.equals(id),
            ))
            .get();
    return [
      for (final row in rows)
        (
          code: row.readTable(_database.teachers).code,
          nameZh: row.readTable(_database.teachers).nameZh,
          nameEn: row.readTable(_database.teachers).nameEn,
        ),
    ];
  }

  Future<List<({String code, String nameZh, String? nameEn})>>
  _readOfferingClasses(int id) async {
    final rows =
        await (_database.select(_database.courseOfferingClasses).join([
                innerJoin(
                  _database.classes,
                  _database.classes.id.equalsExp(
                    _database.courseOfferingClasses.classEntity,
                  ),
                ),
              ])
              ..where(_database.courseOfferingClasses.courseOffering.equals(id))
              ..orderBy([OrderingTerm.asc(_database.classes.code)]))
            .get();
    return [
      for (final row in rows)
        (
          code: row.readTable(_database.classes).code,
          nameZh: row.readTable(_database.classes).nameZh,
          nameEn: row.readTable(_database.classes).nameEn,
        ),
    ];
  }

  /// Gets course catalog information by code.
  ///
  /// Returns cached data if fresh (within TTL). Set [refresh] to `true` to
  /// bypass TTL (pull-to-refresh).
  Future<Course> getCourse(String code, {bool refresh = false}) async {
    const ttl = Duration(days: 3);

    if (!refresh) {
      final cached = await (_database.select(
        _database.courses,
      )..where((c) => c.code.equals(code))).getSingleOrNull();

      if (cached != null) {
        final age = switch (cached.fetchedAt) {
          final t? => DateTime.now().difference(t),
          null => ttl,
        };
        if (age < ttl) return cached;
      }
    }

    final dto = await _authRepository.withAuth(
      () => _courseService.getCourse(code),
      sso: [.courseService],
    );

    if (dto.nameZh == null || dto.credits == null || dto.hours == null) {
      _firebaseService.recordNonFatal(
        'Incomplete course data for $code: '
        'nameZh=${dto.nameZh}, credits=${dto.credits}, hours=${dto.hours}',
      );
    }

    final courseId = await _database.upsertCourse(
      code: code,
      credits: dto.credits ?? 0,
      hours: dto.hours ?? 0,
      nameZh: dto.nameZh ?? code,
      nameEn: dto.nameEn,
    );

    await (_database.update(
      _database.courses,
    )..where((c) => c.id.equals(courseId))).write(
      CoursesCompanion(
        descriptionZh: Value(dto.descriptionZh),
        descriptionEn: Value(dto.descriptionEn),
        fetchedAt: Value(DateTime.now()),
      ),
    );

    return (_database.select(
      _database.courses,
    )..where((c) => c.id.equals(courseId))).getSingle();
  }

  /// Gets course materials (files, recordings, etc.) from I-School Plus.
  ///
  /// Throws [Exception] on network failure.
  Future<List<CourseMaterial>> getMaterials(
    CourseOffering courseOffering,
  ) async {
    throw UnimplementedError();
  }

  /// Gets the download URL for a material.
  ///
  /// The returned `MaterialDto.referer` must be included as a Referer header
  /// when downloading, if non-null.
  ///
  /// Throws [Exception] on network failure.
  /// Throws [UnimplementedError] for course recordings (not yet supported).
  Future<MaterialDto> getMaterialDownload(CourseMaterial material) async {
    throw UnimplementedError();
  }

  /// Watches the I-School Plus roster (classmates) for a course offering.
  ///
  /// Emits the cached roster immediately (ordered by student ID), then triggers
  /// a background network fetch if the roster is empty or stale. The stream
  /// re-emits automatically when the DB is updated.
  ///
  /// Network errors during background refresh are absorbed — the stream
  /// continues showing stale (or empty) data rather than erroring.
  Stream<List<Student>> watchStudents(int courseOfferingId) async* {
    const ttl = Duration(days: 1);

    final query =
        _database.select(_database.courseOfferingStudents).join([
            innerJoin(
              _database.students,
              _database.students.id.equalsExp(
                _database.courseOfferingStudents.student,
              ),
            ),
          ])
          ..where(
            _database.courseOfferingStudents.courseOffering.equals(
              courseOfferingId,
            ),
          )
          ..orderBy([OrderingTerm.asc(_database.students.studentId)]);

    await for (final rows in query.watch()) {
      final students = [
        for (final row in rows) row.readTable(_database.students),
      ];

      if (students.isEmpty) {
        try {
          await refreshStudents(courseOfferingId);
        } catch (_) {
          // Absorb: yield empty below so UI exits loading state
        }
      }

      yield students;

      final offering = await (_database.select(
        _database.courseOfferings,
      )..where((o) => o.id.equals(courseOfferingId))).getSingleOrNull();
      if (offering == null) return;

      final age = switch (offering.rosterFetchedAt) {
        final t? => DateTime.now().difference(t),
        null => ttl,
      };
      if (age >= ttl) {
        try {
          await refreshStudents(courseOfferingId);
        } catch (_) {
          // Absorb: stale data is shown via stream
        }
      }
    }
  }

  /// Fetches the fresh roster from I-School Plus and writes it to the DB.
  ///
  /// The [watchStudents] stream automatically emits the updated value.
  /// Network errors propagate to the caller.
  ///
  /// Not every course-system offering exists on I-School Plus (e.g.
  /// internships, or special entries with no offering number) — these resolve
  /// to an empty roster. The fetch timestamp is recorded either way.
  Future<void> refreshStudents(int courseOfferingId) async {
    final offering = await (_database.select(
      _database.courseOfferings,
    )..where((o) => o.id.equals(courseOfferingId))).getSingleOrNull();
    if (offering == null) return;

    final number = offering.number;
    final dtos = number == null
        ? const <StudentDto>[]
        : await _authRepository.withAuth(() async {
            // Resolve the offering number to its internal I-School Plus handle.
            final courses = await _iSchoolPlusService.getCourseList();
            for (final course in courses) {
              if (course.courseNumber == number) {
                return _iSchoolPlusService.getStudents(course);
              }
            }
            // Offering not available on I-School Plus.
            return <StudentDto>[];
          }, sso: [.iSchoolPlusService]);

    await _database.transaction(() async {
      // Replace the roster for this offering.
      await (_database.delete(
        _database.courseOfferingStudents,
      )..where((s) => s.courseOffering.equals(courseOfferingId))).go();

      for (final dto in dtos) {
        // Students are keyed by their ID; skip rows missing one.
        if (dto.id case final studentId?) {
          final studentRowId = await _database.upsertStudent(
            studentId: studentId,
            name: dto.name,
          );
          await _database
              .into(_database.courseOfferingStudents)
              .insert(
                CourseOfferingStudentsCompanion.insert(
                  courseOffering: courseOfferingId,
                  student: studentRowId,
                ),
                mode: .insertOrIgnore,
              );
        }
      }

      await (_database.update(
        _database.courseOfferings,
      )..where((o) => o.id.equals(courseOfferingId))).write(
        CourseOfferingsCompanion(rosterFetchedAt: Value(DateTime.now())),
      );
    });
  }
}
