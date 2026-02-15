import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/models/ranking.dart';
import 'package:tattoo/models/score.dart';
import 'package:tattoo/models/user.dart';
import 'package:tattoo/utils/http.dart';

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
  (ref) => StudentQueryService(),
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
class StudentQueryService {
  late final Dio _studentQueryDio;

  StudentQueryService() {
    _studentQueryDio = createDio()
      ..options.baseUrl = 'https://aps-stu.ntut.edu.tw/StuQuery/';
  }

  /// Fetches student status (學籍基本資料).
  Future<StudentProfileDto> getStudentProfile() async {
    final response = await _studentQueryDio.get('QryBasisData.jsp');
    final document = parse(response.data);

    final table = document.querySelector('table');
    if (table == null) {
      throw FormatException('No table found in QryBasisData.jsp');
    }

    // Build a map from English header text to the cell value.
    // Data rows have 2 TH (Chinese label, English label) + 1 TD (value).
    final fields = <String, String?>{};
    for (final row in table.querySelectorAll('tr')) {
      final ths = row.querySelectorAll('th');
      final tds = row.querySelectorAll('td');
      if (ths.length != 2 || tds.length != 1) continue;

      final key = ths[1].text.trim();
      // English Name has an inline <div> note; extract the first text node.
      if (key == 'English Name') {
        fields[key] = tds[0].nodes
            .where((node) => node.nodeType == Node.TEXT_NODE)
            .firstOrNull
            ?.text
            ?.trim();
      } else {
        fields[key] = _parseCellText(tds[0]);
      }
    }

    // Date of Birth: "92年05月12日　2003/5/12" — extract Western date.
    final dobMatch = RegExp(
      r'(\d{4})/(\d{1,2})/(\d{1,2})',
    ).firstMatch(fields['Date of Birth'] ?? '');
    final dateOfBirth = dobMatch != null
        ? DateTime(
            int.parse(dobMatch.group(1)!),
            int.parse(dobMatch.group(2)!),
            int.parse(dobMatch.group(3)!),
          )
        : null;

    // Split mixed Chinese+English text at the first Latin character.
    // e.g. "四年制大學部Four-Year Program" → ("四年制大學部", "Four-Year Program")
    (String?, String?) splitZhEn(String? text) {
      if (text == null) return (null, null);
      final i = text.indexOf(RegExp(r'[A-Za-z]'));
      if (i <= 0) return (text, null);
      return (text.substring(0, i).trim(), text.substring(i).trim());
    }

    final (programZh, programEn) = splitZhEn(fields['Program']);
    final (departmentZh, departmentEn) = splitZhEn(
      fields['Department/Graduate Institute'],
    );

    return (
      chineseName: fields['Chinese Name'],
      englishName: fields['English Name'],
      dateOfBirth: dateOfBirth,
      programZh: programZh,
      programEn: programEn,
      departmentZh: departmentZh,
      departmentEn: departmentEn,
    );
  }

