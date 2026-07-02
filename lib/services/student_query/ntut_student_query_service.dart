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
      final html =
          document.querySelector('iframe')?.outerHtml ??
          response.data.toString();
      if (html.isNotEmpty) {
        throw ActionRequiredException(html);
      }
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
    if (document.querySelector('table') == null) {
      final html =
          document.querySelector('iframe')?.outerHtml ??
          response.data.toString();
      if (html.isNotEmpty) {
        throw ActionRequiredException(html);
      }
    }

    // Semester labels are in submit button values: "114 學年度 第 1 學期 (2025 - Fall)"
    final semesterPattern = RegExp(r'(\d+)\s*學年度\s*第\s*(\d+)\s*學期');

    // Walk buttons and tables in document order, pairing each semester button
    // with the next table. Other submits (print/reset) leave pending intact.
    final results = <SemesterScoreDto>[];
    SemesterDto? pendingSemester;
    final nodes = document.querySelectorAll("input[type='submit'], table");

    for (final node in nodes) {
      if (node.localName == 'input') {
        if (semesterPattern.firstMatch(node.attributes['value'] ?? '')
            case final match?) {
          pendingSemester = (
            year: int.parse(match.group(1)!),
            term: int.parse(match.group(2)!),
          );
        }
        continue;
      }

      if (pendingSemester == null) continue;

      final rows = node.querySelectorAll('tr');
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
            courseNameZh: _parseCellText(cells[2]),
            courseNameEn: _parseCellText(cells[3]),
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
        semester: pendingSemester,
        scores: scores,
        average: average,
        conduct: conduct,
        totalCredits: totalCredits,
        creditsPassed: creditsPassed,
        note: note,
      ));
      pendingSemester = null;
    }

    return results;
  }

  @override
  Future<List<GpaDto>> getGpa() async {
    final response = await _studentQueryDio.get('QryGPA.jsp');
    final document = parse(response.data);
    if (document.querySelector('table') == null) {
      final html =
          document.querySelector('iframe')?.outerHtml ??
          response.data.toString();
      if (html.isNotEmpty) {
        throw ActionRequiredException(html);
      }
    }

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
    if (table == null) {
      final html =
          document.querySelector('iframe')?.outerHtml ??
          response.data.toString();
      if (html.isNotEmpty) {
        throw ActionRequiredException(html);
      }
      return [];
    }

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
    if (table == null) {
      final html =
          document.querySelector('iframe')?.outerHtml ??
          response.data.toString();
      if (html.isNotEmpty) {
        throw ActionRequiredException(html);
      }
      return [];
    }

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

  @override
  Future<List<MidtermWarningDto>> getMidtermWarnings() async {
    final response = await _studentQueryDio.get('QrySCWarn.jsp');
    final document = parse(response.data);
    final table = document.querySelector('table');
    if (table == null) return [];

    final results = <MidtermWarningDto>[];
    for (final row in table.querySelectorAll('tr').skip(1)) {
      final cells = row.querySelectorAll('th, td');
      if (cells.length < 9) continue;

      final reqText = _parseCellText(cells[1]) ?? '';
      final required = reqText.contains('必') || reqText.contains('Required')
          ? true
          : (reqText.contains('選') || reqText.contains('Elective')
                ? false
                : null);

      results.add((
        courseNumber: _parseCellText(cells[0]),
        required: required,
        courseNameZh: _parseCellText(cells[2]),
        courseNameEn: _parseCellText(cells[3]),
        credits: double.tryParse(_parseCellText(cells[4]) ?? ''),
        note: _parseCellText(cells[5]),
        isPoorLearning: cells[6].text.trim().isNotEmpty,
        isUndelivered: cells[7].text.trim().isNotEmpty,
        warnedRatio: _parseCellText(cells[8]),
      ));
    }
    return results;
  }

  @override
  Future<StudentAffairsDto> getStudentAffairs() async {
    final response = await _studentQueryDio.get('QryAbsRew.jsp');
    final document = parse(response.data);
    final tables = document.querySelectorAll('table');

    final rewardSummary = <String, int>{};
    final rewardRecords = <RewardPunishmentRecordDto>[];
    final attendanceSummary = <String, int>{};
    final attendanceRecords = <AttendanceRecordDto>[];

    // Table 0: Reward and Punishment Statistics
    if (tables.isNotEmpty) {
      for (final row in tables[0].querySelectorAll('tr').skip(1)) {
        final cells = row.querySelectorAll('th, td');
        if (cells.length >= 2) {
          final classification = cells[0].text.trim();
          final times = int.tryParse(cells[1].text.trim());
          if (classification.isNotEmpty && times != null) {
            rewardSummary[classification] = times;
          }
        }
      }
    }

    // Table 1: Reward and Punishment Detailed Records
    if (tables.length >= 2) {
      for (final row in tables[1].querySelectorAll('tr').skip(1)) {
        final cells = row.querySelectorAll('th, td');
        if (cells.length >= 4) {
          final dateStr = cells[0].text.trim();
          final classification = cells[1].text.trim();
          final timesStr = cells[2].text.trim();
          final reason = _parseCellText(cells[3]);
          if (classification.isEmpty ||
              classification.contains('無') ||
              classification.contains('None')) {
            continue;
          }
          final times = int.tryParse(timesStr) ?? 1;
          rewardRecords.add((
            date: _parseWesternDate(dateStr),
            classification: classification,
            times: times,
            reason: reason,
          ));
        }
      }
    }

    // Table 2: Absenteeism and Leave Statistics
    if (tables.length >= 3) {
      for (final row in tables[2].querySelectorAll('tr').skip(1)) {
        final cells = row.querySelectorAll('th, td');
        if (cells.length >= 2) {
          final classification = cells[0].text.trim();
          final times = int.tryParse(cells[1].text.trim());
          if (classification.isNotEmpty && times != null) {
            attendanceSummary[classification] = times;
          }
        }
      }
    }

    // Table 3: Absenteeism and Leave Detailed Records
    if (tables.length >= 4) {
      for (final row in tables[3].querySelectorAll('tr').skip(1)) {
        final cells = row.querySelectorAll('th, td');
        if (cells.length >= 6) {
          final dateStr = cells[1].text.trim();
          final classification = cells[4].text.trim();
          if (classification.isEmpty ||
              classification.contains('無') ||
              classification.contains('None')) {
            continue;
          }
          attendanceRecords.add((
            week: int.tryParse(cells[0].text.trim()),
            date: _parseWesternDate(dateStr),
            period: int.tryParse(cells[2].text.trim()),
            rollCallNumber: _parseCellText(cells[3]),
            classification: classification,
            note: _parseCellText(cells[5]),
          ));
        }
      }
    }

    return (
      rewardPunishmentSummary: rewardSummary,
      rewardPunishmentRecords: rewardRecords,
      attendanceSummary: attendanceSummary,
      attendanceRecords: attendanceRecords,
    );
  }

  @override
  Future<List<StudentLoanDto>> getStudentLoan() async {
    final response = await _studentQueryDio.get('QryFeeLoan.jsp');
    final document = parse(response.data);
    final table = document.querySelector('table');
    if (table == null) return [];

    final semesterPattern = RegExp(r'(\d+)\s*[-－–—]\s*([12])');
    final results = <StudentLoanDto>[];
    for (final row in table.querySelectorAll('tr').skip(1)) {
      final cells = row.querySelectorAll('th, td');
      if (cells.length < 4) continue;

      final semText = cells[0].text;
      final match = semesterPattern.firstMatch(semText);
      final semester = match != null
          ? (
              year: int.parse(match.group(1)!),
              term: int.parse(match.group(2)!),
            )
          : null;

      results.add((
        semester: semester,
        loanType: _parseCellText(cells[1]),
        amount: double.tryParse(cells[2].text.replaceAll(',', '').trim()),
        status: _parseCellText(cells[3]),
      ));
    }
    return results;
  }

  @override
  Future<List<GeneralEducationDimensionDto>>
  getGeneralEducationDimension() async {
    final response = await _studentQueryDio.get('QryLAECourse.jsp');
    final document = parse(response.data);
    final table = document.querySelector('table');
    if (table == null) return [];

    final semesterPattern = RegExp(r'(\d+)\s*[-－–—]\s*([12])');
    final results = <GeneralEducationDimensionDto>[];
    String? currentDimZh;
    String? currentDimEn;
    double? reqCred;
    double? coreCred;
    double? elecCred;
    var currentCourses = <GeneralEducationCourseDto>[];

    void saveCurrent() {
      if (currentDimZh != null) {
        results.add((
          dimensionZh: currentDimZh,
          dimensionEn: currentDimEn,
          requiredCredits: reqCred,
          coreCreditsTaken: coreCred,
          electiveCreditsTaken: elecCred,
          courses: currentCourses,
        ));
      }
    }

    for (final row in table.querySelectorAll('tr').skip(2)) {
      final cells = row.querySelectorAll('th, td');
      if (cells.length < 5) continue;

      int courseStart = 0;
      if (cells.length >= 10) {
        saveCurrent();
        currentCourses = [];
        final dimText = cells[0].text.trim();
        final i = dimText.indexOf(RegExp(r'[A-Za-z]'));
        if (i > 0) {
          currentDimZh = dimText.substring(0, i).trim();
          currentDimEn = dimText.substring(i).trim();
        } else {
          currentDimZh = dimText;
          currentDimEn = null;
        }
        reqCred = double.tryParse(cells[1].text.trim());
        coreCred = double.tryParse(cells[2].text.trim());
        elecCred = double.tryParse(cells[3].text.trim());
        courseStart = 4;
      }

      if (cells.length >= courseStart + 7) {
        final semText = cells[courseStart].text;
        final semMatch = semesterPattern.firstMatch(semText);
        final semester = semMatch != null
            ? (
                year: int.parse(semMatch.group(1)!),
                term: int.parse(semMatch.group(2)!),
              )
            : null;
        final code = _parseCellText(cells[courseStart + 2]);
        if (code != null) {
          final isCoreText = cells[courseStart + 1].text.trim();
          currentCourses.add((
            semester: semester,
            isCore: isCoreText.isNotEmpty ? true : false,
            courseCode: code,
            courseNameZh: _parseCellText(cells[courseStart + 3]),
            courseNameEn: _parseCellText(cells[courseStart + 4]),
            credits: double.tryParse(cells[courseStart + 5].text.trim()),
            score: int.tryParse(cells[courseStart + 6].text.trim()),
          ));
        }
      }
    }
    saveCurrent();
    return results;
  }

  @override
  Future<List<EnglishProficiencyDto>> getEnglishProficiency() async {
    final response = await _studentQueryDio.get('QryGeptScore.jsp');
    final document = parse(response.data);
    final table = document.querySelector('table');
    if (table == null) return [];

    final semesterPattern = RegExp(r'(\d+)\s*[-－–—]\s*([12])');
    final results = <EnglishProficiencyDto>[];
    for (final row in table.querySelectorAll('tr').skip(1)) {
      final cells = row.querySelectorAll('th, td');
      if (cells.length < 7) continue;

      final semMatch = semesterPattern.firstMatch(cells[0].text);
      final semester = semMatch != null
          ? (
              year: int.parse(semMatch.group(1)!),
              term: int.parse(semMatch.group(2)!),
            )
          : null;

      results.add((
        semester: semester,
        sequenceNumber: int.tryParse(cells[1].text.trim()),
        className: _parseCellText(cells[2]),
        grade: double.tryParse(cells[3].text.trim()),
        level: _parseCellText(cells[4]),
        certificate: _parseCellText(cells[5]),
        reviewResult: _parseCellText(cells[6]),
      ));
    }
    return results;
  }

  @override
  Future<List<ExamScoreDto>> getExamScores() async {
    final response = await _studentQueryDio.get('QryExamScore.jsp');
    final document = parse(response.data);
    final table = document.querySelector('table');
    if (table == null) return [];

    final results = <ExamScoreDto>[];
    String? currentName;
    DateTime? currentDate;
    String? currentPaper;
    var currentSections = <ExamSectionScoreDto>[];

    void saveCurrent() {
      if (currentName != null) {
        results.add((
          examName: currentName,
          date: currentDate,
          testPaper: currentPaper,
          sectionScores: currentSections,
        ));
      }
    }

    for (final row in table.querySelectorAll('tr').skip(1)) {
      final cells = row.querySelectorAll('th, td');
      if (cells.length >= 5) {
        saveCurrent();
        currentSections = [];
        currentName = _parseCellText(cells[0]);
        currentDate = _parseWesternDate(cells[1].text);
        currentPaper = _parseCellText(cells[2]);
        final secName = _parseCellText(cells[3]);
        final secScore = double.tryParse(cells[4].text.trim());
        if (secName != null) {
          currentSections.add((sectionName: secName, score: secScore));
        }
      } else if (cells.length >= 2 && currentName != null) {
        final secName = _parseCellText(cells[0]);
        final secScore = double.tryParse(cells[1].text.trim());
        if (secName != null) {
          currentSections.add((sectionName: secName, score: secScore));
        }
      }
    }
    saveCurrent();
    return results;
  }

  @override
  Future<ContactInfoDto> getContactInfo() async {
    final response = await _studentQueryDio.get('UpdContact.jsp');
    final document = parse(response.data);

    String? val(String name) => document
        .querySelector('input[name="$name"]')
        ?.attributes['value']
        ?.trim();

    final commuteModes = document
        .querySelectorAll('input[name="commute"][checked]')
        .map((e) => e.attributes['value']?.trim() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();

    return (
      mobilePhone: val('mtelno'),
      email: val('email'),
      commuteModes: commuteModes,
      rentalAddress: val('rent_addr'),
      landlordName: val('lessor'),
      landlordPhone: val('ltelno'),
    );
  }

  @override
  Future<void> updateContactInfo(ContactInfoDto info) async {
    await _studentQueryDio.post(
      'UpdContact.jsp',
      data: {
        'tosave': '1',
        'mtelno': info.mobilePhone ?? '',
        'email': info.email ?? '',
        'commute': info.commuteModes,
        'rent_addr': info.rentalAddress ?? '',
        'lessor': info.landlordName ?? '',
        'ltelno': info.landlordPhone ?? '',
        'Save': '確認並儲存資料 (Save)',
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }

  @override
  Future<GraduationQualificationDto?> getGraduationQualifications() async {
    final funcRes = await _studentQueryDio.get('Function.jsp');
    final funcDoc = parse(funcRes.data);
    final link = funcDoc.querySelectorAll('a').firstWhere(
      (a) {
        final text = a.text;
        final href = a.attributes['href'] ?? '';
        if (href.contains('QryGeptScore') ||
            text.contains('英語') ||
            text.contains('English')) {
          return false;
        }
        return text.contains('畢業資格') || text.contains('Graduation');
      },
      orElse: () => Element.tag('a'),
    );
    final href = link.attributes['href'];
    if (href == null || href.isEmpty) return null;

    final response = await _studentQueryDio.get(href);
    final document = parse(response.data);
    final table = document.querySelector('table');
    if (table == null) return null;

    final details = <({String requirement, bool passed, String? note})>[];
    String? status;
    for (final row in table.querySelectorAll('tr')) {
      final cells = row.querySelectorAll('th, td');
      if (cells.length >= 3) {
        final req = cells[0].text.trim();
        final resText = cells[1].text.trim();
        final note = _parseCellText(cells[2]);
        if (req.isNotEmpty) {
          details.add((
            requirement: req,
            passed:
                resText.contains('通過') ||
                resText.contains('Pass') ||
                resText.contains('合格') ||
                resText.contains('符合'),
            note: note,
          ));
        }
      } else if (cells.length == 1 || cells.length == 2) {
        if (cells[0].text.contains('審查結果') ||
            cells[0].text.contains('狀態') ||
            cells[0].text.contains('總結') ||
            cells[0].text.contains('Status')) {
          status = cells.last.text.trim();
        }
      }
    }

    return (status: status, details: details);
  }

  DateTime? _parseWesternDate(String? text) {
    if (text == null) return null;
    final match = RegExp(
      r'(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})',
    ).firstMatch(text);
    if (match != null) {
      return DateTime(
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
        int.parse(match.group(3)!),
      );
    }
    // Try ROC year format: 115.05.29
    final rocMatch = RegExp(
      r'(\d{2,3})[-/.](\d{1,2})[-/.](\d{1,2})',
    ).firstMatch(text);
    if (rocMatch != null) {
      final rocYear = int.parse(rocMatch.group(1)!);
      if (rocYear < 200) {
        return DateTime(
          rocYear + 1911,
          int.parse(rocMatch.group(2)!),
          int.parse(rocMatch.group(3)!),
        );
      }
    }
    return null;
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
      'N' || 'Ｎ' => ScoreStatus.notEntered,
      'W' || 'Ｗ' => ScoreStatus.withdraw,
      '#' || '＃' => ScoreStatus.undelivered,
      'P' || 'Ｐ' => ScoreStatus.pass,
      'F' || 'Ｆ' => ScoreStatus.fail,
      '抵免' || '抵' => ScoreStatus.creditTransfer,
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
