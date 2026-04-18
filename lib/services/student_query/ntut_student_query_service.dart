import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/models/ranking.dart';
import 'package:tattoo/models/score.dart';
import 'package:tattoo/models/user.dart';
import 'package:tattoo/services/student_query/student_query_service.dart';
import 'package:tattoo/utils/http.dart';

class NtutStudentQueryService implements StudentQueryService {
  late final Dio _studentQueryDio;

  NtutStudentQueryService() {
    _studentQueryDio = createDio()
      ..options.baseUrl = 'https://aps-stu.ntut.edu.tw/StuQuery/'
      ..interceptors.add(_SessionCheckInterceptor());
  }

  @override
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

  @override
  Future<List<SemesterScoreDto>> getAcademicPerformance() async {
    final response = await _studentQueryDio.get(
      'QryScore.jsp',
      queryParameters: {'format': '-2'},
    );

    final document = parse(response.data);

    // Semester labels are in submit button values: "114 學年度 第 1 學期 (2025 - Fall)"
    final semesterPattern = RegExp(r'(\d+)\s*學年度\s*第\s*(\d+)\s*學期');
    final semesterButtons = document
        .querySelectorAll("input[type='submit']")
        .where(
          (button) =>
              semesterPattern.hasMatch(button.attributes['value'] ?? ''),
        )
        .toList();
    final elements = document.querySelectorAll('*');
    final elementIndexes = <Element, int>{
      for (var i = 0; i < elements.length; i++) elements[i]: i,
    };

    final results = <SemesterScoreDto>[];
    for (var i = 0; i < semesterButtons.length; i++) {
      final currentButton = semesterButtons[i];
      final match = semesterPattern.firstMatch(
        currentButton.attributes['value'] ?? '',
      );
      if (match == null) continue;

      final startIndex = elementIndexes[currentButton];
      if (startIndex == null) continue;
      final nextButton = i + 1 < semesterButtons.length
          ? semesterButtons[i + 1]
          : null;
      // Parse within this semester section only to avoid table/button misalignment.
      final endIndex = nextButton == null
          ? elements.length
          : elementIndexes[nextButton] ?? elements.length;
      final table = _findAcademicPerformanceTable(
        elements,
        startIndex,
        endIndex,
      );
      if (table == null) continue;

      final semester = (
        year: int.parse(match.group(1)!),
        term: int.parse(match.group(2)!),
      );

      final rows = table.querySelectorAll('tr');
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

  Element? _findAcademicPerformanceTable(
    List<Element> elements,
    int startIndex,
    int endIndex,
  ) {
    // Pick the first score-like table between two semester headers.
    for (var i = startIndex + 1; i < endIndex; i++) {
      final element = elements[i];
      if (element.localName != 'table') continue;
      if (_isAcademicPerformanceTable(element)) {
        return element;
      }
    }
    return null;
  }

  bool _isAcademicPerformanceTable(Element table) {
    final rows = table.querySelectorAll('tr');
    if (rows.isEmpty) return false;

    // Course rows usually have many columns (course metadata + score fields).
    for (final row in rows) {
      final cells = row.querySelectorAll('th, td');
      if (cells.length >= 9) return true;
    }

    // Summary-only tables still contain known labels.
    for (final row in rows) {
      final cells = row.querySelectorAll('th, td');
      if (cells.length != 2) continue;

      final label = cells[0].text;
      if (label.contains('Average') ||
          label.contains('Conduct') ||
          label.contains('Total Credits') ||
          label.contains('Credits Passed') ||
          label.contains('Note')) {
        return true;
      }
    }

    return false;
  }

  @override
  Future<List<GpaDto>> getGpa() async {
    final response = await _studentQueryDio.get('QryGPA.jsp');
    final document = parse(response.data);

    final semesterPattern = RegExp(r'(\d{2,4})\s*[-－–—]\s*([12])');
    final gpaPattern = RegExp(r'\d+(?:\.\d+)?');

    final results = <GpaDto>[];
    final seen = <String>{};

    for (final row in document.querySelectorAll('tr').skip(1)) {
      final cells = row.querySelectorAll('td');
      if (cells.length < 2) continue;

      final semesterContainer = cells[0].querySelector('div') ?? cells[0];
      final semesterText = semesterContainer.nodes
          .where((node) => node.nodeType == Node.TEXT_NODE)
          .map((node) => node.text?.trim() ?? '')
          .firstWhere((text) => text.isNotEmpty, orElse: () => '');
      final semesterMatch = semesterPattern.firstMatch(semesterText);
      if (semesterMatch == null) continue;

      final year = int.parse(semesterMatch.group(1)!);
      final term = int.parse(semesterMatch.group(2)!);

      final gpaText = cells[1].text.trim();
      final gpaMatch = gpaPattern.firstMatch(gpaText);
      final grandTotalGpa = gpaMatch != null
          ? double.tryParse(gpaMatch.group(0)!)
          : null;
      if (grandTotalGpa == null) continue;

      final key = '$year-$term';
      if (!seen.add(key)) continue;

      results.add((
        semester: (year: year, term: term),
        grandTotalGpa: grandTotalGpa,
      ));
    }

    results.sort((a, b) {
      final yearCompare = b.semester.year!.compareTo(a.semester.year!);
      if (yearCompare != 0) return yearCompare;
      return b.semester.term!.compareTo(a.semester.term!);
    });
    return results;
  }

  @override
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

  @override
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

/// Detects expired sessions in StudentQuery responses.
///
/// NTUT returns HTTP 200 with a short error message instead of a proper 401
/// when the SSO session has expired.
class _SessionCheckInterceptor extends Interceptor {
  static const _marker = '應用系統已中斷連線';

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final data = response.data;
    if (data is String && data.contains(_marker)) {
      throw const SessionExpiredException(
        'StudentQuery session expired',
      );
    }
    handler.next(response);
  }
}
