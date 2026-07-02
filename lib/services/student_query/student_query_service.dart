import 'package:riverpod/riverpod.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/models/ranking.dart';
import 'package:tattoo/models/score.dart';
import 'package:tattoo/models/user.dart';
import 'package:tattoo/services/student_query/ntut_student_query_service.dart';

/// A single course score entry from the academic performance page.
typedef ScoreDto = ({
  /// Course offering number (joins with ScheduleDto.number).
  ///
  /// Null for credit transfers/waivers from other institutions.
  String? number,

  /// Course name in Chinese from the academic performance table's 3rd column.
  String? courseNameZh,

  /// Course name in English from the academic performance table's 4th column.
  String? courseNameEn,

  /// Course catalog code (joins with Courses.code).
  ///
  /// Usually present; may be null for rows without a course code.
  /// When present, serves as fallback identifier when [number] is null.
  String? courseCode,

  /// Numeric grade (null when [status] is set).
  int? score,

  /// Special score status (null when [score] is numeric).
  ScoreStatus? status,
});

/// Semester academic performance summary with course scores.
typedef SemesterScoreDto = ({
  /// Semester identifier.
  SemesterDto semester,

  /// Individual course scores for this semester.
  List<ScoreDto> scores,

  /// Weighted average for the semester.
  double? average,

  /// Conduct grade.
  double? conduct,

  /// Total credits attempted.
  double? totalCredits,

  /// Credits passed/earned.
  double? creditsPassed,

  /// Additional note.
  String? note,
});

/// A semester registration record from the class and mentor page.
typedef RegistrationRecordDto = ({
  /// Semester identifier.
  SemesterDto semester,

  /// Student's assigned class name (e.g., "電子四甲").
  String? className,

  /// Enrollment status (在學, 休學, or 退學).
  EnrollmentStatus? enrollmentStatus,

  /// Whether the student is registered for this semester.
  bool registered,

  /// Whether the student graduated this semester.
  bool graduated,

  /// Tutors/mentors assigned to the student's class.
  List<ReferenceDto> tutors,

  /// Class cadre roles held (e.g., ["學輔股長", "服務股長"]).
  List<String> classCadres,
});

/// A single ranking entry for one scope (class/group/department).
typedef GradeRankingEntryDto = ({
  /// The scope of this ranking comparison.
  RankingType type,

  /// Position in the semester ranking (學期成績排名 — 名次).
  int semesterRank,

  /// Total students in the comparison group for semester ranking (總人數).
  int semesterTotal,

  /// Position in the cumulative ranking (歷年成績排名 — 名次).
  int grandTotalRank,

  /// Total students in the comparison group for cumulative ranking (總人數).
  int grandTotalTotal,
});

/// Grade ranking data for a single semester.
typedef GradeRankingDto = ({
  /// Semester identifier.
  SemesterDto semester,

  /// Ranking entries (typically class, group, and department).
  List<GradeRankingEntryDto> entries,
});

/// GPA data for a single semester.
typedef GpaDto = ({
  /// Semester identifier.
  SemesterDto semester,

  /// Grand total (historical cumulative) GPA.
  double grandTotalGpa,
});

/// Student status (學籍基本資料) from the basis data page.
typedef StudentProfileDto = ({
  String? chineseName,
  String? englishName,
  DateTime? dateOfBirth,
  String? programZh,
  String? programEn,
  String? departmentZh,
  String? departmentEn,
});

/// A course entry from the mid-term warning inquiry page (期中預警查詢).
typedef MidtermWarningDto = ({
  /// Course catalog code or offering number.
  String? courseNumber,

  /// Whether the course is required (true) or elective (false).
  bool? required,

  /// Course name in Chinese.
  String? courseNameZh,

  /// Course name in English.
  String? courseNameEn,

  /// Number of credits.
  double? credits,

  /// Additional remarks or restrictions.
  String? note,

  /// Whether the student is marked for poor learning performance in this subject.
  bool isPoorLearning,

  /// Whether the teacher has not yet entered warning records.
  bool isUndelivered,

  /// Ratio of poorly warned students in the class (e.g., "3 / 90").
  String? warnedRatio,
});

