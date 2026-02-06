import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:tattoo/models/score.dart';
import 'package:tattoo/services/course_service.dart';
import 'package:tattoo/utils/http.dart';

/// A single course score entry from the academic performance page.
typedef ScoreDTO = ({
  /// Course offering number (joins with ScheduleDTO.number).
  ///
  /// Null for credit transfers/waivers from other institutions.
  String? number,

  /// Course catalog code (joins with Courses.code).
  ///
  /// Always present — serves as fallback identifier when [number] is null.
  String? courseCode,

  /// Numeric grade (null when [status] is set).
  int? score,

  /// Special score status (null when [score] is numeric).
  ScoreStatus? status,
});

/// Semester academic performance summary with course scores.
typedef SemesterScoreDTO = ({
  /// Semester identifier.
  SemesterDTO semester,

  /// Individual course scores for this semester.
  List<ScoreDTO> scores,

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

  /// Fetches academic performance (scores) for all semesters.
  ///
  /// Returns a list of [SemesterScoreDTO] ordered from most recent to oldest,
  /// each containing individual course scores and semester summary statistics.
  Future<List<SemesterScoreDTO>> getAcademicPerformance() async {
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

    final results = <SemesterScoreDTO>[];
    for (var i = 0; i < tables.length && i < semesterMatches.length; i++) {
      final match = semesterMatches[i];
      final semester = (
        year: int.parse(match.group(1)!),
        semester: int.parse(match.group(2)!),
      );

      final rows = tables[i].querySelectorAll('tr');
      final scores = <ScoreDTO>[];
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

  String? _parseCellText(Element cell) {
    final text = cell.text.trim();
    return text.isNotEmpty ? text : null;
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
