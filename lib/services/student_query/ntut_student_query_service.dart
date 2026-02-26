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
      ..options.baseUrl = 'https://aps-stu.ntut.edu.tw/StuQuery/';
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

    // Safeguard: Detect session termination to trigger auto-reauthentication
    if (response.data.toString().contains('應用系統已中斷連線')) {
      throw Exception('SessionExpired');
    }

    final document = parse(response.data);

    // Matches semester labels e.g., "114 學年度 第 1 學期"
    final semesterPattern = RegExp(r'(\d+)\s*學年度\s*第\s*(\d+)\s*學期');

    // Query both inputs and tables to preserve document order
    final elements = document.querySelectorAll("input[type='submit'], table");

    final results = <SemesterScoreDto>[];
    SemesterDto? currentSemester;
    bool hasAddedTableForCurrentSemester = false;

    for (final el in elements) {
      if (el.localName == 'input') {
        // Found a semester switcher: update current context
        final value = el.attributes['value'] ?? '';
        final match = semesterPattern.firstMatch(value);
        if (match != null) {
          currentSemester = (
            year: int.parse(match.group(1)!),
            term: int.parse(match.group(2)!),
          );
          hasAddedTableForCurrentSemester = false;
        }
      } else if (el.localName == 'table') {
        // Found a data table: verify context and prevent duplicate processing
        if (currentSemester == null || hasAddedTableForCurrentSemester)
          continue;

        final rows = el.querySelectorAll('tr');
        final scores = <ScoreDto>[];
        double? average;
        double? conduct;
        double? totalCredits;
        double? creditsPassed;
        String? note;

        bool isDataParsed = false;

        // Row 0 is the header; data rows have 9+ columns, summary rows have 2
        for (final row in rows.skip(1)) {
          final cells = row.querySelectorAll('th, td');

          if (cells.length >= 9) {
            isDataParsed = true;
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
              isDataParsed = true;
              average = double.tryParse(value ?? '');
            } else if (label.contains('Conduct')) {
              isDataParsed = true;
              conduct = double.tryParse(value ?? '');
            } else if (label.contains('Total Credits')) {
              isDataParsed = true;
              totalCredits = double.tryParse(value ?? '');
            } else if (label.contains('Credits Passed')) {
              isDataParsed = true;
              creditsPassed = double.tryParse(value ?? '');
            } else if (label.contains('Note')) {
              isDataParsed = true;
              note = value;
            }
          }
        }

        if (isDataParsed) {
          results.add((
            semester: currentSemester,
            scores: scores,
            average: average,
            conduct: conduct,
            totalCredits: totalCredits,
            creditsPassed: creditsPassed,
            note: note,
          ));
          hasAddedTableForCurrentSemester = true;
        }
      }
    }

    return results;
  }

  @override
  Future<List<GpaDto>> getGPA() async {
    final response = await _studentQueryDio.get('QryGPA.jsp');

    if (response.data.toString().contains('應用系統已中斷連線')) {
      throw Exception('SessionExpired');
    }

    return _parseGpaFromDocument(parse(response.data));
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

    for (final row in table.querySelectorAll('tr')) {
      final cells = row.querySelectorAll('td').toList();

      int dataStart;
      if (cells.length == 8) {
        // Starting new semester block
        if (currentSemester != null && currentEntries.isNotEmpty) {
          results.add((semester: currentSemester, entries: currentEntries));
          currentEntries = [];
        }
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

    final table = document.querySelector('table');
    if (table == null) return [];

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

      final tutors = cells[5].querySelectorAll('a').map((a) {
        final href = Uri.tryParse(a.attributes['href'] ?? '');
        final id = href?.queryParameters['code'];
        return (id: id, name: _parseCellText(a));
      }).toList();

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

  /// Maps ranking type labels to [RankingType] enum.
  RankingType? _parseRankingType(String text) {
    if (text.contains('Class')) return RankingType.classLevel;
    if (text.contains('Group')) return RankingType.groupLevel;
    if (text.contains('Department')) return RankingType.departmentLevel;
    return null;
  }

  /// Maps enrollment status strings to [EnrollmentStatus] enum.
  EnrollmentStatus? _parseEnrollmentStatus(String? text) {
    return switch (text) {
      '在學' => EnrollmentStatus.learning,
      '休學' => EnrollmentStatus.leaveOfAbsence,
      '退學' => EnrollmentStatus.droppedOut,
      _ => null,
    };
  }

  /// Parses score cell content into numeric values or [ScoreStatus] enums.
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

  List<GpaDto> _parseGpaFromDocument(Document document) {
    final semesterPattern = RegExp(r'(\d{2,4})\s*[-－–—]\s*([12])');
    final gpaPattern = RegExp(r'\d+(?:\.\d+)?');

    final results = <GpaDto>[];
    final seen = <String>{};

    for (final row in document.querySelectorAll('tr')) {
      final cells = row.querySelectorAll('td');
      if (cells.length < 2) continue;

      final semesterContainer = cells[0].querySelector('div') ?? cells[0];
      final semesterText = semesterContainer.nodes
          .where((node) => node.nodeType == Node.TEXT_NODE)
          .map((node) => node.text?.trim() ?? '')
          .firstWhere((text) => text.isNotEmpty, orElse: () => '');
      final semesterMatch = semesterPattern.firstMatch(semesterText);
      if (semesterMatch == null) continue;

      final year = int.tryParse(semesterMatch.group(1)!);
      final term = int.tryParse(semesterMatch.group(2)!);
      if (year == null || term == null) continue;

      final gpaText = cells[1].text.trim();
      final gpaMatch = gpaPattern.firstMatch(gpaText);
      final grandTotalGpa = gpaMatch != null
          ? double.tryParse(gpaMatch.group(0)!)
          : null;
      if (grandTotalGpa == null) continue;

      final key = '$year-$term';
      if (seen.contains(key)) continue;

      seen.add(key);
      results.add((
        semester: (year: year, term: term),
        grandTotalGpa: grandTotalGpa,
      ));
    }

    results.sort((a, b) {
      final yearCompare = b.semester.year.compareTo(a.semester.year);
      if (yearCompare != 0) return yearCompare;
      return b.semester.term.compareTo(a.semester.term);
    });

    return results;
  }
}
