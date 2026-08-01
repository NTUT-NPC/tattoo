import 'package:tattoo/models/ranking.dart';
import 'package:tattoo/models/user.dart';
import 'package:tattoo/services/student_query/student_query_service.dart';

/// Mock implementation of [StudentQueryService] for repository unit tests
/// and demo mode.
class MockStudentQueryService implements StudentQueryService {
  StudentProfileDto? studentProfileResult;
  List<SemesterScoreDto>? academicPerformanceResult;
  List<GpaDto>? gpaResult;
  List<GradeRankingDto>? gradeRankingResult;
  List<RegistrationRecordDto>? registrationRecordsResult;

  @override
  Future<StudentProfileDto> getStudentProfile() async {
    return studentProfileResult ??
        (
          chineseName: '王大同',
          englishName: 'Da-Tong Wang',
          dateOfBirth: DateTime(2003, 5, 12),
          programZh: '四年制大學部',
          programEn: 'Four-Year Program',
          departmentZh: '電子工程系',
          departmentEn: 'Department of Electronic Engineering',
        );
  }

  @override
  Future<List<SemesterScoreDto>> getAcademicPerformance() async {
    return academicPerformanceResult ??
        [
          (
            semester: (year: 114, term: 1),
            scores: [
              (
                number: '347779',
                courseNameZh: '通訊系統實習',
                courseNameEn: 'Communication System Lab.',
                courseCode: '3603005',
                score: 21,
                status: null,
              ),
              (
                number: '347780',
                courseNameZh: '應用軟體設計實習',
                courseNameEn: 'Application Software Design Lab.',
                courseCode: '3603006',
                score: 93,
                status: null,
              ),
              (
                number: '347781',
                courseNameZh: '實務專題(一)',
                courseNameEn: 'Special Projects (I)',
                courseCode: '3603009',
                score: 92,
                status: null,
              ),
              (
                number: '347782',
                courseNameZh: '專題討論',
                courseNameEn: 'Engineering Seminar',
                courseCode: '3603090',
                score: 93,
                status: null,
              ),
              (
                number: '347784',
                courseNameZh: '計算機結構',
                courseNameEn: 'Computer Architecture',
                courseCode: '3602061',
                score: null,
                status: .withdraw,
              ),
              (
                number: '347793',
                courseNameZh: '視窗程式設計',
                courseNameEn: 'Windows Programming',
                courseCode: '3603088',
                score: 84,
                status: null,
              ),
              (
                number: '348337',
                courseNameZh: '電路學(一)',
                courseNameEn: 'Circuit Theory (I)',
                courseCode: '3602012',
                score: 55,
                status: null,
              ),
              (
                number: '348881',
                courseNameZh: '微積分',
                courseNameEn: 'Calculus',
                courseCode: '1401032',
                score: 10,
                status: null,
              ),
              (
                number: '353004',
                courseNameZh: '創新思考',
                courseNameEn: 'Innovative Thinking',
                courseCode: '1418002',
                score: 89,
                status: null,
              ),
              (
                number: '357834',
                courseNameZh: '資訊行為導論',
                courseNameEn: 'Introduction to information behaviors',
                courseCode: '1420003',
                score: 76,
                status: null,
              ),
            ],
            average: 64.9,
            conduct: 89.0,
            totalCredits: 18.0,
            creditsPassed: 11.0,
            note: null,
          ),
          (
            semester: (year: 113, term: 2),
            scores: [
              (
                number: '340433',
                courseNameZh: '數位系統設計實習',
                courseNameEn: 'Digital System Design Lab.',
                courseCode: '3603062',
                score: 23,
                status: null,
              ),
              (
                number: '340435',
                courseNameZh: '專題討論',
                courseNameEn: 'Engineering Seminar',
                courseCode: '3603090',
                score: 84,
                status: null,
              ),
              (
                number: '340436',
                courseNameZh: '實務專題(二)',
                courseNameEn: 'Special Projects (II)',
                courseCode: '3604004',
                score: 93,
                status: null,
              ),
              (
                number: '340437',
                courseNameZh: '作業系統',
                courseNameEn: 'Operating Systems',
                courseCode: '3603059',
                score: 80,
                status: null,
              ),
              (
                number: '340689',
                courseNameZh: '開源系統軟體與實務',
                courseNameEn: 'Open-Source System Software and Practice',
                courseCode: '5903326',
                score: 62,
                status: null,
              ),
              (
                number: '341048',
                courseNameZh: '電子學(二)',
                courseNameEn: 'Electronics (II)',
                courseCode: '3602009',
                score: null,
                status: .withdraw,
              ),
              (
                number: '341065',
                courseNameZh: '工程數學(二)',
                courseNameEn: 'Engineering Mathematics (II)',
                courseCode: '3602005',
                score: null,
                status: .withdraw,
              ),
              (
                number: '341869',
                courseNameZh: '英文溝通與應用(二)',
                courseNameEn:
                    'English Communication and Application II (ECA Courses)',
                courseCode: '1400039',
                score: 54,
                status: null,
              ),
              (
                number: '345588',
                courseNameZh: '計算機演算法',
                courseNameEn: 'Computer Algorithms',
                courseCode: '3602051',
                score: 83,
                status: null,
              ),
              (
                number: '346146',
                courseNameZh: '創業概論',
                courseNameEn: 'Introduction to Entrepreneurial',
                courseCode: '1418003',
                score: 97,
                status: null,
              ),
              (
                number: '346205',
                courseNameZh: '環境教育',
                courseNameEn: 'Environmental Education',
                courseCode: '1410090',
                score: 60,
                status: null,
              ),
            ],
            average: 73.2,
            conduct: 82.0,
            totalCredits: 19.0,
            creditsPassed: 16.0,
            note: null,
          ),
          (
            semester: (year: 113, term: 1),
            scores: [
              (
                number: '334011',
                courseNameZh: '通訊系統實習',
                courseNameEn: 'Communication System Lab.',
                courseCode: '3603005',
                score: 92,
                status: null,
              ),
              (
                number: '334012',
                courseNameZh: '應用軟體設計實習',
                courseNameEn: 'Application Software Design Lab.',
                courseCode: '3603006',
                score: 85,
                status: null,
              ),
              (
                number: '334013',
                courseNameZh: '實務專題(一)',
                courseNameEn: 'Special Projects (I)',
                courseCode: '3603009',
                score: 97,
                status: null,
              ),
              (
                number: '334014',
                courseNameZh: '專題討論',
                courseNameEn: 'Engineering Seminar',
                courseCode: '3603090',
                score: 86,
                status: null,
              ),
              (
                number: '334016',
                courseNameZh: '計算機結構',
                courseNameEn: 'Computer Architecture',
                courseCode: '3602061',
                score: 54,
                status: null,
              ),
              (
                number: '334833',
                courseNameZh: '工程數學(一)',
                courseNameEn: 'Engineering Mathematics (I)',
                courseCode: 'C002004',
                score: 60,
                status: null,
              ),
              (
                number: '337794',
                courseNameZh: '微積分及演習',
                courseNameEn: 'Calculus',
                courseCode: '1401036',
                score: 80,
                status: null,
              ),
              (
                number: '338974',
                courseNameZh: '職場倫理',
                courseNameEn: 'Workplace Ethics',
                courseCode: '1415017',
                score: 79,
                status: null,
              ),
              (
                number: '339025',
                courseNameZh: '音樂概論',
                courseNameEn: 'Introduction to Music',
                courseCode: '1411022',
                score: 80,
                status: null,
              ),
            ],
            average: 75.4,
            conduct: 93.0,
            totalCredits: 18.0,
            creditsPassed: 15.0,
            note: null,
          ),
          (
            semester: (year: 112, term: 2),
            scores: [
              (
                number: '327246',
                courseNameZh: '工程數學(二)',
                courseNameEn: 'Engineering Mathematics (II)',
                courseCode: '3602005',
                score: 48,
                status: null,
              ),
              (
                number: '327247',
                courseNameZh: '電子學(二)',
                courseNameEn: 'Electronics (II)',
                courseCode: '3602009',
                score: 23,
                status: null,
              ),
              (
                number: '327248',
                courseNameZh: '電子學實習(二)',
                courseNameEn: 'Electronic Lab. (II)',
                courseCode: '3602010',
                score: 66,
                status: null,
              ),
              (
                number: '327249',
                courseNameZh: '機率',
                courseNameEn: 'Probability',
                courseCode: '3602011',
                score: 13,
                status: null,
              ),
              (
                number: '327250',
                courseNameZh: '電磁學',
                courseNameEn: 'Electromagnetics',
                courseCode: '3603063',
                score: 48,
                status: null,
              ),
              (
                number: '327251',
                courseNameZh: '資料結構',
                courseNameEn: 'Data Structures',
                courseCode: '3602050',
                score: 77,
                status: null,
              ),
              (
                number: '327258',
                courseNameZh: '計算機組織',
                courseNameEn: 'Computer Organization',
                courseCode: '3603082',
                score: 60,
                status: null,
              ),
              (
                number: '331345',
                courseNameZh: '進階專業英文- 電資(二)',
                courseNameEn:
                    'Advanced ESP (Electrical Engineering and Computer Science) II',
                courseCode: '14E3073',
                score: 90,
                status: null,
              ),
              (
                number: '332227',
                courseNameZh: '創新與創業',
                courseNameEn: 'Innovation and Entrepreneurship',
                courseCode: '1418001',
                score: 92,
                status: null,
              ),
              (
                number: '332287',
                courseNameZh: '國際關係',
                courseNameEn: 'International relations',
                courseCode: '1410042',
                score: 60,
                status: null,
              ),
            ],
            average: 54.3,
            conduct: 88.0,
            totalCredits: 25.0,
            creditsPassed: 13.0,
            note: null,
          ),
          (
            semester: (year: 112, term: 1),
            scores: [
              (
                number: '320232',
                courseNameZh: '英文溝通與應用(一)',
                courseNameEn:
                    'English Communication and Application I (ECA Courses)',
                courseCode: '1400038',
                score: 91,
                status: null,
              ),
              (
                number: '320426',
                courseNameZh: '服務學習',
                courseNameEn: 'Service Learning',
                courseCode: '1400099',
                score: 74,
                status: null,
              ),
              (
                number: '320427',
                courseNameZh: '大學入門與工程倫理',
                courseNameEn:
                    'First step to achieving the goals of universities and Engineering Ethics',
                courseCode: '1400102',
                score: 89,
                status: null,
              ),
              (
                number: '320428',
                courseNameZh: '國文',
                courseNameEn: 'Chinese',
                courseCode: '1404006',
                score: 82,
                status: null,
              ),
              (
                number: '320429',
                courseNameZh: '微積分',
                courseNameEn: 'Calculus',
                courseCode: '1401032',
                score: 71,
                status: null,
              ),
              (
                number: '320430',
                courseNameZh: '物理',
                courseNameEn: 'Physics',
                courseCode: '1401041',
                score: 76,
                status: null,
              ),
              (
                number: '320431',
                courseNameZh: '物理實驗',
                courseNameEn: 'Physics Lab.',
                courseCode: '1401043',
                score: 91,
                status: null,
              ),
              (
                number: '320432',
                courseNameZh: '數位邏輯設計',
                courseNameEn: 'Digital Logic Design',
                courseCode: '3601005',
                score: 92,
                status: null,
              ),
              (
                number: '320433',
                courseNameZh: '高階語言程式實習',
                courseNameEn:
                    'Understand the basic structure of programming languages.',
                courseCode: '3601009',
                score: 97,
                status: null,
              ),
              (
                number: '320434',
                courseNameZh: '計算機概論',
                courseNameEn: 'Introduction to Computer Science',
                courseCode: '3601013',
                score: 92,
                status: null,
              ),
              (
                number: '323453',
                courseNameZh: '體育',
                courseNameEn: 'Physical Education',
                courseCode: '1001002',
                score: 92,
                status: null,
              ),
            ],
            average: 85.1,
            conduct: 91.0,
            totalCredits: 19.0,
            creditsPassed: 19.0,
            note: null,
          ),
        ];
  }

