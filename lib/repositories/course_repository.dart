import 'dart:math';

import 'package:drift/drift.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/services/course_service.dart';
import 'package:tattoo/services/i_school_plus_service.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/utils/fetch_with_ttl.dart';
import 'package:tattoo/utils/localized.dart';

/// Data for a single cell in the course table grid.
typedef CourseTableCell = ({
  /// [CourseOfferings] primary key, for navigating to detail view.
  int id,

  /// [CourseOfferings.number].
  String number,

  /// Number of consecutive period rows this cell spans.
  int span,

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
/// slots covered by [CourseTableCell.span] are absent from the map.
typedef CourseTableData =
    Map<({DayOfWeek day, Period period}), CourseTableCell>;

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
  bool get hasAMCourse => keys.any((s) => s.period.isAM);

  /// Whether any course falls in the afternoon period (5-9).
  bool get hasPMCourse => keys.any((s) => s.period.isPM);

  /// Whether any course falls in the noon period (N).
  bool get hasNoonCourse => keys.any((s) => s.period == Period.nPeriod);

  /// Whether any course falls in the evening period (A-D).
  bool get hasEveningCourse => keys.any((s) => s.period.isEvening);

  /// Earliest period that has a course, or null if empty.
  Period? get earliestPeriod => isEmpty
      ? null
      : Period.values[keys.map((s) => s.period.index).reduce(min)];

  /// Latest period that has a course (accounting for span), or null if empty.
  Period? get latestPeriod => isEmpty
      ? null
      : Period.values[entries
            .map((e) => e.key.period.index + e.value.span - 1)
            .reduce(max)];

  /// Unique courses by number, for aggregation.
  Iterable<CourseTableCell> get _uniqueCourses {
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
  return CourseRepository(
    courseService: ref.watch(courseServiceProvider),
    iSchoolPlusService: ref.watch(iSchoolPlusServiceProvider),
    database: ref.watch(databaseProvider),
    authRepository: ref.watch(authRepositoryProvider),
  );
});

/// Provides course schedules, catalog, materials, and student rosters.
///
/// ```dart
/// final repo = ref.watch(courseRepositoryProvider);
///
/// // Get available semesters
/// final semesters = await repo.getSemesters(user);
///
/// // Get course schedule for a semester
/// final courses = await repo.getCourseTable(
///   user: user,
///   semester: semesters.first,
/// );
///
/// // Get materials for a course
/// final materials = await repo.getMaterials(courses.first);
/// ```
class CourseRepository {
  final CourseService _courseService;
  // ignore: unused_field
  final ISchoolPlusService _iSchoolPlusService;
  final AppDatabase _database;
  final AuthRepository _authRepository;

  CourseRepository({
    required CourseService courseService,
    required ISchoolPlusService iSchoolPlusService,
    required AppDatabase database,
    required AuthRepository authRepository,
  }) : _courseService = courseService,
       _iSchoolPlusService = iSchoolPlusService,
       _database = database,
       _authRepository = authRepository;

  /// Gets available semesters for a student.
  Future<List<Semester>> getSemesters(User user) async {
    final dtos = await _authRepository.withAuth(
      () => _courseService.getCourseSemesterList(user.studentId),
    );

    final semesters = await Future.wait(
      dtos.map((dto) async {
        if (dto case (year: final year?, term: final term?)) {
          final id = await _database.getOrCreateSemester(year, term);
          return Semester(id: id, year: year, term: term);
        }
      }),
    );

    return semesters.nonNulls.toList();
  }

  /// Gets the course schedule for a semester.
  ///
  /// Returns cached data if fresh (within TTL). Set [refresh] to `true` to
  /// bypass TTL (pull-to-refresh).
  ///
  /// Use [getCourseOffering] for related data (teachers, classrooms, schedules).
  Future<CourseTableData> getCourseTable({
    required User user,
    required Semester semester,
    bool refresh = false,
  }) async {
    final cached = await _buildCourseTableData(semester.id);

    return fetchWithTtl(
      cached: cached.isEmpty ? null : cached,
      getFetchedAt: (_) => semester.courseTableFetchedAt,
      fetchFromNetwork: () => _fetchCourseTableFromNetwork(user, semester),
      refresh: refresh,
    );
  }

  Future<CourseTableData> _fetchCourseTableFromNetwork(
    User user,
    Semester semester,
  ) async {
    final dtos = await _authRepository.withAuth(
      () => _courseService.getCourseTable(
        username: user.studentId,
        semester: (year: semester.year, term: semester.term),
      ),
    );

    final freshNumbers = dtos.map((d) => d.number).nonNulls.toSet();

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
        if (courseId == null || courseNameZh == null) continue;

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
          final teacherId = await _database.upsertTeacher(
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
                  teacher: teacherId,
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
              classroomId = await _database.upsertClassroom(
                code: id,
                nameZh: name,
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

    return _buildCourseTableData(semester.id);
  }

  Future<CourseTableData> _buildCourseTableData(int semesterId) async {
    final rows = await (_database.select(
      _database.courseTableSlots,
    )..where((s) => s.semester.equals(semesterId))).get();
    final data = CourseTableData();

    for (final row in rows) {
      final key = (day: row.dayOfWeek, period: row.period);
      if (data.containsKey(key)) continue;

      data[key] = (
        id: row.id,
        number: row.number,
        span: 1,
        courseName: localized(row.nameZh, row.nameEn),
        classroomName: row.classroomNameZh,
        credits: row.credits,
        hours: row.hours,
      );
    }

    // Compute spans: for each slot, look ahead at consecutive periods on the
    // same day. Matching courses get marked span=0 (consumed), and the starting
    // slot gets the total span. Consumed slots are removed at the end.
    for (final entry in data.entries.toList()) {
      if (entry.value.span == 0) continue;
      var span = 1;
      while (true) {
        final nextPeriodIndex = entry.key.period.index + span;
        if (nextPeriodIndex >= Period.values.length) break;
        final nextKey = (
          day: entry.key.day,
          period: Period.values[nextPeriodIndex],
        );
        if (data[nextKey] case final next?
            when next.number == entry.value.number) {
          data[nextKey] = (
            id: next.id,
            number: next.number,
            span: 0,
            courseName: next.courseName,
            classroomName: next.classroomName,
            credits: next.credits,
            hours: next.hours,
          );
          span++;
        } else {
          break;
        }
      }
      if (span > 1) {
        data[entry.key] = (
          id: entry.value.id,
          number: entry.value.number,
          span: span,
          courseName: entry.value.courseName,
          classroomName: entry.value.classroomName,
          credits: entry.value.credits,
          hours: entry.value.hours,
        );
      }
    }

    // Remove consumed slots (span == 0)
    data.removeWhere((_, cell) => cell.span == 0);

    return data;
  }

  /// Gets a course offering with related data (teachers, classrooms, schedules).
  ///
  /// Returns `null` if not found.
  Future<CourseOffering?> getCourseOffering(int id) async {
    throw UnimplementedError();
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
  Future<List<Material>> getMaterials(CourseOffering courseOffering) async {
    throw UnimplementedError();
  }

  /// Gets the download URL for a material.
  ///
  /// The returned [MaterialDto.referer] must be included as a Referer header
  /// when downloading, if non-null.
  ///
  /// Throws [Exception] on network failure.
  /// Throws [UnimplementedError] for course recordings (not yet supported).
  Future<MaterialDto> getMaterialDownload(Material material) async {
    throw UnimplementedError();
  }

  /// Gets students enrolled in a course from I-School Plus.
  ///
  /// Throws [Exception] on network failure.
  Future<List<Student>> getStudents(CourseOffering courseOffering) async {
    throw UnimplementedError();
  }
}
