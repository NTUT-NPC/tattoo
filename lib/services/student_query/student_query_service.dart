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
}
