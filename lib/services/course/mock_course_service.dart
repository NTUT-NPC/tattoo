import 'package:tattoo/models/course.dart';
import 'package:tattoo/services/course/course_service.dart';

/// Mock implementation of [CourseService] for repository unit tests
/// and demo mode.
class MockCourseService implements CourseService {
  List<SemesterDto>? semesterListResult;
  List<ScheduleDto>? courseTableResult;
  CourseDto? courseResult;
  TeacherDto? teacherResult;
  SyllabusDto? syllabusResult;

  @override
  Future<List<SemesterDto>> getCourseSemesterList() async {
    return semesterListResult ??
        [
          (year: 114, term: 1),
          (year: 113, term: 2),
          (year: 113, term: 1),
          (year: 112, term: 2),
          (year: 112, term: 1),
        ];
  }

  @override
  Future<List<ScheduleDto>> getCourseTable({
    required String username,
    required SemesterDto semester,
  }) async {
    if (courseTableResult != null) return courseTableResult!;
    return switch (semester) {
      (year: 114, term: 1) => [
        (
          number: null,
          course: (id: null, nameZh: '班週會及導師時間', nameEn: 'Class Meeting'),
          phase: null,
          credits: null,
          hours: null,
          type: null,
          teachers: null,
          classes: null,
          schedule: [
            (day: .tuesday, period: .third, classroom: null),
            (day: .tuesday, period: .fourth, classroom: null),
          ],
          status: null,
          language: null,
          syllabusIds: null,
          remarks: null,
        ),
        (
          number: '347779',
          course: (
            id: '3603005',
            nameZh: '通訊系統實習',
            nameEn: 'Communication System Lab.',
          ),
          phase: 1,
          credits: 1.0,
          hours: 3,
          type: '必',
          teachers: [(id: '12442', nameZh: '崔紘嘉', nameEn: 'Horng-Jia Tsue')],
          classes: [(id: '2905', nameZh: '電子三甲', nameEn: '4EN3A')],
          schedule: [
            (
              day: .friday,
              period: .second,
              classroom: (id: '288', name: '綜科306'),
            ),
            (
              day: .friday,
              period: .third,
              classroom: (id: '288', name: '綜科306'),
            ),
            (
              day: .friday,
              period: .fourth,
              classroom: (id: '288', name: '綜科306'),
            ),
          ],
          status: null,
          language: null,
          syllabusIds: ['12442'],
          remarks: null,
        ),
        (
          number: '347780',
          course: (
            id: '3603006',
            nameZh: '應用軟體設計實習',
            nameEn: 'Application Software Design Lab.',
          ),
          phase: 1,
          credits: 1.0,
          hours: 3,
          type: '必',
          teachers: [(id: '11437', nameZh: '黃士嘉', nameEn: 'Shih-Chia Huang')],
          classes: [(id: '2905', nameZh: '電子三甲', nameEn: '4EN3A')],
          schedule: [
            (
              day: .friday,
              period: .fifth,
              classroom: (id: '157', name: '共同413'),
            ),
            (
              day: .friday,
              period: .sixth,
              classroom: (id: '157', name: '共同413'),
            ),
            (
              day: .friday,
              period: .seventh,
              classroom: (id: '157', name: '共同413'),
            ),
          ],
          status: null,
          language: null,
          syllabusIds: ['11437'],
          remarks: '計中電腦教室',
        ),
        (
          number: '347781',
          course: (
            id: '3603009',
            nameZh: '實務專題(一)',
            nameEn: 'Special Projects (I)',
          ),
          phase: 1,
          credits: 2.0,
          hours: 6,
          type: '必',
          teachers: [
            (id: '10605', nameZh: '余政杰', nameEn: null),
            (id: '11636', nameZh: '李昭賢', nameEn: null),
            (id: '10823', nameZh: '林信標', nameEn: null),
            (id: '10459', nameZh: '段裘慶', nameEn: null),
            (id: '11246', nameZh: '范育成', nameEn: null),
            (id: '11678', nameZh: '陳晏笙', nameEn: null),
            (id: '11991', nameZh: '陳維昌', nameEn: null),
            (id: '11130', nameZh: '黃育賢', nameEn: null),
            (id: '11894', nameZh: '楊濠瞬', nameEn: null),
            (id: '12231', nameZh: '潘孟鉉', nameEn: null),
          ],
          classes: [(id: '2905', nameZh: '電子三甲', nameEn: '4EN3A')],
          schedule: null,
          status: null,
          language: null,
          // Not every teacher submits a syllabus: 8 of the 10 here.
          syllabusIds: [
            '10605',
            '11636',
            '10823',
            '10459',
            '11246',
            '11678',
            '11130',
            '12231',
          ],
          remarks: null,
        ),
        (
          number: '347782',
          course: (
            id: '3603090',
            nameZh: '專題討論',
            nameEn: 'Engineering Seminar',
          ),
          phase: 1,
          credits: 1.0,
          hours: 2,
          type: '必',
          teachers: [(id: '11232', nameZh: '邱弘緯', nameEn: 'CHIU HUNG WEI')],
          classes: [(id: '2905', nameZh: '電子三甲', nameEn: '4EN3A')],
          schedule: [
            (day: .wednesday, period: .seventh, classroom: null),
            (day: .wednesday, period: .eighth, classroom: null),
          ],
          status: null,
          language: null,
          syllabusIds: ['11232'],
          remarks: null,
        ),
        (
          number: '347784',
          course: (
            id: '3602061',
            nameZh: '計算機結構',
            nameEn: 'Computer Architecture',
          ),
          phase: 1,
          credits: 3.0,
          hours: 3,
          type: '選',
          teachers: [(id: '12376', nameZh: '郭宏源', nameEn: 'Kuo,Hung-Yuan')],
          classes: [
            (id: '2905', nameZh: '電子三甲', nameEn: '4EN3A'),
            (id: '2906', nameZh: '電子三乙', nameEn: '4EN3B'),
          ],
          schedule: [
            (
              day: .thursday,
              period: .second,
              classroom: (id: '46', name: '三教303'),
            ),
            (
              day: .thursday,
              period: .third,
              classroom: (id: '46', name: '三教303'),
            ),
            (
              day: .thursday,
              period: .fourth,
              classroom: (id: '46', name: '三教303'),
            ),
          ],
          status: '撤選',
          language: '中英雙語',
          syllabusIds: ['12376'],
          remarks: '電子大三合開',
        ),
        (
          number: '347793',
          course: (
            id: '3603088',
            nameZh: '視窗程式設計',
            nameEn: 'Windows Programming',
          ),
          phase: 1,
          credits: 3.0,
          hours: 3,
          type: '選',
          teachers: [(id: '12605', nameZh: '吳亦超', nameEn: 'Yi-Chao Wu')],
          classes: [
            (id: '2905', nameZh: '電子三甲', nameEn: '4EN3A'),
            (id: '2906', nameZh: '電子三乙', nameEn: '4EN3B'),
          ],
          schedule: [
            (
              day: .monday,
              period: .fifth,
              classroom: (id: '353', name: '綜科104'),
            ),
            (
              day: .monday,
              period: .sixth,
              classroom: (id: '353', name: '綜科104'),
            ),
            (
              day: .monday,
              period: .ninth,
              classroom: (id: '353', name: '綜科104'),
            ),
          ],
          status: null,
          language: null,
          syllabusIds: ['12605'],
          remarks: '電子大三合開',
        ),
        (
          number: '348337',
          course: (
            id: '3602012',
            nameZh: '電路學(一)',
            nameEn: 'Circuit Theory (I)',
          ),
          phase: 1,
          credits: 3.0,
          hours: 3,
          type: '必',
          teachers: [(id: '11678', nameZh: '陳晏笙', nameEn: 'Yen-Sheng Chen')],
          classes: [(id: '3022', nameZh: '電子二甲', nameEn: '4EN2A')],
          schedule: [
            (
              day: .monday,
              period: .seventh,
              classroom: (id: '561', name: '先鋒501'),
            ),
            (
              day: .monday,
              period: .eighth,
              classroom: (id: '561', name: '先鋒501'),
            ),
            (
              day: .thursday,
              period: .eighth,
              classroom: (id: '561', name: '先鋒501'),
            ),
          ],
          status: null,
          language: '英語',
          syllabusIds: ['11678'],
          remarks: '半導體二和電子二甲合開',
        ),
        (
          number: '348881',
          course: (id: '1401032', nameZh: '微積分', nameEn: 'Calculus'),
          phase: 1,
          credits: 3.0,
          hours: 3,
          type: '必',
          teachers: [(id: '24588', nameZh: '林建洲', nameEn: 'Lin Chien-Chou')],
          classes: [(id: '3129', nameZh: '電子一乙', nameEn: '4EN1B')],
          schedule: [
            (
              day: .wednesday,
              period: .second,
              classroom: (id: '21', name: '二教203'),
            ),
            (
              day: .wednesday,
              period: .third,
              classroom: (id: '21', name: '二教203'),
            ),
            (
              day: .wednesday,
              period: .fourth,
              classroom: (id: '21', name: '二教203'),
            ),
          ],
          status: null,
          language: null,
          syllabusIds: ['24588'],
          remarks: null,
        ),
        (
          number: '353004',
          course: (
            id: '1418002',
            nameZh: '創新思考',
            nameEn: 'Innovative Thinking',
          ),
          phase: 1,
          credits: 2.0,
          hours: 2,
          type: '通',
          teachers: [(id: '24627', nameZh: '楊欣茹', nameEn: 'Hsin-Ju Yang')],
          classes: [
            (id: '2883', nameZh: '博雅課程(十)', nameEn: 'Core Curriculum (X)'),
          ],
          schedule: [
            (
              day: .thursday,
              period: .fifth,
              classroom: (id: '30', name: '二教305'),
            ),
            (
              day: .thursday,
              period: .sixth,
              classroom: (id: '30', name: '二教305'),
            ),
          ],
          status: null,
          language: null,
          syllabusIds: ['24627'],
          remarks: '創新與創業向度',
        ),
        (
          number: '357834',
          course: (
            id: '1420003',
            nameZh: '資訊行為導論',
            nameEn: 'Introduction to information behaviors',
          ),
          phase: 1,
          credits: 2.0,
          hours: 2,
          type: '必',
          teachers: null,
          classes: [
            (
              id: '589',
              nameZh: '博雅選修—跨校',
              nameEn: 'Core Curriculum (Optional) - Inter-school',
            ),
          ],
          schedule: [
            (day: .monday, period: .third, classroom: null),
            (day: .monday, period: .fourth, classroom: null),
          ],
          status: null,
          language: null,
          syllabusIds: null,
          remarks: '北醫/自然與科學/教師邱子恒/3001教室',
        ),
      ],
      (year: 113, term: 2) => [
        (
          number: null,
          course: (id: null, nameZh: '班週會及導師時間', nameEn: 'Class Meeting'),
          phase: null,
          credits: null,
          hours: null,
          type: null,
          teachers: null,
          classes: null,
          schedule: [
            (day: .tuesday, period: .third, classroom: null),
            (day: .tuesday, period: .fourth, classroom: null),
          ],
          status: null,
          language: null,
          syllabusIds: null,
          remarks: null,
        ),
        (
          number: '340433',
          course: (
            id: '3603062',
            nameZh: '數位系統設計實習',
            nameEn: 'Digital System Design Lab.',
          ),
          phase: 1,
          credits: 1.0,
          hours: 3,
          type: '必',
          teachers: [(id: '12376', nameZh: '郭宏源', nameEn: 'Kuo,Hung-Yuan')],
          classes: [
            (id: '2788', nameZh: '電子三甲', nameEn: '4EN3A'),
            (id: '2789', nameZh: '電子三乙', nameEn: '4EN3B'),
          ],
          schedule: [
            (
              day: .wednesday,
              period: .second,
              classroom: (id: '291', name: '綜科501'),
            ),
            (
              day: .wednesday,
              period: .third,
              classroom: (id: '291', name: '綜科501'),
            ),
            (
              day: .wednesday,
              period: .fourth,
              classroom: (id: '291', name: '綜科501'),
            ),
          ],
          status: null,
          language: null,
          syllabusIds: ['12376'],
          remarks: '電子大三合開',
        ),
        (
          number: '340435',
          course: (
            id: '3603090',
            nameZh: '專題討論',
            nameEn: 'Engineering Seminar',
          ),
          phase: 2,
          credits: 1.0,
          hours: 2,
          type: '必',
          teachers: [(id: '10496', nameZh: '李文達', nameEn: 'LEE NEW-TA')],
          classes: [(id: '2788', nameZh: '電子三甲', nameEn: '4EN3A')],
          schedule: [
            (day: .wednesday, period: .seventh, classroom: null),
            (day: .wednesday, period: .eighth, classroom: null),
          ],
          status: null,
          language: null,
          syllabusIds: ['10496'],
          remarks: null,
        ),
        (
          number: '340436',
          course: (
            id: '3604004',
            nameZh: '實務專題(二)',
            nameEn: 'Special Projects (II)',
          ),
          phase: 1,
          credits: 2.0,
          hours: 6,
          type: '必',
          teachers: [
            (id: '10605', nameZh: '余政杰', nameEn: null),
            (id: '10823', nameZh: '林信標', nameEn: null),
            (id: '10459', nameZh: '段裘慶', nameEn: null),
            (id: '11467', nameZh: '胡心卉', nameEn: null),
            (id: '12376', nameZh: '郭宏源', nameEn: null),
            (id: '11130', nameZh: '黃育賢', nameEn: null),
            (id: '12231', nameZh: '潘孟鉉', nameEn: null),
            (id: '12245', nameZh: '賴建宏', nameEn: null),
            (id: '12232', nameZh: '鍾明桉', nameEn: null),
          ],
          classes: [(id: '2788', nameZh: '電子三甲', nameEn: '4EN3A')],
          schedule: null,
          status: null,
          language: null,
          syllabusIds: [
            '10605',
            '10823',
            '10459',
            '11467',
            '12376',
            '11130',
            '12231',
            '12245',
            '12232',
          ],
          remarks: null,
        ),
        (
          number: '340437',
          course: (
            id: '3603059',
            nameZh: '作業系統',
            nameEn: 'Operating Systems',
          ),
          phase: 1,
          credits: 3.0,
          hours: 3,
          type: '選',
          teachers: [(id: '10459', nameZh: '段裘慶', nameEn: 'CHYON-CHING TUAN')],
          classes: [
            (id: '2788', nameZh: '電子三甲', nameEn: '4EN3A'),
            (id: '2789', nameZh: '電子三乙', nameEn: '4EN3B'),
          ],
          schedule: [
            (
              day: .tuesday,
              period: .fifth,
              classroom: (id: '20', name: '二教202'),
            ),
            (
              day: .tuesday,
              period: .sixth,
              classroom: (id: '20', name: '二教202'),
            ),
            (
              day: .tuesday,
              period: .seventh,
              classroom: (id: '20', name: '二教202'),
            ),
          ],
          status: null,
          language: null,
          syllabusIds: ['10459'],
          remarks: '電子大三合開',
        ),
        (
          number: '340689',
          course: (
            id: '5903326',
            nameZh: '開源系統軟體與實務',
            nameEn: 'Open-Source System Software and Practice',
          ),
          phase: 1,
          credits: 3.0,
          hours: 3,
          type: '選',
          teachers: [(id: '12384', nameZh: '張世豪', nameEn: 'Chang, Shih-Hao')],
          classes: [(id: '2798', nameZh: '資工三', nameEn: '4CSIE3')],
          schedule: [
            (
              day: .tuesday,
              period: .second,
              classroom: (id: '450', name: '六教725'),
            ),
            (
              day: .friday,
              period: .fifth,
              classroom: (id: '450', name: '六教725'),
            ),
            (
              day: .friday,
              period: .sixth,
              classroom: (id: '450', name: '六教725'),
            ),
          ],
          status: null,
          language: null,
          syllabusIds: ['12384'],
          remarks: null,
        ),
        (
          number: '341048',
          course: (
            id: '3602009',
            nameZh: '電子學(二)',
            nameEn: 'Electronics (II)',
          ),
          phase: 1,
          credits: 3.0,
          hours: 3,
          type: '必',
          teachers: [(id: '11130', nameZh: '黃育賢', nameEn: 'Huang Yu-Hsien')],
          classes: [(id: '2905', nameZh: '電子二甲', nameEn: '4EN2A')],
          schedule: [
            (
              day: .thursday,
              period: .third,
              classroom: (id: '26', name: '二教301'),
            ),
            (
              day: .thursday,
              period: .fourth,
              classroom: (id: '26', name: '二教301'),
            ),
            (
              day: .wednesday,
              period: .sixth,
              classroom: (id: '26', name: '二教301'),
            ),
          ],
          status: '撤選',
          language: null,
          syllabusIds: ['11130'],
          remarks: null,
        ),
        (
          number: '341065',
          course: (
            id: '3602005',
            nameZh: '工程數學(二)',
            nameEn: 'Engineering Mathematics (II)',
          ),
          phase: 1,
          credits: 3.0,
          hours: 3,
          type: '必',
          teachers: [(id: '11635', nameZh: '曾柏軒', nameEn: 'Po-Hsuan Tseng')],
          classes: [(id: '2906', nameZh: '電子二乙', nameEn: '4EN2B')],
          schedule: [
            (
              day: .tuesday,
              period: .eighth,
              classroom: (id: '25', name: '二教207'),
            ),
            (
              day: .monday,
              period: .ninth,
              classroom: (id: '25', name: '二教207'),
            ),
            (
              day: .tuesday,
              period: .ninth,
              classroom: (id: '25', name: '二教207'),
            ),
          ],
          status: '撤選',
          language: '英語',
          syllabusIds: ['11635'],
          remarks: null,
        ),
        (
          number: '341869',
          course: (
            id: '1400039',
            nameZh: '英文溝通與應用(二)',
            nameEn: 'English Communication and Application II (ECA Courses)',
          ),
          phase: 1,
          credits: 2.0,
          hours: 3,
          type: '必',
          teachers: [(id: '12380', nameZh: '吳宙霖', nameEn: 'Carter,Jon Robert')],
          classes: [(id: '3039', nameZh: '資財一', nameEn: '4IFM1')],
          schedule: [
            (
              day: .friday,
              period: .third,
              classroom: (id: '9', name: '一教301'),
            ),
            (
              day: .friday,
              period: .fourth,
              classroom: (id: '9', name: '一教301'),
            ),
            (
              day: .thursday,
              period: .eighth,
              classroom: (id: '9', name: '一教301'),
            ),
          ],
          status: null,
          language: null,
          syllabusIds: ['12380'],
          remarks: '高級B',
        ),
        (
          number: '345588',
          course: (
            id: '3602051',
            nameZh: '計算機演算法',
            nameEn: 'Computer Algorithms',
          ),
          phase: 1,
          credits: 3.0,
          hours: 3,
          type: '選',
          teachers: [(id: '12245', nameZh: '賴建宏', nameEn: 'Chien-Hung Lai')],
          classes: [
            (id: '2788', nameZh: '電子三甲', nameEn: '4EN3A'),
            (id: '2789', nameZh: '電子三乙', nameEn: '4EN3B'),
          ],
          schedule: [
            (
              day: .friday,
              period: .seventh,
              classroom: (id: '291', name: '綜科501'),
            ),
            (
              day: .friday,
              period: .eighth,
              classroom: (id: '291', name: '綜科501'),
            ),
            (
              day: .friday,
              period: .ninth,
              classroom: (id: '291', name: '綜科501'),
            ),
          ],
          status: null,
          language: null,
          syllabusIds: ['12245'],
          remarks: '電子大三合開',
        ),
        (
          number: '346146',
          course: (
            id: '1418003',
            nameZh: '創業概論',
            nameEn: 'Introduction to Entrepreneurial',
          ),
          phase: 1,
          credits: 2.0,
          hours: 2,
          type: '通',
          teachers: [(id: '24602', nameZh: '陳正中', nameEn: 'Cheng,jeng-chung')],
          classes: [
            (id: '2760', nameZh: '博雅課程(四)', nameEn: 'Core Curriculum (IV)'),
          ],
          schedule: [
            (
              day: .monday,
              period: .seventh,
              classroom: (id: '452', name: '六教727'),
            ),
            (
              day: .monday,
              period: .eighth,
              classroom: (id: '452', name: '六教727'),
            ),
          ],
          status: null,
          language: null,
          syllabusIds: ['24602'],
          remarks: '創新與創業向度',
        ),
        (
          number: '346205',
          course: (
            id: '1410090',
            nameZh: '環境教育',
            nameEn: 'Environmental Education',
          ),
          phase: 1,
          credits: 2.0,
          hours: 2,
          type: '通',
          teachers: [(id: '24530', nameZh: '何俊頤', nameEn: 'Chun-Yi Ho')],
          classes: [
            (id: '2884', nameZh: '博雅課程(十一)', nameEn: 'Core Curriculum (XI)'),
          ],
          schedule: [
            (
              day: .thursday,
              period: .fifth,
              classroom: (id: '572', name: '先鋒201'),
            ),
            (
              day: .thursday,
              period: .sixth,
              classroom: (id: '572', name: '先鋒201'),
            ),
          ],
          status: null,
          language: null,
          syllabusIds: ['24530'],
          remarks: '社會與法治向度',
        ),
      ],
      (year: 113, term: 1) => [
        (
          number: null,
          course: (id: null, nameZh: '班週會及導師時間', nameEn: 'Class Meeting'),
          phase: null,
          credits: null,
          hours: null,
          type: null,
          teachers: null,
          classes: null,
          schedule: [
            (day: .tuesday, period: .third, classroom: null),
            (day: .tuesday, period: .fourth, classroom: null),
          ],
          status: null,
          language: null,
          syllabusIds: null,
          remarks: null,
        ),
        (
          number: '334011',
          course: (
            id: '3603005',
            nameZh: '通訊系統實習',
            nameEn: 'Communication System Lab.',
          ),
          phase: 1,
          credits: 1.0,
          hours: 3,
          type: '必',
          teachers: [(id: '12442', nameZh: '崔紘嘉', nameEn: 'Horng-Jia Tsue')],
          classes: [(id: '2788', nameZh: '電子三甲', nameEn: '4EN3A')],
          schedule: [
            (
              day: .friday,
              period: .second,
              classroom: (id: '288', name: '綜科306'),
            ),
            (
              day: .friday,
              period: .third,
              classroom: (id: '288', name: '綜科306'),
            ),
            (
              day: .friday,
              period: .fourth,
              classroom: (id: '288', name: '綜科306'),
            ),
          ],
          status: null,
          language: null,
          syllabusIds: ['12442'],
          remarks: null,
        ),
        (
          number: '334012',
          course: (
            id: '3603006',
            nameZh: '應用軟體設計實習',
            nameEn: 'Application Software Design Lab.',
          ),
          phase: 1,
          credits: 1.0,
          hours: 3,
          type: '必',
          teachers: [(id: '11437', nameZh: '黃士嘉', nameEn: 'Shih-Chia Huang')],
          classes: [(id: '2788', nameZh: '電子三甲', nameEn: '4EN3A')],
          schedule: [
            (
              day: .friday,
              period: .fifth,
              classroom: (id: '154', name: '共同312'),
            ),
            (
              day: .friday,
              period: .sixth,
              classroom: (id: '154', name: '共同312'),
            ),
            (
              day: .friday,
              period: .seventh,
              classroom: (id: '154', name: '共同312'),
            ),
          ],
          status: null,
          language: null,
          syllabusIds: ['11437'],
          remarks: '計中電腦教室',
        ),
        (
          number: '334013',
          course: (
            id: '3603009',
            nameZh: '實務專題(一)',
            nameEn: 'Special Projects (I)',
          ),
          phase: 1,
          credits: 2.0,
          hours: 6,
          type: '必',
          teachers: [
            (id: '10605', nameZh: '余政杰', nameEn: null),
            (id: '10459', nameZh: '段裘慶', nameEn: null),
            (id: '11246', nameZh: '范育成', nameEn: null),
            (id: '10618', nameZh: '孫卓勳', nameEn: null),
            (id: '12376', nameZh: '郭宏源', nameEn: null),
            (id: '11130', nameZh: '黃育賢', nameEn: null),
            (id: '12231', nameZh: '潘孟鉉', nameEn: null),
            (id: '11682', nameZh: '鄭瑞清', nameEn: null),
            (id: '12245', nameZh: '賴建宏', nameEn: null),
          ],
          classes: [(id: '2788', nameZh: '電子三甲', nameEn: '4EN3A')],
          schedule: null,
          status: null,
          language: null,
          syllabusIds: [
            '10605',
            '10459',
            '11246',
            '10618',
            '12376',
            '11130',
            '12231',
            '11682',
            '12245',
          ],
          remarks: null,
        ),
        (
          number: '334014',
          course: (
            id: '3603090',
            nameZh: '專題討論',
            nameEn: 'Engineering Seminar',
          ),
          phase: 1,
          credits: 1.0,
          hours: 2,
          type: '必',
          teachers: [(id: '10496', nameZh: '李文達', nameEn: 'LEE NEW-TA')],
          classes: [(id: '2788', nameZh: '電子三甲', nameEn: '4EN3A')],
          schedule: [
            (day: .wednesday, period: .seventh, classroom: null),
            (day: .wednesday, period: .eighth, classroom: null),
          ],
          status: null,
          language: null,
          syllabusIds: ['10496'],
          remarks: null,
        ),
        (
          number: '334016',
          course: (
            id: '3602061',
            nameZh: '計算機結構',
            nameEn: 'Computer Architecture',
          ),
          phase: 1,
          credits: 3.0,
          hours: 3,
          type: '選',
          teachers: [(id: '12376', nameZh: '郭宏源', nameEn: 'Kuo,Hung-Yuan')],
          classes: [
            (id: '2788', nameZh: '電子三甲', nameEn: '4EN3A'),
            (id: '2789', nameZh: '電子三乙', nameEn: '4EN3B'),
          ],
          schedule: [
            (
              day: .tuesday,
              period: .fifth,
              classroom: (id: '53', name: '三教403'),
            ),
            (
              day: .tuesday,
              period: .sixth,
              classroom: (id: '53', name: '三教403'),
            ),
            (
              day: .tuesday,
              period: .seventh,
              classroom: (id: '53', name: '三教403'),
            ),
          ],
          status: null,
          language: '中英雙語',
          syllabusIds: ['12376'],
          remarks: '電子大三合開',
        ),
        (
          number: '334833',
          course: (
            id: 'C002004',
            nameZh: '工程數學(一)',
            nameEn: 'Engineering Mathematics (I)',
          ),
          phase: 1,
          credits: 3.0,
          hours: 3,
          type: '選',
          teachers: [(id: '12239', nameZh: '陳柏端', nameEn: 'Po-Tuan Cheng')],
          classes: [(id: '2925', nameZh: '技優專班二', nameEn: '4CMEE2')],
          schedule: [
            (
              day: .tuesday,
              period: .second,
              classroom: (id: '67', name: '三教510'),
            ),
            (
              day: .wednesday,
              period: .fifth,
              classroom: (id: '67', name: '三教510'),
            ),
            (
              day: .wednesday,
              period: .sixth,
              classroom: (id: '67', name: '三教510'),
            ),
          ],
          status: null,
          language: null,
          syllabusIds: ['12239'],
          remarks: '限技優專班同學。',
        ),
        (
          number: '337794',
          course: (
            id: '1401036',
            nameZh: '微積分及演習',
            nameEn: 'Calculus',
          ),
          phase: 1,
          credits: 3.0,
          hours: 4,
          type: '選',
          teachers: [(id: '23969', nameZh: '洪祥', nameEn: 'HUNG CHEN HSIANG')],
          classes: [
            (
              id: '2402',
              nameZh: '技優學生專班課程',
              nameEn: 'Courses for Skilled Students',
            ),
          ],
          schedule: [
            (
              day: .tuesday,
              period: .ninth,
              classroom: (id: '35', name: '三教109'),
            ),
            (
              day: .wednesday,
              period: .ninth,
              classroom: (id: '35', name: '三教109'),
            ),
            (
              day: .tuesday,
              period: .aPeriod,
              classroom: (id: '35', name: '三教109'),
            ),
            (
              day: .wednesday,
              period: .aPeriod,
              classroom: (id: '35', name: '三教109'),
            ),
          ],
          status: null,
          language: null,
          syllabusIds: ['23969'],
          remarks: '◎限技優學生修習',
        ),
        (
          number: '338974',
          course: (
            id: '1415017',
            nameZh: '職場倫理',
            nameEn: 'Workplace Ethics',
          ),
          phase: 1,
          credits: 2.0,
          hours: 2,
          type: '通',
          teachers: [(id: '24363', nameZh: '陳雪芳', nameEn: 'Hsueh-Fang Chen')],
          classes: [
            (id: '2760', nameZh: '博雅課程(四)', nameEn: 'Core Curriculum (IV)'),
          ],
          schedule: [
            (
              day: .monday,
              period: .seventh,
              classroom: (id: '563', name: '先鋒503'),
            ),
            (
              day: .monday,
              period: .eighth,
              classroom: (id: '563', name: '先鋒503'),
            ),
          ],
          status: null,
          language: null,
          syllabusIds: ['24363'],
          remarks: '人文與藝術向度',
        ),
        (
          number: '339025',
          course: (
            id: '1411022',
            nameZh: '音樂概論',
            nameEn: 'Introduction to Music',
          ),
          phase: 1,
          credits: 2.0,
          hours: 2,
          type: '通',
          teachers: [(id: '22465', nameZh: '陳雪燕', nameEn: 'Hsueh-Yen Chen')],
          classes: [
            (id: '2883', nameZh: '博雅課程(十)', nameEn: 'Core Curriculum (X)'),
          ],
          schedule: [
            (
              day: .thursday,
              period: .third,
              classroom: (id: '74', name: '四教203'),
            ),
            (
              day: .thursday,
              period: .fourth,
              classroom: (id: '74', name: '四教203'),
            ),
          ],
          status: null,
          language: null,
          syllabusIds: ['22465'],
          remarks: '人文與藝術向度',
        ),
      ],
      (year: 112, term: 2) => [
        (
          number: null,
          course: (id: null, nameZh: '班週會及導師時間', nameEn: 'Class Meeting'),
          phase: null,
          credits: null,
          hours: null,
          type: null,
          teachers: null,
          classes: null,
          schedule: [
            (day: .tuesday, period: .third, classroom: null),
            (day: .tuesday, period: .fourth, classroom: null),
          ],
          status: null,
          language: null,
          syllabusIds: null,
          remarks: null,
        ),
        (
          number: '327246',
          course: (
            id: '3602005',
            nameZh: '工程數學(二)',
            nameEn: 'Engineering Mathematics (II)',
          ),
          phase: 1,
          credits: 3.0,
          hours: 3,
          type: '必',
          teachers: [(id: '11635', nameZh: '曾柏軒', nameEn: 'Po-Hsuan Tseng')],
          classes: [(id: '2788', nameZh: '電子二甲', nameEn: '4EN2A')],
          schedule: [
            (
              day: .tuesday,
              period: .seventh,
              classroom: (id: '424', name: '六教227'),
            ),
            (
              day: .thursday,
              period: .eighth,
              classroom: (id: '424', name: '六教227'),
            ),
            (
              day: .thursday,
              period: .ninth,
              classroom: (id: '424', name: '六教227'),
            ),
          ],
          status: null,
          language: '英語',
          syllabusIds: ['11635'],
          remarks: '與電資二合開',
        ),
        (
          number: '327247',
          course: (
            id: '3602009',
            nameZh: '電子學(二)',
            nameEn: 'Electronics (II)',
          ),
          phase: 1,
          credits: 3.0,
          hours: 3,
          type: '必',
          teachers: [(id: '11391', nameZh: '王多柏', nameEn: 'To-Po Wang')],
          classes: [(id: '2788', nameZh: '電子二甲', nameEn: '4EN2A')],
          schedule: [
            (
              day: .thursday,
              period: .third,
              classroom: (id: '26', name: '二教301'),
            ),
            (
              day: .thursday,
              period: .fourth,
              classroom: (id: '26', name: '二教301'),
            ),
            (
              day: .tuesday,
              period: .fifth,
              classroom: (id: '26', name: '二教301'),
            ),
          ],
          status: null,
          language: null,
          syllabusIds: ['11391'],
          remarks: null,
        ),
        (
          number: '327248',
          course: (
            id: '3602010',
            nameZh: '電子學實習(二)',
            nameEn: 'Electronic Lab. (II)',
          ),
          phase: 1,
          credits: 1.0,
          hours: 3,
          type: '必',
          teachers: [(id: '11246', nameZh: '范育成', nameEn: 'YU-CHENG FAN')],
          classes: [(id: '2788', nameZh: '電子二甲', nameEn: '4EN2A')],
          schedule: [
            (
              day: .friday,
              period: .third,
              classroom: (id: '292', name: '綜科502'),
            ),
            (
              day: .friday,
              period: .fourth,
              classroom: (id: '292', name: '綜科502'),
            ),
            (
              day: .friday,
              period: .fifth,
              classroom: (id: '292', name: '綜科502'),
            ),
          ],
          status: null,
          language: null,
          syllabusIds: ['11246'],
          remarks: null,
        ),
        (
          number: '327249',
          course: (
            id: '3602011',
            nameZh: '機率',
            nameEn: 'Probability',
          ),
          phase: 1,
          credits: 3.0,
          hours: 3,
          type: '必',
          teachers: [(id: '11010', nameZh: '曾恕銘', nameEn: 'Tseng Shu-ming')],
          classes: [(id: '2788', nameZh: '電子二甲', nameEn: '4EN2A')],
          schedule: [
            (
              day: .monday,
              period: .third,
              classroom: (id: '25', name: '二教207'),
            ),
            (
              day: .monday,
              period: .fourth,
              classroom: (id: '25', name: '二教207'),
            ),
            (
              day: .thursday,
              period: .seventh,
              classroom: (id: '26', name: '二教301'),
            ),
          ],
          status: null,
          language: null,
          syllabusIds: ['11010'],
          remarks: null,
        ),
        (
          number: '327250',
          course: (
            id: '3603063',
            nameZh: '電磁學',
            nameEn: 'Electromagnetics',
          ),
          phase: 1,
          credits: 3.0,
          hours: 3,
          type: '必',
          teachers: [(id: '10605', nameZh: '余政杰', nameEn: 'CHENG-CHEN YU')],
          classes: [(id: '2788', nameZh: '電子二甲', nameEn: '4EN2A')],
          schedule: [
            (
              day: .wednesday,
              period: .third,
              classroom: (id: '31', name: '二教306'),
            ),
            (
              day: .wednesday,
              period: .fourth,
              classroom: (id: '31', name: '二教306'),
            ),
            (
              day: .friday,
              period: .eighth,
              classroom: (id: '31', name: '二教306'),
            ),
          ],
          status: null,
          language: null,
          syllabusIds: ['10605'],
          remarks: null,
        ),
        (
          number: '327251',
          course: (
            id: '3602050',
            nameZh: '資料結構',
            nameEn: 'Data Structures',
          ),
          phase: 1,
          credits: 3.0,
          hours: 3,
          type: '選',
          teachers: [(id: '11636', nameZh: '李昭賢', nameEn: 'Lee, Chao-Hsien')],
          classes: [
            (id: '2788', nameZh: '電子二甲', nameEn: '4EN2A'),
            (id: '2789', nameZh: '電子二乙', nameEn: '4EN2B'),
          ],
          schedule: [
            (
              day: .wednesday,
              period: .fifth,
              classroom: (id: '55', name: '三教407'),
            ),
            (
              day: .wednesday,
              period: .sixth,
              classroom: (id: '55', name: '三教407'),
            ),
            (
              day: .wednesday,
              period: .seventh,
              classroom: (id: '55', name: '三教407'),
            ),
          ],
          status: null,
          language: null,
          syllabusIds: ['11636'],
          remarks: '電子二甲乙合開',
        ),
        (
          number: '327258',
          course: (
            id: '3603082',
            nameZh: '計算機組織',
            nameEn: 'Computer Organization',
          ),
          phase: 1,
          credits: 3.0,
          hours: 3,
          type: '選',
          teachers: [(id: '12376', nameZh: '郭宏源', nameEn: 'Kuo,Hung-Yuan')],
          classes: [
            (id: '2788', nameZh: '電子二甲', nameEn: '4EN2A'),
            (id: '2789', nameZh: '電子二乙', nameEn: '4EN2B'),
          ],
          schedule: [
            (
              day: .wednesday,
              period: .eighth,
              classroom: (id: '32', name: '二教307'),
            ),
            (
              day: .wednesday,
              period: .ninth,
              classroom: (id: '32', name: '二教307'),
            ),
            (
              day: .wednesday,
              period: .aPeriod,
              classroom: (id: '32', name: '二教307'),
            ),
          ],
          status: null,
          language: '中英雙語',
          syllabusIds: ['12376'],
          remarks: '電子二甲乙合開',
        ),
        (
          number: '331345',
          course: (
            id: '14E3073',
            nameZh: '進階專業英文- 電資(二)',
            nameEn:
                'Advanced ESP (Electrical Engineering and Computer Science) II',
          ),
          phase: 1,
          credits: 2.0,
          hours: 2,
          type: '必',
          teachers: [(id: '11967', nameZh: '郭政淳', nameEn: 'Jonathan Kuo')],
          classes: [
            (
              id: '2156',
              nameZh: '大二專業英文(二)',
              nameEn: 'Diversified English (II)',
            ),
          ],
          schedule: [
            (
              day: .monday,
              period: .fifth,
              classroom: (id: '66', name: '三教509'),
            ),
            (
              day: .monday,
              period: .sixth,
              classroom: (id: '66', name: '三教509'),
            ),
          ],
          status: null,
          language: null,
          syllabusIds: ['11967'],
          remarks: '高級',
        ),
        (
          number: '332227',
          course: (
            id: '1418001',
            nameZh: '創新與創業',
            nameEn: 'Innovation and Entrepreneurship',
          ),
          phase: 1,
          credits: 2.0,
          hours: 2,
          type: '通',
          teachers: [(id: '23915', nameZh: '吳奇靜', nameEn: 'Chi-ching Wu')],
          classes: [
            (id: '2760', nameZh: '博雅課程(四)', nameEn: 'Core Curriculum (IV)'),
          ],
          schedule: [
            (
              day: .monday,
              period: .seventh,
              classroom: (id: '563', name: '先鋒503'),
            ),
            (
              day: .monday,
              period: .eighth,
              classroom: (id: '563', name: '先鋒503'),
            ),
          ],
          status: null,
          language: null,
          syllabusIds: ['23915'],
          remarks: '106-108：創新與創業核心。109(含)後：創新與創業',
        ),
        (
          number: '332287',
          course: (
            id: '1410042',
            nameZh: '國際關係',
            nameEn: 'International relations',
          ),
          phase: 1,
          credits: 2.0,
          hours: 2,
          type: '通',
          teachers: [(id: '24489', nameZh: '陳郁芬', nameEn: 'CHEN YU FEN')],
          classes: [
            (id: '2884', nameZh: '博雅課程(十一)', nameEn: 'Core Curriculum (XI)'),
          ],
          schedule: [
            (
              day: .thursday,
              period: .fifth,
              classroom: (id: '30', name: '二教305'),
            ),
            (
              day: .thursday,
              period: .sixth,
              classroom: (id: '30', name: '二教305'),
            ),
          ],
          status: null,
          language: null,
          syllabusIds: ['24489'],
          remarks: '106-108：民主與法治選修。109(含)後：社會與法治',
        ),
      ],
      (year: 112, term: 1) => [
        (
          number: null,
          course: (id: null, nameZh: '班週會及導師時間', nameEn: 'Class Meeting'),
          phase: null,
          credits: null,
          hours: null,
          type: null,
          teachers: null,
          classes: null,
          schedule: [
            (day: .tuesday, period: .third, classroom: null),
            (day: .tuesday, period: .fourth, classroom: null),
          ],
          status: null,
          language: null,
          syllabusIds: null,
          remarks: null,
        ),
        (
          number: '320232',
          course: (
            id: '1400038',
            nameZh: '英文溝通與應用(一)',
            nameEn: 'English Communication and Application I (ECA Courses)',
          ),
          phase: 1,
          credits: 2.0,
          hours: 3,
          type: '必',
          teachers: [(id: '24112', nameZh: '章慧琴', nameEn: 'Hui-chin Chang')],
          classes: [(id: '2894', nameZh: '電機一甲', nameEn: '4EE1A')],
          schedule: [
            (
              day: .friday,
              period: .fifth,
              classroom: (id: '20', name: '二教202'),
            ),
            (
              day: .friday,
              period: .sixth,
              classroom: (id: '20', name: '二教202'),
            ),
            (
              day: .thursday,
              period: .seventh,
              classroom: (id: '20', name: '二教202'),
            ),
          ],
          status: null,
          language: null,
          syllabusIds: ['24112'],
          remarks: '初級',
        ),
        (
          number: '320426',
          course: (
            id: '1400099',
            nameZh: '服務學習',
            nameEn: 'Service Learning',
          ),
          phase: 1,
          credits: 0.0,
          hours: 1,
          type: '必',
          teachers: [(id: '24294', nameZh: '簡明昱', nameEn: 'Jeremiah Chien')],
          classes: [(id: '2906', nameZh: '電子一乙', nameEn: '4EN1B')],
          schedule: [
            (
              day: .wednesday,
              period: .eighth,
              classroom: (id: '75', name: '四教204'),
            ),
          ],
          status: null,
          language: null,
          syllabusIds: ['24294'],
          remarks: '*第一週必到，課程地點公告至「北科服務學習網」。',
        ),
        (
          number: '320427',
          course: (
            id: '1400102',
            nameZh: '大學入門與工程倫理',
            nameEn:
                'First step to achieving the goals of universities and Engineering Ethics',
          ),
          phase: 1,
          credits: 1.0,
          hours: 2,
          type: '必',
          teachers: [(id: '12491', nameZh: '劉凱鈞', nameEn: 'Kai-Chun Liu')],
          classes: [(id: '2906', nameZh: '電子一乙', nameEn: '4EN1B')],
          schedule: [
            (
              day: .friday,
              period: .third,
              classroom: (id: '21', name: '二教203'),
            ),
            (
              day: .friday,
              period: .fourth,
              classroom: (id: '21', name: '二教203'),
            ),
          ],
          status: null,
          language: null,
          syllabusIds: ['12491'],
          remarks: '9/22職能測驗於共科B1',
        ),
        (
          number: '320428',
          course: (id: '1404006', nameZh: '國文', nameEn: 'Chinese'),
          phase: 1,
          credits: 2.0,
          hours: 2,
          type: '必',
          teachers: [(id: '12079', nameZh: '黃琛傑', nameEn: 'HUANG CHEN-CHIEH')],
          classes: [(id: '2906', nameZh: '電子一乙', nameEn: '4EN1B')],
          schedule: [
            (
              day: .thursday,
              period: .third,
              classroom: (id: '21', name: '二教203'),
            ),
            (
              day: .thursday,
              period: .fourth,
              classroom: (id: '21', name: '二教203'),
            ),
          ],
          status: null,
          language: null,
          syllabusIds: ['12079'],
          remarks: null,
        ),
        (
          number: '320429',
          course: (id: '1401032', nameZh: '微積分', nameEn: 'Calculus'),
          phase: 1,
          credits: 3.0,
          hours: 3,
          type: '必',
          teachers: [(id: '11145', nameZh: '洪春凰', nameEn: 'Hong Chen-Huang')],
          classes: [(id: '2906', nameZh: '電子一乙', nameEn: '4EN1B')],
          schedule: [
            (
              day: .thursday,
              period: .second,
              classroom: (id: '32', name: '二教307'),
            ),
            (
              day: .wednesday,
              period: .third,
              classroom: (id: '26', name: '二教301'),
            ),
            (
              day: .wednesday,
              period: .fourth,
              classroom: (id: '26', name: '二教301'),
            ),
          ],
          status: null,
          language: null,
          syllabusIds: ['11145'],
          remarks: null,
        ),
        (
          number: '320430',
          course: (id: '1401041', nameZh: '物理', nameEn: 'Physics'),
          phase: 1,
          credits: 3.0,
          hours: 3,
          type: '必',
          teachers: [(id: '11067', nameZh: '洪魏寬', nameEn: 'WEI-KUAN HUNG')],
          classes: [(id: '2906', nameZh: '電子一乙', nameEn: '4EN1B')],
          schedule: [
            (
              day: .tuesday,
              period: .fifth,
              classroom: (id: '21', name: '二教203'),
            ),
            (
              day: .thursday,
              period: .fifth,
              classroom: (id: '21', name: '二教203'),
            ),
            (
              day: .thursday,
              period: .sixth,
              classroom: (id: '21', name: '二教203'),
            ),
          ],
          status: null,
          language: null,
          syllabusIds: ['11067'],
          remarks: null,
        ),
        (
          number: '320431',
          course: (
            id: '1401043',
            nameZh: '物理實驗',
            nameEn: 'Physics Lab.',
          ),
          phase: 1,
          credits: 1.0,
          hours: 3,
          type: '必',
          teachers: [(id: '11067', nameZh: '洪魏寬', nameEn: 'WEI-KUAN HUNG')],
          classes: [(id: '2906', nameZh: '電子一乙', nameEn: '4EN1B')],
          schedule: [
            (
              day: .tuesday,
              period: .sixth,
              classroom: (id: '523', name: '億光0628'),
            ),
            (
              day: .tuesday,
              period: .seventh,
              classroom: (id: '523', name: '億光0628'),
            ),
            (
              day: .tuesday,
              period: .eighth,
              classroom: (id: '523', name: '億光0628'),
            ),
          ],
          status: null,
          language: null,
          syllabusIds: ['11067'],
          remarks: null,
        ),
        (
          number: '320432',
          course: (
            id: '3601005',
            nameZh: '數位邏輯設計',
            nameEn: 'Digital Logic Design',
          ),
          phase: 1,
          credits: 3.0,
          hours: 3,
          type: '必',
          teachers: [(id: '11391', nameZh: '王多柏', nameEn: 'To-Po Wang')],
          classes: [(id: '2906', nameZh: '電子一乙', nameEn: '4EN1B')],
          schedule: [
            (
              day: .friday,
              period: .second,
              classroom: (id: '25', name: '二教207'),
            ),
            (
              day: .monday,
              period: .fifth,
              classroom: (id: '32', name: '二教307'),
            ),
            (
              day: .monday,
              period: .sixth,
              classroom: (id: '32', name: '二教307'),
            ),
          ],
          status: null,
          language: '英語',
          syllabusIds: ['11391'],
          remarks: 'EMI英文',
        ),
        (
          number: '320433',
          course: (
            id: '3601009',
            nameZh: '高階語言程式實習',
            nameEn: 'Understand the basic structure of programming languages.',
          ),
          phase: 1,
          credits: 1.0,
          hours: 3,
          type: '必',
          teachers: [(id: '11437', nameZh: '黃士嘉', nameEn: 'Shih-Chia Huang')],
          classes: [(id: '2906', nameZh: '電子一乙', nameEn: '4EN1B')],
          schedule: [
            (
              day: .friday,
              period: .seventh,
              classroom: (id: '155', name: '共同313'),
            ),
            (
              day: .friday,
              period: .eighth,
              classroom: (id: '155', name: '共同313'),
            ),
            (
              day: .friday,
              period: .ninth,
              classroom: (id: '155', name: '共同313'),
            ),
          ],
          status: null,
          language: null,
          syllabusIds: ['11437'],
          remarks: '計中電腦教室',
        ),
        (
          number: '320434',
          course: (
            id: '3601013',
            nameZh: '計算機概論',
            nameEn: 'Introduction to Computer Science',
          ),
          phase: 1,
          credits: 3.0,
          hours: 3,
          type: '必',
          teachers: [(id: '12376', nameZh: '郭宏源', nameEn: 'Kuo,Hung-Yuan')],
          classes: [(id: '2906', nameZh: '電子一乙', nameEn: '4EN1B')],
          schedule: [
            (
              day: .tuesday,
              period: .first,
              classroom: (id: '21', name: '二教203'),
            ),
            (
              day: .tuesday,
              period: .second,
              classroom: (id: '21', name: '二教203'),
            ),
            (
              day: .wednesday,
              period: .seventh,
              classroom: (id: '21', name: '二教203'),
            ),
          ],
          status: null,
          language: null,
          syllabusIds: ['12376'],
          remarks: null,
        ),
        (
          number: '323453',
          course: (
            id: '1001002',
            nameZh: '體育',
            nameEn: 'Physical Education',
          ),
          phase: 1,
          credits: 0.0,
          hours: 2,
          type: '必',
          teachers: [(id: '11172', nameZh: '林威玲', nameEn: 'Lin Wei Ling')],
          classes: [
            (id: '447', nameZh: '體育專項(一)', nameEn: 'PE courses-1'),
          ],
          schedule: [
            (day: .wednesday, period: .first, classroom: null),
            (day: .wednesday, period: .second, classroom: null),
          ],
          status: null,
          language: null,
          syllabusIds: ['11172'],
          remarks: '*肢體美學A',
        ),
      ],
      _ => const [],
    };
  }