  /// Fetches academic performance (scores) for all semesters.
  ///
  /// Returns a list of [SemesterScoreDto] ordered from most recent to oldest,
  /// each containing individual course scores and semester summary statistics.
  Future<List<SemesterScoreDto>> getAcademicPerformance() async {
    final response = await _studentQueryDio.get(
      'QryScore.jsp',
      queryParameters: {'format': '-2'},
    );

    final document = parse(response.data);

    // Semester labels are in submit button values: "114 學年度 第 1 學期 (2025 - Fall)"
    final semesterPattern = RegExp(r'(\d+)\s*學年度\s*第\s*(\d+)\s*學期');
    final semesterButtons = document.querySelectorAll("input[type='submit']");
    final semesterMatches = semesterButtons
        .map((btn) => semesterPattern.firstMatch(btn.attributes['value'] ?? ''))
        .whereType<RegExpMatch>()
        .toList();

    final tables = document.querySelectorAll('table');

    final results = <SemesterScoreDto>[];
    for (var i = 0; i < tables.length && i < semesterMatches.length; i++) {
      final match = semesterMatches[i];
      final semester = (
        year: int.parse(match.group(1)!),
        term: int.parse(match.group(2)!),
      );

      final rows = tables[i].querySelectorAll('tr');
      final scores = <ScoreDto>[];
      double? average;
      double? conduct;
      double? totalCredits;
      double? creditsPassed;
      String? note;

      // Skip header row; data rows have 9+ cells, summary rows have 1-2
      for (final row in rows.skip(1)) {
        final cells = row.querySelectorAll('th, td');

        if (cells.length >= 9) {
          final scoreText = _parseCellText(cells[7]);
          final (scoreValue, status) = _parseScore(scoreText);
          scores.add((
            number: _parseCellText(cells[0]),
            courseCode: _parseCellText(cells[4]),
            score: scoreValue,
            status: status,
          ));
        } else if (cells.length == 2) {
          final label = cells[0].text;
          final value = _parseCellText(cells[1]);

          if (label.contains('Average')) {
            average = double.tryParse(value ?? '');
          } else if (label.contains('Conduct')) {
            conduct = double.tryParse(value ?? '');
          } else if (label.contains('Total Credits')) {
            totalCredits = double.tryParse(value ?? '');
          } else if (label.contains('Credits Passed')) {
            creditsPassed = double.tryParse(value ?? '');
          } else if (label.contains('Note')) {
            note = value;
          }
        }
      }

      results.add((
        semester: semester,
        scores: scores,
        average: average,
        conduct: conduct,
        totalCredits: totalCredits,
        creditsPassed: creditsPassed,
        note: note,
      ));
    }

    return results;
  }

  /// Fetches grade ranking data for all semesters.
  ///
  /// Returns a list of [GradeRankingDto] ordered from most recent to oldest,
  /// each containing ranking positions at class, group, and department levels.
  Future<List<GradeRankingDto>> getGradeRanking() async {
    final response = await _studentQueryDio.get('QryRank.jsp');
    final document = parse(response.data);

    final table = document.querySelector('table');
    if (table == null) return [];

    final semesterPattern = RegExp(r'(\d+)\s*-\s*(\d+)');
    final results = <GradeRankingDto>[];
    SemesterDto? currentSemester;
    var currentEntries = <GradeRankingEntryDto>[];

    // Rows are either: 8 cells (semester start + data), 7 cells (continuation),
    // or other (header/notice — skip).
    // Semester cell uses rowspan="3" to span its 3 ranking type rows.
    for (final row in table.querySelectorAll('tr')) {
      final cells = row.querySelectorAll('td').toList();

      int dataStart;
      if (cells.length == 8) {
        // New semester with ranking data
        if (currentSemester != null && currentEntries.isNotEmpty) {
          results.add((semester: currentSemester, entries: currentEntries));
          currentEntries = [];
        }
        // Cell contains "113 - 2<br>2025 - Spring" — use first text node
        final semesterText = cells[0].nodes
            .where((node) => node.nodeType == Node.TEXT_NODE)
            .firstOrNull
            ?.text;
        final match = semesterPattern.firstMatch(semesterText ?? '');
        if (match == null) continue;
        currentSemester = (
          year: int.parse(match.group(1)!),
          term: int.parse(match.group(2)!),
        );
        dataStart = 1;
      } else if (cells.length == 7) {
        dataStart = 0;
      } else {
        continue;
      }

      // cells[dataStart]: ranking type, +1/+2: semester rank/total,
      // +3: semester percentage (skip), +4/+5: grand total rank/total,
      // +6: grand total percentage (skip)
      final type = _parseRankingType(cells[dataStart].text);
      if (type == null) continue;

      final semesterRank = int.tryParse(cells[dataStart + 1].text.trim());
      final semesterTotal = int.tryParse(cells[dataStart + 2].text.trim());
      final grandTotalRank = int.tryParse(cells[dataStart + 4].text.trim());
      final grandTotalTotal = int.tryParse(cells[dataStart + 5].text.trim());

      if (semesterRank == null ||
          semesterTotal == null ||
          grandTotalRank == null ||
          grandTotalTotal == null) {
        continue;
      }

      currentEntries.add((
        type: type,
        semesterRank: semesterRank,
        semesterTotal: semesterTotal,
        grandTotalRank: grandTotalRank,
        grandTotalTotal: grandTotalTotal,
      ));
    }

    if (currentSemester != null && currentEntries.isNotEmpty) {
      results.add((semester: currentSemester, entries: currentEntries));
    }

    return results;
  }

