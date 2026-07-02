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
                number: '346774',
                courseNameZh: '鐵道號誌與行車控制系統',
                courseNameEn: 'Railway Signal and Traffic Control System',
                courseCode: '3004130',
                score: 86,
                status: null,
              ),
              (
                number: '348337',
                courseNameZh: '電路學(一)',
                courseNameEn: 'Circuit Theory (I)',
                courseCode: '3602012',
                score: 60,
                status: null,
              ),
              (
                number: '348616',
                courseNameZh: '數位出版與設計',
                courseNameEn: 'Digital Publishing Design',
                courseCode: 'AC23502',
                score: 82,
                status: null,
              ),
              (
                number: '352204',
                courseNameZh: '邊緣運算',
                courseNameEn: 'Edge Computing',
                courseCode: '3604174',
                score: 95,
                status: null,
              ),
              (
                number: '352205',
                courseNameZh: '計算機網路',
                courseNameEn: 'Computer Networks',
                courseCode: '3604052',
                score: 89,
                status: null,
              ),
              (
                number: '352828',
                courseNameZh: '體育',
                courseNameEn: 'Physical Education',
                courseCode: '1001002',
                score: 77,
                status: null,
              ),
              (
                number: '352902',
                courseNameZh: '智慧財產權',
                courseNameEn: 'Intellectual Property',
                courseCode: '1410145',
                score: 66,
                status: null,
              ),
              (
                number: '353181',
                courseNameZh: '生成式AI文字與圖像生成原理實務',
                courseNameEn:
                    'Generative AI: Text and Image Synthesis Principles and Practice',
                courseCode: '0199998',
                score: 68,
                status: null,
              ),
            ],
            average: 78.6,
            conduct: 87.0,
            totalCredits: 20.0,
            creditsPassed: 20.0,
            note: null,
          ),
          (
            semester: (year: 113, term: 2),
            scores: [
              (
                number: '342501',
                courseNameZh: '工程數學(一)',
                courseNameEn: 'Engineering Mathematics (I)',
                courseCode: '3602001',
                score: 72,
                status: null,
              ),
              (
                number: '342510',
                courseNameZh: '計算機網路',
                courseNameEn: 'Computer Networks',
                courseCode: '3604052',
                score: null,
                status: .withdraw,
              ),
              (
                number: '345890',
                courseNameZh: '體育',
                courseNameEn: 'Physical Education',
                courseCode: '1001002',
                score: 81,
                status: null,
              ),
              (
                number: '345920',
                courseNameZh: '中國書法藝術欣賞',
                courseNameEn: 'Chinese Calligraphy Appreciation',
                courseCode: '1410080',
                score: 75,
                status: null,
              ),
              (
                number: null,
                courseNameZh: '微積分',
                courseNameEn: 'Calculus',
                courseCode: '1401032',
                score: null,
                status: .creditTransfer,
              ),
            ],
            average: 76.0,
            conduct: 85.0,
            totalCredits: 14.0,
            creditsPassed: 11.0,
            note: null,
          ),
        ];
  }

  @override
  Future<List<GpaDto>> getGpa() async {
    return gpaResult ??
        [
          (semester: (year: 114, term: 1), grandTotalGpa: 2.61),
          (semester: (year: 113, term: 2), grandTotalGpa: 2.51),
          (semester: (year: 113, term: 1), grandTotalGpa: 2.42),
          (semester: (year: 112, term: 2), grandTotalGpa: 2.28),
          (semester: (year: 112, term: 1), grandTotalGpa: 2.65),
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
                semesterRank: 46,
                semesterTotal: 54,
                grandTotalRank: 51,
                grandTotalTotal: 54,
              ),
              (
                type: RankingType.groupLevel,
                semesterRank: 92,
                semesterTotal: 105,
                grandTotalRank: 101,
                grandTotalTotal: 105,
              ),
              (
                type: RankingType.departmentLevel,
                semesterRank: 92,
                semesterTotal: 105,
                grandTotalRank: 101,
                grandTotalTotal: 105,
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
        ];
  }

  @override
  Future<List<RegistrationRecordDto>> getRegistrationRecords() async {
    return registrationRecordsResult ??
        [
          (
            semester: (year: 114, term: 2),
            className: '電子四甲',
            enrollmentStatus: EnrollmentStatus.learning,
            registered: true,
            graduated: false,
            tutors: [(id: '11246', name: '范育成')],
            classCadres: [],
          ),
          (
            semester: (year: 114, term: 1),
            className: '電子四甲',
            enrollmentStatus: EnrollmentStatus.learning,
            registered: true,
            graduated: false,
            tutors: [(id: '11246', name: '范育成')],
            classCadres: ['學輔股長', '服務股長'],
          ),
          (
            semester: (year: 113, term: 2),
            className: '電子三甲',
            enrollmentStatus: EnrollmentStatus.learning,
            registered: true,
            graduated: false,
            tutors: [(id: '11246', name: '范育成')],
            classCadres: ['學輔股長', '服務股長'],
          ),
          (
            semester: (year: 113, term: 1),
            className: '電子三甲',
            enrollmentStatus: EnrollmentStatus.learning,
            registered: true,
            graduated: false,
            tutors: [(id: '11246', name: '范育成')],
            classCadres: ['學輔股長', '服務股長'],
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