  @override
  Future<List<GpaDto>> getGpa() async {
    return gpaResult ??
        [
          (semester: (year: 114, term: 1), grandTotalGpa: 2.74),
          (semester: (year: 113, term: 2), grandTotalGpa: 2.51),
          (semester: (year: 113, term: 1), grandTotalGpa: 2.42),
          (semester: (year: 112, term: 2), grandTotalGpa: 2.28),
          (semester: (year: 112, term: 1), grandTotalGpa: 3.68),
        ];
  }

  @override
  Future<List<GradeRankingDto>> getGradeRanking() async {
    return gradeRankingResult ??
        [
          (
            semester: (year: 114, term: 1),
            entries: [
              (
                type: RankingType.classLevel,
                semesterRank: 57,
                semesterTotal: 59,
                grandTotalRank: 48,
                grandTotalTotal: 59,
              ),
              (
                type: RankingType.groupLevel,
                semesterRank: 113,
                semesterTotal: 116,
                grandTotalRank: 97,
                grandTotalTotal: 116,
              ),
              (
                type: RankingType.departmentLevel,
                semesterRank: 113,
                semesterTotal: 116,
                grandTotalRank: 97,
                grandTotalTotal: 116,
              ),
            ],
          ),
          (
            semester: (year: 113, term: 2),
            entries: [
              (
                type: RankingType.classLevel,
                semesterRank: 50,
                semesterTotal: 54,
                grandTotalRank: 51,
                grandTotalTotal: 54,
              ),
              (
                type: RankingType.groupLevel,
                semesterRank: 99,
                semesterTotal: 105,
                grandTotalRank: 101,
                grandTotalTotal: 105,
              ),
              (
                type: RankingType.departmentLevel,
                semesterRank: 99,
                semesterTotal: 105,
                grandTotalRank: 101,
                grandTotalTotal: 105,
              ),
            ],
          ),
          (
            semester: (year: 113, term: 1),
            entries: [
              (
                type: RankingType.classLevel,
                semesterRank: 42,
                semesterTotal: 54,
                grandTotalRank: 51,
                grandTotalTotal: 54,
              ),
              (
                type: RankingType.groupLevel,
                semesterRank: 90,
                semesterTotal: 107,
                grandTotalRank: 102,
                grandTotalTotal: 107,
              ),
              (
                type: RankingType.departmentLevel,
                semesterRank: 90,
                semesterTotal: 107,
                grandTotalRank: 102,
                grandTotalTotal: 107,
              ),
            ],
          ),
          (
            semester: (year: 112, term: 2),
            entries: [
              (
                type: RankingType.classLevel,
                semesterRank: 52,
                semesterTotal: 53,
                grandTotalRank: 49,
                grandTotalTotal: 53,
              ),
              (
                type: RankingType.groupLevel,
                semesterRank: 104,
                semesterTotal: 106,
                grandTotalRank: 100,
                grandTotalTotal: 106,
              ),
              (
                type: RankingType.departmentLevel,
                semesterRank: 104,
                semesterTotal: 106,
                grandTotalRank: 100,
                grandTotalTotal: 106,
              ),
            ],
          ),
          (
            semester: (year: 112, term: 1),
            entries: [
              (
                type: RankingType.classLevel,
                semesterRank: 13,
                semesterTotal: 54,
                grandTotalRank: 13,
                grandTotalTotal: 54,
              ),
              (
                type: RankingType.groupLevel,
                semesterRank: 25,
                semesterTotal: 110,
                grandTotalRank: 25,
                grandTotalTotal: 110,
              ),
              (
                type: RankingType.departmentLevel,
                semesterRank: 25,
                semesterTotal: 110,
                grandTotalRank: 25,
                grandTotalTotal: 110,
              ),
            ],
          ),
        ];
  }

