// ignore_for_file: unused_field

import 'dart:math';

import 'package:drift/drift.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/services/course_service.dart';
import 'package:tattoo/services/i_school_plus_service.dart';
import 'package:tattoo/services/portal_service.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/utils/fetch_with_ttl.dart';

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
    portalService: ref.watch(portalServiceProvider),
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
/// final semesters = await repo.getSemesters();
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
  final PortalService _portalService;
  final CourseService _courseService;
  final ISchoolPlusService _iSchoolPlusService;
  final AppDatabase _database;
  final AuthRepository _authRepository;

  CourseRepository({
    required PortalService portalService,
    required CourseService courseService,
    required ISchoolPlusService iSchoolPlusService,
    required AppDatabase database,
    required AuthRepository authRepository,
  }) : _portalService = portalService,
       _courseService = courseService,
       _iSchoolPlusService = iSchoolPlusService,
       _database = database,
       _authRepository = authRepository;

  /// Gets available semesters for the authenticated student.
  ///
  /// Returns cached data if fresh (within TTL). Set [refresh] to `true` to
  /// bypass TTL (pull-to-refresh).
  Future<List<Semester>> getSemesters({bool refresh = false}) async {
    final user = await _database.select(_database.users).getSingleOrNull();
    final hasOfferings = _database.select(_database.courseOfferings)
      ..where((co) => co.semester.equalsExp(_database.semesters.id));
    final cached =
        await (_database.select(_database.semesters)
              ..where((_) => existsQuery(hasOfferings))
              ..orderBy([
                (s) => OrderingTerm.desc(s.year),
                (s) => OrderingTerm.desc(s.term),
              ]))
            .get();

    return fetchWithTtl(
      cached: cached.isEmpty ? null : cached,
      getFetchedAt: (_) => user?.semestersFetchedAt,
      fetchFromNetwork: _fetchSemestersFromNetwork,
      refresh: refresh,
    );
  }

  Future<List<Semester>> _fetchSemestersFromNetwork() async {
    final dtos = await _authRepository.withAuth(() async {
      await _portalService.sso(.courseService);
      return _courseService.getCourseSemesterList();
    });

    final semesters = await dtos.map((dto) async {
      if (dto case (year: final year?, term: final term?)) {
        final id = await _database.getOrCreateSemester(year, term);
        return Semester(id: id, year: year, term: term);
      }
    }).wait;

    await (_database.update(_database.users)).write(
      UsersCompanion(semestersFetchedAt: Value(DateTime.now())),
    );

    return semesters.nonNulls.toList();
  }

  /// Gets the course schedule for a semester.
  ///
  /// Use [getCourseOffering] for related data (teachers, classrooms, schedules).
  ///
  /// Throws [Exception] on network failure.
  Future<CourseTableData> getCourseTable({
    required User user,
    required Semester semester,
  }) async {
    throw UnimplementedError();
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
