import 'package:riverpod/riverpod.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/services/course/ntut_course_service.dart';

/// Course schedule entry from the course selection system.
typedef ScheduleDto = ({
  /// Course offering number (e.g., "313146", "352902").
  String? number,

  /// Reference to the course with bilingual name.
  LocalizedRefDto? course,

  /// Course sequence phase/stage number (階段, e.g., "1", "2").
  int? phase,

  /// Number of credits for this course.
  double? credits,

  /// Number of hours per week.
  int? hours,

  /// Type of course (e.g., "必", "選", "通", "輔").
  String? type,

  /// Reference to the instructor with bilingual name.
  LocalizedRefDto? teacher,

  /// List of class/program references with bilingual names.
  List<LocalizedRefDto>? classes,

  /// Weekly schedule as list of (day, period, classroom) entries.
  ///
  /// Each entry includes the classroom for that specific timeslot, as some
  /// courses use different rooms for different sessions.
  List<({DayOfWeek day, Period period, ReferenceDto? classroom})>? schedule,

  /// Enrollment status for special cases (e.g., "撤選" for withdrawal).
  ///
  /// Normally null for regular enrolled courses.
  String? status,

  /// Language of instruction.
  String? language,

  /// Syllabus identifier for fetching course syllabus.
  String? syllabusId,

  /// Additional remarks or notes about the course.
  String? remarks,
});

/// Course information from the course catalog.
typedef CourseDto = ({
  /// Course's unique identifier code.
  String? id,

  /// Course name in Traditional Chinese.
  String? nameZh,

  /// Course name in English.
  String? nameEn,

  /// Number of credits.
  double? credits,

  /// Number of hours per week.
  int? hours,

  /// Course description in Traditional Chinese.
  String? descriptionZh,

  /// Course description in English.
  String? descriptionEn,
});

/// Office hours time slot for a teacher.
typedef OfficeHourDto = ({
  /// Day of week.
  DayOfWeek day,

  /// Start time as (hour, minute).
  ({int hour, int minute}) startTime,

  /// End time as (hour, minute).
  ({int hour, int minute}) endTime,
});

/// Teacher profile information from the teacher schedule page.
typedef TeacherDto = ({
  /// Reference to the teacher's department.
  ReferenceDto? department,

  /// Academic title (e.g., "專任副教授", "兼任講師").
  String? title,

  /// Teacher's name in Traditional Chinese.
  String? nameZh,

  /// Teacher's name in English (from office hours page).
  String? nameEn,

  /// Total teaching hours for the semester.
  double? teachingHours,

  /// Office hours time slots.
  List<OfficeHourDto>? officeHours,

  /// Additional notes about office hours (e.g., appointment requirements).
  String? officeHoursNote,
});

/// Syllabus details from the course syllabus page (教學大綱與進度).
typedef SyllabusDto = ({
  // Header table (課程基本資料)

  /// Course type for graduation requirements (修).
  ///
  /// More accurate than course table types (必/選/通/輔).
  /// Uses symbols: ○, △, ☆, ●, ▲, ★
  CourseType? type,

  /// Number of enrolled students (人).
  int? enrolled,

  /// Number of withdrawn students (撤).
  int? withdrawn,

  // Syllabus table (教學大綱與進度)

  /// Instructor's email address.
  String? email,

  /// Last updated timestamp (最後更新時間).
  DateTime? lastUpdated,

  /// Course objective/outline (課程大綱).
  ///
  /// English page: "Course Objective"
  String? objective,

  /// Weekly plan (課程進度).
  ///
  /// English page: "Course Schedule" - describes weekly topics, not class
  /// meeting times.
  String? weeklyPlan,

  /// Evaluation and grading policy (評量方式與標準).
  String? evaluation,

  /// Textbooks and reference materials (使用教材、參考書目或其他).
  String? materials,

  /// Additional remarks (備註).
  String? remarks,
});

/// Provides the singleton [CourseService] instance.
final courseServiceProvider = Provider<CourseService>(
  (ref) => NtutCourseService(),
);

/// Service for accessing NTUT's course selection and catalog system.
///
/// This service provides access to:
/// - Student course schedules and enrollment
/// - Course catalog information
/// - Teacher, classroom, and syllabus data
///
/// Authentication is required through [PortalService.sso] with
/// [PortalServiceCode.courseService] before using this service.
///
/// Data is parsed from HTML pages as NTUT does not provide a REST API.
abstract interface class CourseService {
  /// Fetches the list of available semesters for the authenticated student.
  ///
  /// Returns a list of semester identifiers (year and semester number) for which
  /// course schedules are available. The server identifies the student from the
  /// session cookie established by SSO.
  ///
  /// This method should be called before [getCourseTable] to determine which
  /// semesters have course data available.
  Future<List<SemesterDto>> getCourseSemesterList();

  /// Fetches the course schedule table for a specific student and semester.
  ///
  /// Returns a list of course offerings enrolled by the student, including:
  /// - Course details (name, credits, hours)
  /// - Schedule information (days, periods, classroom)
  /// - Teacher and class information
  /// - Enrollment status and remarks
  ///
  /// The [username] should be a student ID, and [semester] should be obtained
  /// from [getCourseSemesterList].
  ///
  /// Throws an [Exception] if no courses are found for the given semester.
  Future<List<ScheduleDto>> getCourseTable({
    required String username,
    required SemesterDto semester,
  });

  /// Fetches detailed information about a specific course from the catalog.
  ///
  /// Returns course details including bilingual names, descriptions, credits,
  /// and hours per week.
  ///
  /// The [courseId] should be a course code obtained from the `course.id` field
  /// of a [ScheduleDto].
  ///
  /// Throws an [Exception] if the course details table is not found.
  Future<CourseDto> getCourse(String courseId);

  /// Fetches detailed information about a specific teacher.
  ///
  /// Returns teacher profile information including department, title, and
  /// office hours for the given [teacherId] in a specific [semester].
  ///
  /// The [teacherId] should be a teacher code obtained from the `teacher.id`
  /// field of a [ScheduleDto].
  Future<TeacherDto> getTeacher({
    required String teacherId,
    required SemesterDto semester,
  });

  /// Fetches detailed information about a specific classroom.
  ///
  /// Returns classroom information including location and schedule for the given
  /// [classroomId] in a specific [semester].
  ///
  /// This method is not yet implemented.
  Future getClassroom({
    required String classroomId,
    required SemesterDto semester,
  });

  /// Fetches the detailed syllabus for a course offering.
  ///
  /// Returns syllabus information including course objectives, textbooks,
  /// grading policy, and weekly plan.
  ///
  /// The [courseNumber] should be a course offering number (e.g., "346774"),
  /// and [syllabusId] should be obtained from the `syllabusId` field of a
  /// [ScheduleDto].
  ///
  /// Throws an [Exception] if the syllabus tables are not found.
  Future<SyllabusDto> getSyllabus({
    required String courseNumber,
    required String syllabusId,
  });
}
