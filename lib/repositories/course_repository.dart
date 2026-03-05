// ignore_for_file: unused_field

import 'package:riverpod/riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/services/course_service.dart';
import 'package:tattoo/services/i_school_plus_service.dart';
import 'package:tattoo/services/portal_service.dart';

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
});

/// Maps `(dayOfWeek, period)` grid positions to cell data.
///
/// Only the start slot of a multi-period block has an entry; subsequent
/// slots covered by [CourseTableCell.span] are absent from the map.
typedef CourseTableData = Map<(DayOfWeek, Period), CourseTableCell>;

/// Derived layout metadata computed from [CourseTableData] keys.
///
/// Used by the course table UI to decide which rows/columns to show.
extension CourseTableMeta on CourseTableData {
  /// Whether any course falls in the morning period (before noon).
  bool hasAmCourse() => true;

  /// Whether any course falls in the afternoon period.
  bool hasPmCourse() => true;

  /// Whether any course falls in the evening period.
  bool hasNightCourse() => true;

  /// Earliest period that has a course.
  Period earliestStartSection() => .first;

  /// Latest period that has a course (accounting for span).
  Period latestEndSection() => .first;

  /// Whether any course falls on a weekday (Mon–Fri).
  bool hasWeekdayCourse() => true;

  /// Whether any course falls on Saturday.
  bool hasSatCourse() => true;

  /// Whether any course falls on Sunday.
  bool hasSunCourse() => true;

  /// Sum of credits across all distinct courses.
  double totalCredits() => 1.0;

  /// Sum of hours across all distinct courses.
  int totalHours() => 1;
}

/// Provides the [CourseRepository] instance.
final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return CourseRepository(
    portalService: ref.watch(portalServiceProvider),
    courseService: ref.watch(courseServiceProvider),
    iSchoolPlusService: ref.watch(iSchoolPlusServiceProvider),
    database: ref.watch(databaseProvider),
  );
});

/// Provides course schedules, catalog, materials, and student rosters.
///
/// ```dart
/// final repo = ref.watch(courseRepositoryProvider);
///
/// // Get available semesters
/// final semesters = await repo.getSemesters('111360109');
///
/// // Get course schedule for a semester
/// final courses = await repo.getCourseTable(
///   username: '111360109',
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

  CourseRepository({
    required PortalService portalService,
    required CourseService courseService,
    required ISchoolPlusService iSchoolPlusService,
    required AppDatabase database,
  }) : _portalService = portalService,
       _courseService = courseService,
       _iSchoolPlusService = iSchoolPlusService,
       _database = database;

  /// Gets available semesters for a student.
  ///
  /// Throws [Exception] on network failure.
  Future<List<Semester>> getSemesters(String username) async {
    throw UnimplementedError();
  }

  /// Gets the course schedule for a semester.
  ///
  /// Use [getCourseOffering] for related data (teachers, classrooms, schedules).
  ///
  /// Throws [Exception] on network failure.
  Future<CourseTableData> getCourseTable({
    required String username,
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