  @override
  Future<CourseDto> getCourse(String courseId) async {
    return courseResult ??
        (
          id: '1416019',
          nameZh: 'Python程式設計概論與應用',
          nameEn: 'Python Program Design and Application',
          credits: 2.0,
          hours: 2,
          descriptionZh:
              '在本課程中，同學將學習到計算機程式語言Python基礎與應用，'
              '建立Python程式設計的基本概念。透過做中學、學中做，'
              '建構程式設計的基礎，以及基本程式運算邏輯，'
              '以培養運算思維、動手做的能力。'
              '期末以分組方式完成一個與學生專業領域相關應用的專題，'
              '學習如何運用程式解決與自身相關領域運用上的問題。',
          descriptionEn:
              'In this course, students will learn the basics and applications '
              'of the Python programming language and establish the basic '
              'concepts of Python programming design. Through the continuous '
              'practice, student will construct the basic logic of the program '
              'design, and the ability of computation think and practice '
              'application. At the final, a topic related to the application '
              'of students\' professional subjects will be completed in groups, '
              'and student will learn how to use the program to solve problems '
              'in the relevant fields.',
        );
  }

  @override
  Future<TeacherDto> getTeacher({
    required String teacherId,
    required SemesterDto semester,
  }) async {
    return teacherResult ??
        (
          department: (id: '59', name: '資工系'),
          title: '專任副教授',
          nameZh: '王李吉',
          nameEn: 'Lee-Jyi Wang',
          teachingHours: 15.0,
          officeHours: [
            (
              day: DayOfWeek.monday,
              startTime: (hour: 10, minute: 10),
              endTime: (hour: 12, minute: 10),
            ),
            (
              day: DayOfWeek.wednesday,
              startTime: (hour: 13, minute: 0),
              endTime: (hour: 15, minute: 0),
            ),
          ],
          officeHoursNote: null,
        );
  }