  /// Fetches registration records (class assignment, mentors, cadre roles)
  /// for all semesters.
  ///
  /// Returns a list of [RegistrationRecordDto] ordered from most recent to
  /// oldest.
  Future<List<RegistrationRecordDto>> getRegistrationRecords() async {
    final response = await _studentQueryDio.get('QryRegist.jsp');

    final document = parse(response.data);

    // Single table with 7 columns: semester, class, enrollment status,
    // registered, graduated, tutors, class cadres
    final table = document.querySelector('table');
    if (table == null) return [];

    // Semester cell: <div>"114 - 2"<br>"2026 - Spring"</div> — use first text node
    final semesterPattern = RegExp(r'(\d+)\s*-\s*(\d+)');

    final results = <RegistrationRecordDto>[];
    for (final row in table.querySelectorAll('tr').skip(1)) {
      final cells = row.querySelectorAll('th, td');
      if (cells.length < 7) continue;

      final semesterContainer = cells[0].querySelector('div') ?? cells[0];
      final semesterText = semesterContainer.nodes
          .where((node) => node.nodeType == Node.TEXT_NODE)
          .firstOrNull
          ?.text;
      final semesterMatch = semesterPattern.firstMatch(semesterText ?? '');
      if (semesterMatch == null) continue;

      final semester = (
        year: int.parse(semesterMatch.group(1)!),
        term: int.parse(semesterMatch.group(2)!),
      );
      final className = _parseCellText(cells[1]);
      final enrollmentStatus = _parseEnrollmentStatus(_parseCellText(cells[2]));
      final registered = cells[3].text.contains('※');
      final graduated = cells[4].text.contains('※');

      // Tutor names are <a> links to CourseService's Teach.jsp with ?code=teacherId
      final tutors = cells[5].querySelectorAll('a').map((a) {
        final href = Uri.tryParse(a.attributes['href'] ?? '');
        final id = href?.queryParameters['code'];
        return (id: id, name: _parseCellText(a));
      }).toList();

      // Cadre roles are text nodes separated by <br> inside a <div>
      final cadreContainer = cells[6].querySelector('div') ?? cells[6];
      final classCadres = cadreContainer.nodes
          .where((node) => node.nodeType == Node.TEXT_NODE)
          .map((node) => node.text?.trim() ?? '')
          .where((text) => text.isNotEmpty)
          .toList();

      results.add((
        semester: semester,
        className: className,
        enrollmentStatus: enrollmentStatus,
        registered: registered,
        graduated: graduated,
        tutors: tutors,
        classCadres: classCadres,
      ));
    }

    return results;
  }

  String? _parseCellText(Element cell) {
    final text = cell.text.trim();
    return text.isNotEmpty ? text : null;
  }

  /// Maps ranking type cell text (e.g. "班 級 排 名Class Ranking") to enum.
  RankingType? _parseRankingType(String text) {
    if (text.contains('Class')) return RankingType.classLevel;
    if (text.contains('Group')) return RankingType.groupLevel;
    if (text.contains('Department')) return RankingType.departmentLevel;
    return null;
  }

  /// Maps enrollment status text to [EnrollmentStatus].
  EnrollmentStatus? _parseEnrollmentStatus(String? text) {
    return switch (text) {
      '在學' => EnrollmentStatus.learning,
      '休學' => EnrollmentStatus.leaveOfAbsence,
      '退學' => EnrollmentStatus.droppedOut,
      _ => null,
    };
  }

  /// Parses a score cell value into either a numeric grade or a [ScoreStatus].
  (int?, ScoreStatus?) _parseScore(String? text) {
    if (text == null) return (null, null);

    final numeric = int.tryParse(text);
    if (numeric != null) return (numeric, null);

    final status = switch (text) {
      'N' => ScoreStatus.notEntered,
      'W' || 'Ｗ' => ScoreStatus.withdraw,
      '#' => ScoreStatus.undelivered,
      'P' => ScoreStatus.pass,
      'F' => ScoreStatus.fail,
      '抵免' => ScoreStatus.creditTransfer,
      _ => null,
    };

    return (null, status);
  }
}