  @override
  Future<List<RegistrationRecordDto>> getRegistrationRecords() async {
    return registrationRecordsResult ??
        [
          (
            semester: (year: 114, term: 1),
            className: '電子三甲',
            enrollmentStatus: EnrollmentStatus.learning,
            registered: true,
            graduated: false,
            tutors: [(id: '11635', name: '曾柏軒 (Po-Hsuan Tseng)')],
            classCadres: [],
          ),
          (
            semester: (year: 113, term: 2),
            className: '電子三甲',
            enrollmentStatus: EnrollmentStatus.learning,
            registered: true,
            graduated: false,
            tutors: [(id: '11246', name: '范育成 (YU-CHENG FAN)')],
            classCadres: ['學輔股長', '服務股長'],
          ),
          (
            semester: (year: 113, term: 1),
            className: '電子三甲',
            enrollmentStatus: EnrollmentStatus.learning,
            registered: true,
            graduated: false,
            tutors: [(id: '11246', name: '范育成 (YU-CHENG FAN)')],
            classCadres: ['學輔股長', '服務股長'],
          ),
          (
            semester: (year: 112, term: 2),
            className: '電子二甲',
            enrollmentStatus: EnrollmentStatus.learning,
            registered: true,
            graduated: false,
            tutors: [(id: '11246', name: '范育成 (YU-CHENG FAN)')],
            classCadres: ['學輔股長', '服務股長'],
          ),
          (
            semester: (year: 112, term: 1),
            className: '電子一乙',
            enrollmentStatus: EnrollmentStatus.learning,
            registered: true,
            graduated: false,
            tutors: [
              (id: '10697', name: '林惟鐘 (WEI-CHUNG LIN)'),
              (id: '11158', name: '陳建中 (Jiann-Jong Chen)'),
            ],
            classCadres: [],
          ),
        ];
  }

