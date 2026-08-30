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

/// A submitted syllabus and its ordered dynamic content sections.
typedef SyllabusDetail = ({
  Syllabus metadata,
  List<SyllabusSection> sections,
});

/// A submitted syllabus paired with its authoring teacher.
typedef TeacherSyllabusDetail = ({
  ({String code, String nameZh, String? nameEn}) teacher,
  SyllabusDetail syllabus,
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
  /// + classes), selected by its course number (課號) and composed from the
  /// database — no network. Submitted syllabuses are fetched separately via
  /// [watchSyllabuses]. Emits `null` when the offering is missing; re-emits when
  /// a syllabus refresh writes the offering's header fields.
  ///
  /// Course numbers are globally unique and identify at most one offering.
  Stream<CourseOfferingDetail?> watchCourseOffering(String number) async* {
    final overviews = _database.courseOfferingOverviews;
    final query =
        _database.select(overviews).join([
            innerJoin(
              _database.semesters,
              _database.semesters.id.equalsExp(overviews.semester),
            ),
          ])
          ..where(overviews.number.equals(number))
          ..orderBy([
            .desc(_database.semesters.year),
            .desc(_database.semesters.term),
          ])
          ..limit(1);

    await for (final rows in query.watch()) {
      final overview = rows.firstOrNull?.readTable(overviews);
      if (overview == null) {
        yield null;
        continue;
      }

      yield await _readCourseOfferingDetail(overview);
    }
  }

  Future<CourseOfferingDetail> _readCourseOfferingDetail(
    CourseOfferingOverview overview,
  ) async {
    final offeringId = overview.id;
    final (schedule, teachers, classes) = await (
      _readOfferingSchedule(offeringId),
      _readOfferingTeachers(offeringId),
      _readOfferingClasses(offeringId),
    ).wait;

    return (
      overview: overview,
      schedule: schedule,
      teachers: teachers,
      classes: classes,
    );
  }

  /// Watches every submitted [language] syllabus for the offering identified
  /// by [courseNumber].
  ///
  /// Emits a non-empty cached aggregate immediately. Missing or stale cache
  /// entries are fetched before the first emission when no teacher has a
  /// submitted syllabus, or revalidated after cached submissions are emitted.
  /// Unsubmitted syllabuses retain cache metadata but are omitted from results.
  /// Refresh failures are absorbed so stale data remains visible and an empty
  /// list leaves loading.
  /// Missing offerings and offerings without teachers emit an empty list
  /// without making a request.
  Stream<List<TeacherSyllabusDetail>> watchSyllabuses({
    required String courseNumber,
    required SyllabusLanguage language,
  }) async* {
    const ttl = Duration(minutes: 15);

    final context = await _readSyllabusContext(courseNumber);
    if (context == null || context.teachers.isEmpty) {
      yield [];
      return;
    }

    final offering = context.offering;
    final associatedTeachers = context.teachers;

    final teacherIds = associatedTeachers
        .map((entry) => entry.teacher.id)
        .toList();
    final syllabuses = _database.syllabuses;
    final sections = _database.syllabusSections;
    final teachers = _database.teachers;
    final query =
        _database.select(syllabuses).join([
            innerJoin(teachers, teachers.id.equalsExp(syllabuses.teacher)),
            leftOuterJoin(
              sections,
              sections.syllabus.equalsExp(syllabuses.id),
            ),
          ])
          ..where(
            syllabuses.courseOffering.equals(offering.id) &
                syllabuses.teacher.isIn(teacherIds) &
                syllabuses.language.equalsValue(language),
          )
          ..orderBy([
            .asc(teachers.code),
            .asc(sections.position),
          ]);

    var attemptedRefresh = false;
    await for (final rows in query.watch()) {
      final details = _mapSyllabusRows(rows);
      final cachedByTeacher = {
        for (final row in rows)
          row.readTable(_database.syllabuses).teacher: row.readTable(
            _database.syllabuses,
          ),
      };
      final now = DateTime.now();
      final needsRefresh = associatedTeachers.any((associatedTeacher) {
        final cached = cachedByTeacher[associatedTeacher.teacher.id];
        return cached == null || now.difference(cached.fetchedAt) >= ttl;
      });

      if (details.isEmpty) {
        if (needsRefresh && !attemptedRefresh) {
          attemptedRefresh = true;
          try {
            await refreshSyllabuses(
              courseNumber: courseNumber,
              language: language,
            );
            yield _mapSyllabusRows(await query.get());
            continue;
          } catch (_) {
            // Absorb: yield an empty list so the UI exits its loading state.
          }
        }
        yield [];
        continue;
      }

      yield details;

      if (needsRefresh && !attemptedRefresh) {
        attemptedRefresh = true;
        try {
          await refreshSyllabuses(
            courseNumber: courseNumber,
            language: language,
          );
        } catch (_) {
          // Absorb: the cached details emitted above remain visible.
        }
      }
    }
  }

  List<TeacherSyllabusDetail> _mapSyllabusRows(List<TypedResult> rows) {
    final grouped =
        <
          int,
          ({
            Syllabus metadata,
            Teacher teacher,
            List<SyllabusSection> sections,
          })
        >{};

    for (final row in rows) {
      final metadata = row.readTable(_database.syllabuses);
      final teacher = row.readTable(_database.teachers);
      final section = row.readTableOrNull(_database.syllabusSections);
      final aggregate = grouped.putIfAbsent(
        metadata.id,
        () => (metadata: metadata, teacher: teacher, sections: []),
      );
      if (section case final section?) {
        aggregate.sections.add(section);
      }
    }

    return [
      for (final aggregate in grouped.values)
        if (aggregate.metadata.updatedAt != null &&
            aggregate.sections.any(
              (section) => section.content?.trim().isNotEmpty ?? false,
            ))
          (
            teacher: (
              code: aggregate.teacher.code,
              nameZh: aggregate.teacher.nameZh,
              nameEn: aggregate.teacher.nameEn,
            ),
            syllabus: (
              metadata: aggregate.metadata,
              sections: aggregate.sections,
            ),
          ),
    ];
  }

  /// Fetches every associated teacher's [language] syllabus for the offering
  /// identified by [courseNumber] and persists the complete result atomically.
  ///
  /// Responses without a last-updated timestamp or any non-blank section
  /// content are treated as unsubmitted: their sections are removed while a
  /// metadata row retains the fetch timestamp for TTL caching. Submitted
  /// metadata and ordered sections are upserted, instructor emails are written
  /// to [TeacherSemesters], and shared header fields are copied from the first
  /// submitted response. Missing offerings and offerings without teachers are
  /// no-ops; network errors propagate without writes.
  Future<void> refreshSyllabuses({
    required String courseNumber,
    required SyllabusLanguage language,
  }) async {
    final context = await _readSyllabusContext(courseNumber);
    if (context == null || context.teachers.isEmpty) return;

    final offering = context.offering;
    final teachers = context.teachers;

    final results = await _authRepository.withAuth(
      () => Future.wait([
        for (final teacher in teachers)
          _courseService
              .getSyllabus(
                courseNumber: courseNumber,
                teacherId: teacher.teacher.code,
                language: language,
              )
              .then((syllabus) => (teacher: teacher, syllabus: syllabus)),
      ]),
      sso: [.courseService],
    );

    await _database.transaction(() async {
      final fetchedAt = DateTime.now();

      for (final result in results) {
        final teacher = result.teacher.teacher;
        final teacherSemester = result.teacher.teacherSemester;
        final syllabus = result.syllabus;

        if (syllabus == null ||
            syllabus.lastUpdated == null ||
            !syllabus.sections.any(
              (section) => section.content?.trim().isNotEmpty ?? false,
            )) {
          final storedSyllabus = await _database
              .into(_database.syllabuses)
              .insertReturning(
                SyllabusesCompanion.insert(
                  courseOffering: offering.id,
                  teacher: teacher.id,
                  language: language,
                  fetchedAt: fetchedAt,
                ),
                onConflict: DoUpdate(
                  (_) => SyllabusesCompanion(
                    updatedAt: const Value(null),
                    fetchedAt: Value(fetchedAt),
                  ),
                  target: [
                    _database.syllabuses.courseOffering,
                    _database.syllabuses.teacher,
                    _database.syllabuses.language,
                  ],
                ),
              );
          await (_database.delete(_database.syllabusSections)..where(
                (section) => section.syllabus.equals(storedSyllabus.id),
              ))
              .go();
          continue;
        }

        final storedSyllabus = await _database
            .into(_database.syllabuses)
            .insertReturning(
              SyllabusesCompanion.insert(
                courseOffering: offering.id,
                teacher: teacher.id,
                language: language,
                updatedAt: Value(syllabus.lastUpdated),
                fetchedAt: fetchedAt,
              ),
              onConflict: DoUpdate(
                (_) => SyllabusesCompanion(
                  updatedAt: Value(syllabus.lastUpdated),
                  fetchedAt: Value(fetchedAt),
                ),
                target: [
                  _database.syllabuses.courseOffering,
                  _database.syllabuses.teacher,
                  _database.syllabuses.language,
                ],
              ),
            );

        await (_database.delete(_database.syllabusSections)..where(
              (section) => section.syllabus.equals(storedSyllabus.id),
            ))
            .go();
        await _database.batch((batch) {
          batch.insertAll(_database.syllabusSections, [
            for (final (position, section) in syllabus.sections.indexed)
              SyllabusSectionsCompanion.insert(
                syllabus: storedSyllabus.id,
                title: section.title,
                content: Value(section.content),
                position: position,
              ),
          ]);
        });

        await (_database.update(
          _database.teacherSemesters,
        )..where((stored) => stored.id.equals(teacherSemester.id))).write(
          TeacherSemestersCompanion(email: Value(syllabus.email)),
        );
      }

      final firstSubmitted = results
          .map((result) => result.syllabus)
          .nonNulls
          .where(
            (syllabus) =>
                syllabus.lastUpdated != null &&
                syllabus.sections.any(
                  (section) => section.content?.trim().isNotEmpty ?? false,
                ),
          )
          .firstOrNull;
      if (firstSubmitted case final firstSubmitted?) {
        await (_database.update(
          _database.courseOfferings,
        )..where((stored) => stored.id.equals(offering.id))).write(
          CourseOfferingsCompanion(
            courseType: Value(firstSubmitted.type),
            enrolled: Value(firstSubmitted.enrolled),
            withdrawn: Value(firstSubmitted.withdrawn),
            fetchedAt: Value(fetchedAt),
          ),
        );
      }
    });
  }

  Future<
    ({
      CourseOffering offering,
      List<
        ({
          Teacher teacher,
          TeacherSemester teacherSemester,
        })
      >
      teachers,
    })?
  >
  _readSyllabusContext(String number) async {
    final offerings = _database.courseOfferings;
    final offeringTeachers = _database.courseOfferingTeachers;
    final teacherSemesters = _database.teacherSemesters;
    final teachers = _database.teachers;
    final query =
        _database.select(offerings).join([
            leftOuterJoin(
              offeringTeachers,
              offeringTeachers.courseOffering.equalsExp(offerings.id),
            ),
            leftOuterJoin(
              teacherSemesters,
              teacherSemesters.id.equalsExp(
                offeringTeachers.teacherSemester,
              ),
            ),
            leftOuterJoin(
              teachers,
              teachers.id.equalsExp(teacherSemesters.teacher),
            ),
          ])
          ..where(offerings.number.equals(number))
          ..orderBy([.asc(teachers.code)]);
    final rows = await query.get();
    final offering = rows.firstOrNull?.readTable(offerings);
    if (offering == null) return null;

    return (
      offering: offering,
      teachers: [
        for (final row in rows)
          if ((
                row.readTableOrNull(teachers),
                row.readTableOrNull(teacherSemesters),
              )
              case (final teacher?, final teacherSemester?))
            (teacher: teacher, teacherSemester: teacherSemester),
      ],
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

  /// Gets students enrolled in a course from I-School Plus.
  ///
  /// Throws [Exception] on network failure.
  Future<List<Student>> getStudents(CourseOffering courseOffering) async {
    throw UnimplementedError();
  }
}
