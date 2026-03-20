import 'package:tattoo/services/i_school_plus/i_school_plus_service.dart';

/// Mock implementation of [ISchoolPlusService] for repository unit tests
/// and demo mode.
class MockISchoolPlusService implements ISchoolPlusService {
  List<ISchoolCourseDto>? courseListResult;
  List<StudentDto>? studentsResult;
  List<MaterialRefDto>? materialsResult;
  MaterialDto? materialResult;

  @override
  Future<List<ISchoolCourseDto>> getCourseList() async {
    return courseListResult ??
        [
          (courseNumber: '353181', internalId: '10099612'),
          (courseNumber: '352902', internalId: '10099386'),
          (courseNumber: '352828', internalId: '10099330'),
          (courseNumber: '352205', internalId: '10098948'),
          (courseNumber: '352204', internalId: '10098947'),
          (courseNumber: '348337', internalId: '10097936'),
        ];
  }

  @override
  Future<List<StudentDto>> getStudents(ISchoolCourseDto course) async {
    return studentsResult ??
        [
          (id: '111592347', name: '王大同'),
          (id: '111360109', name: '何承軒'),
          (id: '112360104', name: '孫培鈞'),
          (id: '111590453', name: '張竣崴'),
          (id: '112810006', name: '李圓凱'),
        ];
  }

  @override
  Future<List<MaterialRefDto>> getMaterials(ISchoolCourseDto course) async {
    if (materialsResult case final result?) return result;

    final c = course.courseNumber.isNotEmpty
        ? course
        : (courseNumber: '324647', internalId: '10090205');

    return [
      (
        course: c,
        title: 'Python-6-2023-0913',
        href: 'jtaYElDtPEXlaW8_Qv2wxWqssM7ith',
      ),
      (
        course: c,
        title: '教育大數據微學程-學習護照',
        href: 'NgOBKdDO8dL8A5Sh3Vz3SkTZ9sT58i',
      ),
      (
        course: c,
        title: '[錄] 09131025',
        href: 'nr8-YzItjO1YRyoQbiPCmGhHXJuk4z',
      ),
      (
        course: c,
        title: 'Blockly_Maze',
        href: 'hC-BrNCI2-Ho25bmCleEcQ,,',
      ),
      (
        course: c,
        title: 'Chap 01-認識 Python-richwang',
        href: 'j5Joz_BH8cT2xM8vTOrQOE1VSrL5TL',
      ),
      (
        course: c,
        title: 'Chap 02-資料型別、變數與運算子-richwang',
        href: 'bSIzva1DuyYTy1TSPRLdwIOJW9g_kd',
      ),
      (
        course: c,
        title: '[錄] 10041011',
        href: 'nr8-YzItjO13lC_MUisMuPLEaPOrok',
      ),
      (
        course: c,
        title: 'Python-6-Seat-Portrait',
        href: 'jtaYElDtPEUbt8OK0bTJuahHaVTpl6',
      ),
    ];
  }

  @override
  Future<MaterialDto> getMaterial(MaterialRefDto material) async {
    return materialResult ??
        (
          downloadUrl: Uri.parse(
            'https://istudy.ntut.edu.tw/learn/path/download.php?id=mock',
          ),
          referer: null,
          streamable: false,
        );
  }
}
