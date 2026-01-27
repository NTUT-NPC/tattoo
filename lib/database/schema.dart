/// Database schema definitions for Tattoo.
///
/// This file defines the complete database structure for storing:
/// - User accounts and student profiles
/// - Course catalog and semester offerings
/// - Class schedules and time slots
/// - Teachers, classrooms, and class (系級) information
/// - Student enrollments and course materials
///
/// The schema is designed to support offline-first operation with periodic
/// sync from NTUT's various web services (Portal, CourseService, I-School Plus).
library;

import 'package:drift/drift.dart';
import 'package:tattoo/models/course.dart';

/// Mixin for tables that use an auto-incrementing integer primary key.
mixin AutoIncrementId on Table {
  /// Auto-incrementing primary key.
  late final id = integer().autoIncrement()();
}

/// Mixin for tables that support incremental data fetching.
///
/// NTUT pages often provide partial information about related entities.
/// For example, the course schedule table shows teacher names and IDs,
/// but not their complete profile information.
///
/// This mixin enables a two-stage fetch pattern:
/// 1. Initial fetch: Insert row with basic info, `fetchedAt = null` (partial data)
/// 2. Detail fetch: Update row with complete info, set `fetchedAt = now()` (full data)
///
/// The `fetchedAt` field serves dual purposes:
/// - **Completeness indicator**: null = partial data, non-null = complete data
/// - **Cache invalidation**: timestamp indicates when complete data was last fetched
mixin Fetchable on Table {
  /// Timestamp of when complete data was last fetched from the server.
  ///
  /// - `null`: Only partial/basic information is available (e.g., name + ID from a list page)
  /// - `non-null`: Complete details have been fetched (e.g., full profile from detail page)
  ///
  /// Use this field to:
  /// - Determine if a detail fetch is needed (null = need to fetch)
  /// - Implement cache expiration (old timestamp = stale, re-fetch)
  late final fetchedAt = dateTime().nullable()();
}

// Base Tables
// -----------

/// Student information.
///
/// Represents students enrolled at NTUT. Data can be fetched from:
/// - Portal profiles
/// - I-School Plus student leaderboards
class Students extends Table with AutoIncrementId {
  /// Unique student ID (學號).
  late final studentId = text().unique()();

  /// Student's name.
  late final name = text()();
}

/// Academic semester information.
///
/// Represents an academic term at NTUT (e.g., 114-1 for Fall 2025).
class Semesters extends Table with AutoIncrementId {
  /// Academic year in ROC calendar (e.g., 114 for 2025).
  late final year = integer()();

  /// Semester number within the year (1=Fall, 2=Spring).
  late final semester = integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {year, semester},
  ];
}

/// Course catalog information.
///
/// Represents the permanent course definition independent of semester offerings.
/// Data is typically fetched from course catalog pages.
class Courses extends Table with AutoIncrementId, Fetchable {
  /// Unique course code (e.g., "CS101", "MATH2001").
  late final code = text().unique()();

  /// Number of credits awarded for completing this course.
  late final credits = real()();

  /// Number of class hours per week.
  late final hours = integer()();

  /// Course name in English.
  late final nameEn = text().nullable()();

  /// Course name in Traditional Chinese.
  late final nameZh = text().nullable()();

  /// Course description in English.
  late final descriptionEn = text().nullable()();

  /// Course description in Traditional Chinese.
  late final descriptionZh = text().nullable()();
}

/// Teacher/instructor information in a particular semester.
class Teachers extends Table with AutoIncrementId, Fetchable {
  /// Unique teacher code/ID in the NTUT system.
  late final code = text().unique()();

  /// Teacher's name in Traditional Chinese.
  late final nameZh = text()();

  // TODO: Add email field (available from syllabus page)
  // TextColumn get email = text().nullable()();

  // TODO: Add additional teacher details (office, phone, office hours)
}

/// Student class/major (系級) in a particular semester.
///
/// Represents academic departments and year levels (e.g., "電子四甲").
class Classes extends Table with AutoIncrementId, Fetchable {
  /// Unique class code in the NTUT system.
  late final code = text().unique()();

  /// Class name in Traditional Chinese (e.g., "電子四甲").
  late final nameZh = text().unique()();
}

/// Classroom/location information in a particular semester.
///
/// Represents physical classrooms where courses are held.
class Classrooms extends Table with AutoIncrementId, Fetchable {
  /// Unique classroom code in the NTUT system.
  late final code = text().unique()();

  /// Classroom name/location in Traditional Chinese (e.g., "共同大樓 101").
  late final nameZh = text()();

  // TODO: Add fields for full name, floor, capacity, usage
}

// Tables with foreign keys to base tables
// ---------------------------------------

