// ignore_for_file: unused_field

import 'dart:math';

import 'package:drift/drift.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/models/classroom.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/services/course/course_service.dart';
import 'package:tattoo/services/i_school_plus/i_school_plus_service.dart';
import 'package:tattoo/services/portal/portal_service.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/services/firebase_service.dart';
import 'package:tattoo/utils/localized.dart';

/// Data for a single cell in the course table grid.
typedef CourseTableCellData = ({
  /// [CourseOfferings] primary key, for navigating to detail view.
  int id,

  /// [CourseOfferings.number].
  String number,

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

/// Maps `(dayOfWeek, period)` grid positions to cell data.
///
/// Only the start slot of a multi-period block has an entry; subsequent
/// slots covered by [CourseTableCellData.span] are absent from the map.
typedef CourseTableData =
    Map<({DayOfWeek day, Period period}), CourseTableCellData>;

/// A single key–value pair from [CourseTableData].
typedef CourseTableEntry =
    MapEntry<({DayOfWeek day, Period period}), CourseTableCellData>;

extension on CourseTableEntry {
  /// All [Period]s this entry occupies, accounting for [CourseTableCellData.span]
  /// and skipping noon when [CourseTableCellData.crossesNoon] is true.
  Iterable<Period> get periods {
    final noonIndex = Period.nPeriod.index;
    final start = key.period.index;
    return List.generate(value.span, (i) {
      final raw = start + i;
      return Period.values[raw >= noonIndex && value.crossesNoon
          ? raw + 1
          : raw];
    });
  }
}

/// Derived layout metadata computed from [CourseTableData] keys.
///
/// Used by the course table UI to decide which rows/columns to show.
extension CourseTableMeta on CourseTableData {
  /// Whether any course falls on a weekday (Mon-Fri).
  bool get hasWeekdayCourse => keys.any((s) => s.day.isWeekday);

  /// Whether any course falls on Saturday.
  bool get hasSaturdayCourse => keys.any((s) => s.day == DayOfWeek.saturday);

  /// Whether any course falls on Sunday.
  bool get hasSundayCourse => keys.any((s) => s.day == DayOfWeek.sunday);

  /// Whether any course falls in the morning period (1-4).
  bool get hasAMCourse => entries.any((e) => e.periods.any((p) => p.isAM));

  /// Whether any course falls in the afternoon period (5-9).
  bool get hasPMCourse => entries.any((e) => e.periods.any((p) => p.isPM));

  /// Whether any course falls in the noon period (N).
  bool get hasNoonCourse =>
      entries.any((e) => e.periods.any((p) => p == Period.nPeriod));

  /// Whether any course falls in the evening period (A-D).
  bool get hasEveningCourse =>
      entries.any((e) => e.periods.any((p) => p.isEvening));

  /// Earliest period that has a course, or null if empty.
  Period? get earliestPeriod => isEmpty
      ? null
      : Period.values[keys.map((s) => s.period.index).reduce(min)];

  /// Latest period that has a course (accounting for span), or null if empty.
  Period? get latestPeriod => isEmpty
      ? null
      : entries
            .expand((e) => e.periods)
            .reduce((a, b) => a.index > b.index ? a : b);

  /// Unique courses by number, for aggregation.
  Iterable<CourseTableCellData> get _uniqueCourses {
    final seen = <String>{};
    return values.where((cell) => seen.add(cell.number));
  }

  /// Sum of credits across all distinct courses.
  double get totalCredits =>
      _uniqueCourses.fold(0.0, (sum, cell) => sum + cell.credits);

  /// Sum of hours across all distinct courses.
  int get totalHours => _uniqueCourses.fold(0, (sum, cell) => sum + cell.hours);
}

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
    required PortalService portalService,
    required CourseService courseService,
    required ISchoolPlusService iSchoolPlusService,
    required AppDatabase database,
    required AuthRepository authRepository,
    required FirebaseService firebaseService,
  }) : _portalService = portalService,
       _courseService = courseService,
       _iSchoolPlusService = iSchoolPlusService,
       _database = database,
       _authRepository = authRepository,
       _firebaseService = firebaseService;

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
      for (final dto in dtos) {
        if (dto case (year: final year?, term: final term?)) {
          await _database.getOrCreateSemester(
            year,
            term,
            inCourseSemesterList: true,
          );
        }
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
  /// Use [getCourseOffering] for related data (teachers, classrooms, schedules).
  Stream<CourseTableData> watchCourseTable({
    required Semester semester,
  }) async* {
    const ttl = Duration(days: 3);

    final query = _database.select(_database.courseTableSlots)
      ..where((s) => s.semester.equals(semester.id));

    await for (final rows in query.watch()) {
      final data = _buildCourseTableData(rows);

      if (data.isEmpty) {
        try {
          await refreshCourseTable(semester: semester);
        } catch (_) {
          // Absorb: yield empty below so UI exits loading state
        }
      }

      yield data;

      final semesterRow = await (_database.select(
        _database.semesters,
      )..where((s) => s.id.equals(semester.id))).getSingle();
      final age = switch (semesterRow.courseTableFetchedAt) {
        final t? => DateTime.now().difference(t),
        null => ttl,
      };
      if (age >= ttl) {
        try {
          await refreshCourseTable(semester: semester);
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
  Future<void> refreshCourseTable({
    required Semester semester,
  }) async {
    final user = await _database.select(_database.users).getSingle();

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
      // Remove offerings no longer in the response (e.g. dropped courses).
      // Junction/child rows are cascade-deleted by FK constraints.
      await (_database.delete(_database.courseOfferings)..where(
            (o) =>
                o.semester.equals(semester.id) & o.number.isNotIn(freshNumbers),
          ))
          .go();

      for (final dto in dtos) {
        if (dto.number == null) continue;
        final courseId = dto.course?.id;
        final courseNameZh = dto.course?.nameZh;
        if (courseId == null || courseNameZh == null) {
          _firebaseService.recordNonFatal(
            'Skipped offering with incomplete course data: '
            'number=${dto.number}, courseId=$courseId, '
            'courseNameZh=$courseNameZh',
          );
          continue;
        }

        if (dto.credits == null || dto.hours == null) {
          _firebaseService.recordNonFatal(
            'Course $courseId missing credits/hours: '
            'credits=${dto.credits}, hours=${dto.hours}',
          );
        }

        final dbCourseId = await _database.upsertCourse(
          code: courseId,
          credits: dto.credits ?? 0,
          hours: dto.hours ?? 0,
          nameZh: courseNameZh,
          nameEn: dto.course?.nameEn,
        );

        final offeringId = await _database.upsertCourseOffering(
          courseId: dbCourseId,
          semesterId: semester.id,
          number: dto.number!,
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

        // Teacher
        if (dto.teacher case LocalizedRefDto(:final id?, :final nameZh?)) {
          final teacherSemesterId = await _database.upsertTeacherSemester(
            code: id,
            semesterId: semester.id,
            nameZh: nameZh,
            nameEn: dto.teacher?.nameEn,
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
                  StackTrace.current,
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

  /// Builds [CourseTableData] from raw view rows, computing multi-period spans.
  static CourseTableData _buildCourseTableData(List<CourseTableSlot> rows) {
    final data = CourseTableData();

    for (final row in rows) {
      final key = (day: row.dayOfWeek, period: row.period);
      if (data.containsKey(key)) continue;

      data[key] = (
        id: row.id,
        number: row.number,
        span: 1,
        crossesNoon: false,
        courseName: localized(row.nameZh, row.nameEn),
        classroomName: switch ((row.classroomNameZh, row.classroomNameEn)) {
          (final zh?, final en) => localized(zh, en),
          _ => null,
        },
        credits: row.credits,
        hours: row.hours,
      );
    }

    // Compute spans: for each slot, look ahead at consecutive periods on the
    // same day. Matching offerings are tracked in a consumed set, and the
    // starting slot gets the total span. Consumed slots are removed at the end.
    //
    // When no course occupies the noon period on any day, courses that span
    // across noon (e.g. period 4 → 5) are merged. The noon period is skipped
    // (not counted in span) and crossesNoon is set for UI height calculation.
    final hasNoon = data.keys.any((s) => s.period == Period.nPeriod);
    final consumed = <({DayOfWeek day, Period period})>{};
    for (final entry in data.entries) {
      if (consumed.contains(entry.key)) continue;
      var span = 1;
      var crossesNoon = false;
      var lookIndex = entry.key.period.index + 1;
      while (lookIndex < Period.values.length) {
        final nextPeriod = Period.values[lookIndex];
        // Skip noon if no courses use it
        if (nextPeriod == Period.nPeriod && !hasNoon) {
          lookIndex++;
          continue;
        }
        final nextKey = (day: entry.key.day, period: nextPeriod);
        if (data[nextKey] case final next? when next.id == entry.value.id) {
          consumed.add(nextKey);
          span++;
          crossesNoon = entry.key.period.isAM && nextPeriod.isPM;
          lookIndex++;
        } else {
          break;
        }
      }
      if (span > 1 || crossesNoon) {
        data[entry.key] = (
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
    data.removeWhere((key, _) => consumed.contains(key));

    return data;
  }

  /// Gets a course offering with related data (teachers, classrooms, schedules).
  ///
  /// Returns `null` if not found.
  Future<CourseOffering?> getCourseOffering(int id) async {
    throw UnimplementedError();
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

  /// Gets detailed course catalog information.
  ///
  /// Throws [Exception] on network failure.
  Future<Course> getCourseDetails(String courseId) async {
    throw UnimplementedError();
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
  /// The returned [MaterialDto.referer] must be included as a Referer header
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