  @override
  Future<List<MidtermWarningDto>> getMidtermWarnings() async {
    return [
      (
        courseNumber: '354067',
        required: false,
        courseNameZh: '通訊系統',
        courseNameEn: 'Communication Systems',
        credits: 3.0,
        note: '電機三乙丙合開',
        isPoorLearning: true,
        isUndelivered: false,
        warnedRatio: '3 / 90',
      ),
    ];
  }

  @override
  Future<StudentAffairsDto> getStudentAffairs() async {
    return (
      rewardPunishmentSummary: {'嘉獎': 2},
      rewardPunishmentRecords: [
        (
          date: DateTime(2025, 5, 20),
          classification: '嘉獎',
          times: 2,
          reason: '擔任班幹部認真負責',
        ),
      ],
      attendanceSummary: {'公假': 7},
      attendanceRecords: [
        (
          week: 10,
          date: DateTime(2025, 5, 29),
          period: 1,
          rollCallNumber: null,
          classification: '公假',
          note: null,
        ),
      ],
    );
  }

  @override
  Future<List<StudentLoanDto>> getStudentLoan() async {
    return [
      (
        semester: (year: 113, term: 1),
        loanType: '學雜費貸款',
        amount: 28000.0,
        status: '審查通過',
      ),
    ];
  }

