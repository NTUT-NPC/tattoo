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
                courseCode: '3004130',
                score: 86,
                status: null,
              ),
              (
                number: '348337',
                courseCode: '3602012',
                score: 60,
                status: null,
              ),
              (
                number: '348616',
                courseCode: 'AC23502',
                score: 82,
                status: null,
              ),
              (
                number: '352204',
                courseCode: '3604174',
                score: 95,
                status: null,
              ),
              (
                number: '352205',
                courseCode: '3604052',
                score: 89,
                status: null,
              ),
              (
                number: '352828',
                courseCode: '1001002',
                score: 77,
                status: null,
              ),
              (
                number: '352902',
                courseCode: '1410145',
                score: 66,
                status: null,
              ),
              (
                number: '353181',
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
                courseCode: '3602001',
                score: 72,
                status: null,
              ),
              (
                number: '342510',
                courseCode: '3604052',
                score: null,
                status: .withdraw,
              ),
              (
                number: '345890',
                courseCode: '1001002',
                score: 81,
                status: null,
              ),
              (
                number: '345920',
                courseCode: '1410080',
                score: 75,
                status: null,
              ),
              (
                number: null,
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
}