/// A reward or punishment detailed record from the student affairs page (考勤、獎懲查詢).
typedef RewardPunishmentRecordDto = ({
  /// Date of the event.
  DateTime? date,

  /// Classification (e.g., "嘉獎", "申誡").
  String classification,

  /// Number of times/units.
  int times,

  /// Description of the facts or reasons.
  String? reason,
});

/// An absenteeism or leave record from the student affairs page.
typedef AttendanceRecordDto = ({
  /// Week number of the semester.
  int? week,

  /// Date of the leave or absence.
  DateTime? date,

  /// Period/session number of the day.
  int? period,

  /// Roll call list number.
  String? rollCallNumber,

  /// Leave or absence classification (e.g., "公假", "曠課", "事假").
  String classification,

  /// Additional remarks.
  String? note,
});

/// Comprehensive student affairs data including rewards, punishments, and attendance.
typedef StudentAffairsDto = ({
  /// Summary counts of rewards and punishments by classification.
  Map<String, int> rewardPunishmentSummary,

  /// Detailed list of rewards and punishments.
  List<RewardPunishmentRecordDto> rewardPunishmentRecords,

  /// Summary counts of absenteeism and leaves by classification.
  Map<String, int> attendanceSummary,

  /// Detailed list of absenteeism and leaves.
  List<AttendanceRecordDto> attendanceRecords,
});

/// A student loan record from the student loan inquiry page (就學貸款資料查詢).
typedef StudentLoanDto = ({
  /// Semester identifier.
  SemesterDto? semester,

  /// Type or category of the loan.
  String? loanType,

  /// Loan amount in NTD.
  double? amount,

  /// Review status or notes.
  String? status,
});

/// A course taken within a general education dimension (博雅課程).
typedef GeneralEducationCourseDto = ({
  /// Semester when the course was taken.
  SemesterDto? semester,

  /// Whether the course counts toward the core requirement (true) or elective (false).
  bool? isCore,

  /// Course catalog code.
  String? courseCode,

  /// Course name in Chinese.
  String? courseNameZh,

  /// Course name in English.
  String? courseNameEn,

  /// Credits earned.
  double? credits,

  /// Final grade achieved.
  int? score,
});

/// Summary and course list for a general education dimension (查詢已修讀博雅課程向度).
typedef GeneralEducationDimensionDto = ({
  /// Dimension name in Chinese (e.g., "自然與科學向度").
  String dimensionZh,

  /// Dimension name in English (e.g., "Liberal Arts Education-Nature").
  String? dimensionEn,

  /// Credits required for this dimension.
  double? requiredCredits,

  /// Core credits already taken.
  double? coreCreditsTaken,

  /// Elective credits already taken.
  double? electiveCreditsTaken,

  /// Courses taken within this dimension over the years.
  List<GeneralEducationCourseDto> courses,
});

/// An English graduation requirement verification record (查詢英語畢業門檻登錄資料).
typedef EnglishProficiencyDto = ({
  /// Semester identifier when recorded.
  SemesterDto? semester,

  /// Sequence number.
  int? sequenceNumber,

  /// Class name at the time of recording.
  String? className,

  /// Overall score or grade achieved.
  double? grade,

  /// Level or tier assigned.
  String? level,

  /// Name of the examination or certificate submitted.
  String? certificate,

  /// Final review result (e.g., "通過英文畢業門檻").
  String? reviewResult,
});

/// A section or total score entry for a coordinate subject exam (會考成績).
typedef ExamSectionScoreDto = ({
  /// Section name (e.g., "聽力測驗Listening test", "總成績Total Score").
  String? sectionName,

  /// Score achieved.
  double? score,
});

/// Results for a university coordinate subject exam (查詢會考電腦閱卷成績).
typedef ExamScoreDto = ({
  /// Name of the coordinate exam.
  String? examName,

  /// Date the examination was held.
  DateTime? date,

  /// Test paper version or form (e.g., "A").
  String? testPaper,

  /// Section scores and total score.
  List<ExamSectionScoreDto> sectionScores,
});