  @override
  Future getClassroom({
    required String classroomId,
    required SemesterDto semester,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<SyllabusDto> getSyllabus({
    required String courseNumber,
    required String syllabusId,
  }) async {
    return syllabusResult ??
        (
          type: CourseType.universityCommonRequired,
          enrolled: 55,
          withdrawn: 2,
          email: 'richwang@ntut.edu.tw',
          lastUpdated: DateTime(2025, 10, 20, 10, 15, 5),
          objective:
              '在本課程中，同學將學習到計算機程式語言Python基礎與應用，'
              '建立Python程式設計的基本概念。透過做中學、學中做，'
              '建構程式設計的基礎，以及基本程式運算邏輯，'
              '以培養運算思維、動手做的能力。'
              '期末以分組方式完成一個與學生專業領域相關應用的專題，'
              '學習如何運用程式解決與自身相關領域運用上的問題。',
          weeklyPlan:
              '第01週\t教育大數據概述及Python開發環境建置\n'
              '第02週\t數學函式、字元與字串\n'
              '第03週\t流程控制\n'
              '第04週\t迴圈及其應用\n'
              '第05週\t中秋節(放假)\n'
              '第06週\t串列list, 數組tuple介紹與字串操作\n'
              '第07週\t函式與模組的應用介紹-1\n'
              '第08週\t函式與模組的應用介紹-2\n'
              '第09週\t期中考試\n'
              '第10週\t字典dict, 集合set介紹\n'
              '第11週\t共授專家演講\n'
              '第12週\t正規表示式(Regular Expression)介紹\n'
              '第13週\t類別與物件\n'
              '第14週\t檔案與異常處理\n'
              '第15週\t政府公開相關資料(教育)的擷取介紹\n'
              '第16週\t政府公開資料(教育)的處理與分析\n'
              '第17週\tAI簡介與應用介紹\n'
              '第18週\t期末考試',
          evaluation:
              '(*) 資工系同學因系上已有相關課程，所以學分將不認列，請勿選修。\n'
              '課程參與(20%)\n作業與隨堂考試(30%)\n期中考試(25%)\n期末考試(25%)',
          materials: '稍後公佈',
          remarks:
              '因應疫情發展，本學期教學及授課方式請依照學校網頁所公布之訊息為準：\n'
              '(https://oaa.ntut.edu.tw/p/404-1008-98622.php?Lang=zh-tw)\n'
              '1. 同學如有加退選簽核或課程問題，請寫信至 richwang@ntut.edu.tw，'
              '信件標題 [課程名稱]_班級(或隨班附讀)_名字。\n'
              '2. 本課程其他資料，將透過北科i學園plus公布。\n'
              '3. 本課程採實體授課方式，但為因應疫情或其它狀況，'
              '可能會調整授課內容、授課方式、評分項目與配分比例。\n'
              '如果無法實體上課，預定使用Teams於原定上課時段進行遠距上課，'
              '相關細節將再另行公告。\n'
              '相關防疫或課程上課形式公告，請參考學校網頁: '
              'https://oaa.ntut.edu.tw/p/404-1008-98622.php?Lang=zh-tw',
        );
  }
}