/// User account information from the NTUT portal.
///
/// Represents the authenticated user's account details and profile.
class Users extends Table with AutoIncrementId {
  /// Reference to the student record associated with this user account.
  late final student = integer().references(Students, #id)();

  /// Filename of the user's avatar image stored locally.
  late final avatarFilename = text()();

  /// User's email address.
  late final email = text()();

  /// Number of days until the user's password expires.
  ///
  /// Null if password expiration is not enforced or unknown.
  late final passwordExpiresInDays = integer().nullable()();
}

/// Specific offering of a course in a particular semester.
///
/// Represents a course section (班級) in a specific semester with its
/// schedule, teachers, and enrollment information.
@TableIndex(name: 'semester_course_offerings', columns: {#semester})
class CourseOfferings extends Table with AutoIncrementId, Fetchable {
  /// Reference to the course definition.
  late final course = integer().references(Courses, #id)();

  /// Reference to the semester when this course is offered.
  late final semester = integer().references(Semesters, #id)();

  /// Unique course offering number/section identifier (e.g., "CS101-01").
  late final number = text().unique()();

  /// Course sequence phase/stage number (階段, e.g., "1", "2").
  ///
  /// For multi-part courses like 物理 with the same name. Some courses
  /// encode the sequence in the name instead (e.g., 英文溝通與應用(一)).
  late final phase = text()();

  /// Type of course (required/elective/general).
  late final courseType = textEnum<CourseType>()();

  /// Enrollment status (e.g., "撤選").
  late final status = text().nullable()();

  /// Language of instruction (e.g., "英語").
  late final language = text().nullable()();

  /// Additional remarks or notes about this offering.
  late final remarks = text().nullable()();

  /// Syllabus ID for fetching detailed syllabus information.
  ///
  /// TODO: Add fields for syllabus details (objectives, textbooks, grading).
  late final syllabusId = text().nullable()();
}

// Junction tables and dependent tables
// ------------------------------------

/// Junction table linking course offerings to their instructors.
///
/// Supports multiple teachers per course offering (team teaching).
class CourseOfferingTeachers extends Table {
  /// Reference to the course offering.
  late final courseOffering = integer().references(CourseOfferings, #id)();

  /// Reference to the teacher.
  late final teacher = integer().references(Teachers, #id)();

  @override
  Set<Column> get primaryKey => {courseOffering, teacher};
}

/// Junction table linking course offerings to the classes they're intended for.
///
/// A course offering may target multiple classes (e.g., shared courses).
class CourseOfferingClasses extends Table {
  /// Reference to the course offering.
  late final courseOffering = integer().references(CourseOfferings, #id)();

  /// Reference to the class/major.
  late final classEntity = integer().references(Classes, #id)();

  @override
  Set<Column> get primaryKey => {courseOffering, classEntity};
}

/// Junction table linking course offerings to their classrooms.
///
/// Note: Current design maps classrooms to entire course offerings.
/// TODO: Consider adding classroom FK to Schedules instead for per-timeslot
/// classroom mapping, as some courses may use different rooms for different sessions.
class CourseOfferingClassrooms extends Table {
  /// Reference to the course offering.
  late final courseOffering = integer().references(CourseOfferings, #id)();

  /// Reference to the classroom.
  late final classroom = integer().references(Classrooms, #id)();

  @override
  Set<Column> get primaryKey => {courseOffering, classroom};
}

/// Junction table linking course offerings to enrolled students.
///
/// Represents the enrollment/roster for each course section.
class CourseOfferingStudents extends Table {
  /// Reference to the course offering.
  late final courseOffering = integer().references(CourseOfferings, #id)();

  /// Reference to the student.
  late final student = integer().references(Students, #id)();

  @override
  Set<Column> get primaryKey => {courseOffering, student};
}

/// Class schedule time slots for course offerings.
///
/// Each record represents one time slot (day + period) for a course offering.
/// A course that meets multiple times per week will have multiple schedule records.
class Schedules extends Table with AutoIncrementId {
  /// Reference to the course offering.
  late final courseOffering = integer().references(CourseOfferings, #id)();

  /// Day of the week for this class session.
  late final dayOfWeek = intEnum<DayOfWeek>()();

  /// Period within the day for this class session.
  late final period = intEnum<Period>()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {courseOffering, dayOfWeek, period},
  ];
}

/// Course materials and resources.
///
/// Represents files, recordings, and other materials posted to I-School Plus.
///
/// Data source: I-School Plus materials and recordings page
class Materials extends Table with AutoIncrementId {
  /// Reference to the course offering this material belongs to.
  late final courseOffering = integer().references(CourseOfferings, #id)();

  /// Title/name of the material or resource.
  late final title = text().nullable()();

  /// URL/link to the material (may be a download link or external resource).
  late final href = text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {courseOffering, href},
  ];
}