/// Student personal contact information from the contact maintenance page (維護個人聯絡資料).
typedef ContactInfoDto = ({
  /// Mobile phone number.
  String? mobilePhone,

  /// Primary email address.
  String? email,

  /// Transportation modes used to commute to school (e.g., ["住校", "捷運"]).
  List<String> commuteModes,

  /// Rental house address (if applicable).
  String? rentalAddress,

  /// Landlord's name (if applicable).
  String? landlordName,

  /// Landlord's phone number (if applicable).
  String? landlordPhone,
});

/// Graduation qualification review status (查詢畢業資格審查).
///
/// Note: This data is typically only available to graduating seniors.
typedef GraduationQualificationDto = ({
  /// Status summary or review result.
  String? status,

  /// Detailed checks or requirements breakdown.
  List<({String requirement, bool passed, String? note})> details,
});

/// Provides the singleton [StudentQueryService] instance.
final studentQueryServiceProvider = Provider<StudentQueryService>(
  (ref) => NtutStudentQueryService(),
);

/// Service for accessing NTUT's student query system (學生查詢專區).
///
/// This service provides access to:
/// - Academic performance and scores
/// - Student status information
/// - GPA and ranking data
///
/// Authentication is required through [PortalService.sso] with
/// [PortalServiceCode.studentQueryService] before using this service.
///
/// Data is parsed from HTML pages as NTUT does not provide a REST API.
abstract interface class StudentQueryService {
  /// Fetches student status (學籍基本資料).
  Future<StudentProfileDto> getStudentProfile();

  /// Fetches academic performance (scores) for all semesters.
  ///
  /// Returns a list of [SemesterScoreDto] ordered from most recent to oldest,
  /// each containing individual course scores and semester summary statistics.
  Future<List<SemesterScoreDto>> getAcademicPerformance();

  /// Fetches grand total GPA records by semester.
  Future<List<GpaDto>> getGpa();

  /// Fetches grade ranking data for all semesters.
  ///
  /// Returns a list of [GradeRankingDto] ordered from most recent to oldest,
  /// each containing ranking positions at class, group, and department levels.
  Future<List<GradeRankingDto>> getGradeRanking();

  /// Fetches registration records (class assignment, mentors, cadre roles)
  /// for all semesters.
  ///
  /// Returns a list of [RegistrationRecordDto] ordered from most recent to
  /// oldest.
  Future<List<RegistrationRecordDto>> getRegistrationRecords();

  /// Fetches mid-term warning records for the current semester (期中預警查詢).
  Future<List<MidtermWarningDto>> getMidtermWarnings();

  /// Fetches student affairs records including rewards, punishments, and attendance (考勤、獎懲查詢).
  Future<StudentAffairsDto> getStudentAffairs();

  /// Fetches student loan records (就學貸款資料查詢).
  Future<List<StudentLoanDto>> getStudentLoan();

  /// Fetches general education dimension course summary and records (查詢已修讀博雅課程向度).
  Future<List<GeneralEducationDimensionDto>> getGeneralEducationDimension();

  /// Fetches English graduation proficiency requirement records (查詢英語畢業門檻登錄資料).
  Future<List<EnglishProficiencyDto>> getEnglishProficiency();

  /// Fetches coordinate subject computer-graded exam scores (查詢會考電腦閱卷成績).
  Future<List<ExamScoreDto>> getExamScores();

  /// Fetches personal contact information (維護個人聯絡資料).
  Future<ContactInfoDto> getContactInfo();

  /// Updates personal contact information on NTUT servers.
  Future<void> updateContactInfo(ContactInfoDto info);

  /// Fetches graduation qualification review status (查詢畢業資格審查).
  ///
  /// Returns null if the graduation review function is not available for the current student.
  Future<GraduationQualificationDto?> getGraduationQualifications();
}
