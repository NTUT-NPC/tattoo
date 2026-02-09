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
import 'package:tattoo/models/ranking.dart';
import 'package:tattoo/models/score.dart';

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
  ///
  /// Nullable because some students in I-School Plus rosters have no name
  /// recorded (e.g., student 110440001 in course 292704).
  late final name = text().nullable()();
}

/// Academic semester information.
///
/// Represents an academic term at NTUT (e.g., 114-1 for Fall 2025).
class Semesters extends Table with AutoIncrementId {
  /// Academic year in ROC calendar (e.g., 114 for 2025).
  late final year = integer()();

  /// Semester number within the year (1=Fall, 2=Spring, 3=Summer).
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
  /// Unique course code (e.g., "3004130", "3602012", "AC23502", "1001002").
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

/// Academic department information.
///
/// Represents departments/institutes at NTUT (e.g., "製科所", "電子系").
class Departments extends Table with AutoIncrementId, Fetchable {
  /// Unique department code in the NTUT system.
  late final code = text().unique()();

  /// Department name in Traditional Chinese.
  late final nameZh = text()();
}

/// Teacher/instructor information for a particular semester.
///
/// Each row represents a teacher's profile snapshot for a specific semester.
/// The same teacher will have multiple rows across different semesters.
@TableIndex(name: 'teacher_semester', columns: {#semester})
class Teachers extends Table with AutoIncrementId, Fetchable {
  /// Teacher code/ID in the NTUT system.
  late final code = text()();

  /// Reference to the semester this profile is for.
  late final semester = integer().references(Semesters, #id)();

  /// Teacher's name in Traditional Chinese.
  late final nameZh = text()();

  /// Teacher's name in English.
  late final nameEn = text().nullable()();

  /// Teacher's email address.
  ///
  /// Available from syllabus page (教學大綱與進度).
  late final email = text().nullable()();

  /// Reference to the teacher's department.
  late final department = integer().nullable().references(Departments, #id)();

  /// Academic title (e.g., "專任副教授", "兼任講師").
  late final title = text().nullable()();

  /// Total teaching hours for this semester.
  late final teachingHours = real().nullable()();

  /// Additional notes about office hours (e.g., appointment requirements).
  late final officeHoursNote = text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {code, semester},
  ];
}

/// Teacher office hours time slots.
///
/// Each row represents one office hour time slot for a teacher.
/// A teacher may have multiple office hour slots per week.
@TableIndex(name: 'teacher_office_hour_teacher', columns: {#teacher})
class TeacherOfficeHours extends Table with AutoIncrementId {
  /// Reference to the teacher (semester-specific).
  late final teacher = integer().references(Teachers, #id)();

  /// Day of the week for this office hour slot.
  late final dayOfWeek = intEnum<DayOfWeek>()();

  /// Start time hour (0-23).
  late final startHour = integer()();

  /// Start time minute (0-59).
  late final startMinute = integer()();

  /// End time hour (0-23).
  late final endHour = integer()();

  /// End time minute (0-59).
  late final endMinute = integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {teacher, dayOfWeek, startHour, startMinute},
  ];
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
@TableIndex(name: 'user_student', columns: {#student})
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
@TableIndex(name: 'course_offering_course', columns: {#course})
@TableIndex(name: 'course_offering_semester', columns: {#semester})
class CourseOfferings extends Table with AutoIncrementId, Fetchable {
  /// Reference to the course definition.
  late final course = integer().references(Courses, #id)();

  /// Reference to the semester when this course is offered.
  late final semester = integer().references(Semesters, #id)();

  /// Unique course offering number (e.g., "313146", "352902").
  late final number = text().unique()();

  /// Course sequence phase/stage number (階段, e.g., "1", "2").
  ///
  /// For multi-part courses like 物理 with the same name. Some courses
  /// encode the sequence in the name instead (e.g., 英文溝通與應用(一)).
  late final phase = integer()();

  /// Course type for graduation credit requirements (課程標準).
  ///
  /// Uses symbols from syllabus page: ○, △, ☆, ●, ▲, ★
  /// See [CourseType] enum for mapping.
  late final courseType = textEnum<CourseType>()();

  /// Enrollment status for special cases (e.g., "撤選" for withdrawal).
  ///
  /// Normally null for regular enrolled courses.
  late final status = text().nullable()();

  /// Language of instruction (e.g., "英語").
  late final language = text().nullable()();

  /// Additional remarks or notes about this offering.
  late final remarks = text().nullable()();

  /// Number of enrolled students (人).
  late final enrolled = integer().nullable()();

  /// Number of withdrawn students (撤).
  late final withdrawn = integer().nullable()();

  // Syllabus fields (教學大綱與進度)

  /// Syllabus ID for fetching detailed syllabus information.
  late final syllabusId = text().nullable()();

  /// When the syllabus was last updated (最後更新時間).
  late final syllabusUpdatedAt = dateTime().nullable()();

  /// Course objective/outline (課程大綱).
  late final objective = text().nullable()();

  /// Weekly plan describing topics covered each week (課程進度).
  ///
  /// Note: Called "Course Schedule" on English page, but refers to weekly
  /// topics, not class meeting times.
  late final weeklyPlan = text().nullable()();

  /// Evaluation and grading policy (評量方式與標準).
  late final evaluation = text().nullable()();

  /// Textbooks and reference materials (使用教材、參考書目或其他).
  late final textbooks = text().nullable()();
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
@TableIndex(name: 'schedule_course_offering', columns: {#courseOffering})
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

/// Per-course score entry from the student query system (學業成績查詢).
///
/// Each row represents one course's grade for a student in a semester.
/// Data source: StudentQueryService.getAcademicPerformance()
@TableIndex(name: 'score_student', columns: {#student})
class Scores extends Table with AutoIncrementId {
  /// Reference to the student who received this score.
  late final student = integer().references(Students, #id)();

  /// Reference to the semester this score belongs to.
  late final semester = integer().references(Semesters, #id)();

  /// Reference to the course definition (resolved from ScoreDto.courseCode).
  late final course = integer().references(Courses, #id)();

  /// Reference to the specific course offering.
  ///
  /// Nullable because credit waivers (抵免) have no associated offering.
  late final courseOffering = integer().nullable().references(
    CourseOfferings,
    #id,
  )();

  /// Numeric grade (null when [status] is set instead).
  late final score = integer().nullable()();

  /// Special score status (null when [score] is numeric).
  late final status = textEnum<ScoreStatus>().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {student, course, semester},
  ];
}

/// Per-student per-semester academic summary from the student query system.
///
/// Stores aggregate statistics like weighted average, conduct grade, and
/// credits for each semester, as well as registration status information.
///
/// Data sources:
/// - StudentQueryService.getAcademicPerformance() — scores and averages
/// - StudentQueryService.getRegistrationRecords() — registration status
/// - StudentQueryService.getGradeRanking() — rankings (via [StudentSemesterRankings])
@TableIndex(name: 'student_semester_summary_student', columns: {#student})
class StudentSemesterSummaries extends Table with AutoIncrementId {
  /// Reference to the student.
  late final student = integer().references(Students, #id)();

  /// Reference to the semester.
  late final semester = integer().references(Semesters, #id)();

  /// Weighted average for the semester.
  late final average = real().nullable()();

  /// Conduct grade.
  late final conduct = real().nullable()();

  /// Total credits attempted.
  late final totalCredits = real().nullable()();

  /// Credits passed/earned.
  late final creditsPassed = real().nullable()();

  /// Additional note.
  late final note = text().nullable()();

  /// Student's assigned class name (e.g., "電子四甲").
  /// Plain text — no class code available from this page.
  late final className = text().nullable()();

  /// Enrollment status (e.g., "在學", "休學", "退學").
  late final enrollmentStatus = text().nullable()();

  /// Whether the student is registered for this semester.
  late final registered = boolean().nullable()();

  /// Whether the student graduated this semester.
  late final graduated = boolean().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {student, semester},
  ];
}

/// Junction table linking student semester summaries to their tutors.
///
/// A student may have multiple tutors (導師) in a semester.
/// Data source: StudentQueryService.getRegistrationRecords()
class StudentSemesterSummaryTutors extends Table {
  /// Reference to the student semester summary.
  late final summary = integer().references(StudentSemesterSummaries, #id)();

  /// Reference to the teacher serving as tutor.
  late final teacher = integer().references(Teachers, #id)();

  @override
  Set<Column> get primaryKey => {summary, teacher};
}

/// Class cadre roles held by a student in a semester.
///
/// Each row represents one cadre role (e.g., "班代", "副班代") for a
/// student in a particular semester.
/// Data source: StudentQueryService.getRegistrationRecords()
class StudentSemesterSummaryCadreRoles extends Table with AutoIncrementId {
  /// Reference to the student semester summary.
  late final summary = integer().references(StudentSemesterSummaries, #id)();

  /// Cadre role title (e.g., "班代", "副班代").
  late final role = text()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {summary, role},
  ];
}

/// Grade ranking data for a student in a semester at a given scope.
///
/// Each student-semester has up to 3 rows: class, group, and department.
/// Data source: StudentQueryService.getGradeRanking()
class StudentSemesterRankings extends Table {
  /// Reference to the student semester summary.
  late final summary = integer().references(StudentSemesterSummaries, #id)();

  /// The scope of this ranking (class, group, or department).
  late final rankingType = textEnum<RankingType>()();

  /// Position in the semester ranking (學期成績排名).
  late final semesterRank = integer()();

  /// Total students in the comparison group for semester ranking.
  late final semesterTotal = integer()();

  /// Position in the cumulative ranking (歷年成績排名).
  late final grandTotalRank = integer()();

  /// Total students in the comparison group for cumulative ranking.
  late final grandTotalTotal = integer()();

  @override
  Set<Column> get primaryKey => {summary, rankingType};
}

/// Course materials and resources.
///
/// Represents files, recordings, and other materials posted to I-School Plus.
///
/// Data source: I-School Plus materials and recordings page
@TableIndex(name: 'material_course_offering', columns: {#courseOffering})
class Materials extends Table with AutoIncrementId {
  /// Reference to the course offering this material belongs to.
  late final courseOffering = integer().references(CourseOfferings, #id)();

  /// Title/name of the material or resource.
  late final title = text().nullable()();

  /// SCORM resource identifier for the material.
  ///
  /// This is an encoded identifier from the SCORM manifest.
  /// This value is used internally by I-School Plus to locate the resource.
  late final href = text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {courseOffering, href},
  ];
}
