// ignore_for_file: unused_field

import 'package:riverpod/riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/services/course_service.dart';
import 'package:tattoo/services/i_school_plus_service.dart';
import 'package:tattoo/services/portal_service.dart';

/// Temporary UI contract for one course entry in the course table.
///
/// Field names and types align with current database schema as much as possible
/// so repository implementation can migrate without API changes.
typedef CourseTableInfoObject = ({
  /// [CourseOfferings.number].
  String number,

  /// [Courses.nameZh].
  String? courseNameZh,

  /// [Teachers.nameZh] of this offering.
  ///
  /// A course offering can have multiple teachers.
  List<String> teacherNamesZh,

  /// [Courses.credits].
  double credits,

  /// [Courses.hours].
  int hours,

  /// [Classrooms.nameZh] of this offering.
  ///
  /// A course offering can use multiple classrooms.
  List<String> classroomNamesZh,

  /// Raw schedule format from [Schedules] table.
  ///
  /// Each entry is one `(dayOfWeek, period)` slot.
  List<({DayOfWeek dayOfWeek, Period period})> schedule,

  /// [Classes.nameZh] of this offering.
  ///
  /// A course offering can target multiple classes.
  List<String> classNamesZh,
});

/// Temporary UI contract for one renderable time block in the course table.
typedef CourseTableBlockObject = ({
  /// Course metadata shown in this block.
  CourseTableInfoObject courseInfo,

  /// Weekday of this block.
  DayOfWeek dayOfWeek,

  /// Inclusive start slot of this block.
  Period startSection,

  /// Inclusive end slot of this block.
  Period endSection,
});

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
  Future<List<CourseOffering>> getCourseTable({
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