  @override
  Future<List<GeneralEducationDimensionDto>>
  getGeneralEducationDimension() async {
    return [
      (
        dimensionZh: '自然與科學向度',
        dimensionEn: 'Liberal Arts Education-Nature',
        requiredCredits: 4.0,
        coreCreditsTaken: null,
        electiveCreditsTaken: 4.0,
        courses: [
          (
            semester: (year: 112, term: 1),
            isCore: false,
            courseCode: '1416009',
            courseNameZh: '環境與自然保育',
            courseNameEn: 'Environment and Conservation',
            credits: 2.0,
            score: 94,
          ),
        ],
      ),
    ];
  }

  @override
  Future<List<EnglishProficiencyDto>> getEnglishProficiency() async {
    return [
      (
        semester: (year: 113, term: 2),
        sequenceNumber: 1,
        className: '電機二甲',
        grade: 0.0,
        level: 'A',
        certificate: '校內英語畢業門檻鑑定考',
        reviewResult: '通過英文畢業門檻',
      ),
    ];
  }

  @override
  Future<List<ExamScoreDto>> getExamScores() async {
    return [
      (
        examName: '113學年度第二學期 英文教學期中會考',
        date: DateTime(2025, 4, 15),
        testPaper: 'A',
        sectionScores: [
          (sectionName: '聽力測驗Listening test', score: 46.70),
          (sectionName: '閱讀測驗Reading test', score: 43.30),
          (sectionName: '總成績Total Score', score: 90.00),
        ],
      ),
    ];
  }

  @override
  Future<ContactInfoDto> getContactInfo() async {
    return (
      mobilePhone: '0912345678',
      email: 'student@ntut.edu.tw',
      commuteModes: ['住校', '捷運'],
      rentalAddress: null,
      landlordName: null,
      landlordPhone: null,
    );
  }

  @override
  Future<void> updateContactInfo(ContactInfoDto info) async {}

  @override
  Future<GraduationQualificationDto?> getGraduationQualifications() async {
    return (
      status: '審查通過',
      details: [
        (requirement: '應修總學分', passed: true, note: '已達標'),
      ],
    );
  }
}
