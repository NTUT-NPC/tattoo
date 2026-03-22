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
    return courseTableResult ??
        [
          (
            number: '352204',
            course: (
              id: '3604174',
              nameZh: '邊緣運算',
              nameEn: 'Edge Computing',
            ),
            phase: 1,
            credits: 3.0,
            hours: 3,
            type: '選',
            teacher: (
              id: '12245',
              nameZh: '賴建宏',
              nameEn: 'Chien-Hung Lai',
            ),
            classes: [
              (id: '2788', nameZh: '電子四甲', nameEn: '4EN4A'),
              (id: '2789', nameZh: '電子四乙', nameEn: '4EN4B'),
            ],
            schedule: [
              (
                day: .monday,
                period: .second,
                classroom: (id: '353', name: '綜科104'),
              ),
              (
                day: .monday,
                period: .third,
                classroom: (id: '353', name: '綜科104'),
              ),
              (
                day: .monday,
                period: .fourth,
                classroom: (id: '353', name: '綜科104'),
              ),
            ],
            status: null,
            language: null,
            syllabusId: '12245',
            remarks: '電子大四合開',
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
            teacher: (
              id: '11678',
              nameZh: '陳晏笙',
              nameEn: 'Yen-Sheng Chen',
            ),
            classes: [
              (id: '3022', nameZh: '電子二甲', nameEn: '4EN2A'),
            ],
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
            syllabusId: '11678',
            remarks: '半導體二和電子二甲合開',
          ),
          (
            number: '352205',
            course: (
              id: '3604052',
              nameZh: '計算機網路',
              nameEn: 'Computer Networks',
            ),
            phase: 1,
            credits: 3.0,
            hours: 3,
            type: '選',
            teacher: (
              id: '10459',
              nameZh: '段裘慶',
              nameEn: 'CHYON-CHING TUAN',
            ),
            classes: [
              (id: '2788', nameZh: '電子四甲', nameEn: '4EN4A'),
              (id: '2789', nameZh: '電子四乙', nameEn: '4EN4B'),
            ],
            schedule: [
              (
                day: .tuesday,
                period: .fifth,
                classroom: (id: '52', name: '三教402'),
              ),
              (
                day: .tuesday,
                period: .sixth,
                classroom: (id: '52', name: '三教402'),
              ),
              (
                day: .tuesday,
                period: .seventh,
                classroom: (id: '52', name: '三教402'),
              ),
            ],
            status: null,
            language: null,
            syllabusId: '10459',
            remarks: '電子大四合開',
          ),
          (
            number: '352828',
            course: (
              id: '1001002',
              nameZh: '體育',
              nameEn: 'Physical Education',
            ),
            phase: 3,
            credits: 0.0,
            hours: 2,
            type: '必',
            teacher: (
              id: '24595',
              nameZh: '黃庭婷',
              nameEn: 'HUANG TING-TING',
            ),
            classes: [
              (id: '2037', nameZh: '體育專項(十)', nameEn: 'PE courses-10'),
            ],
            schedule: [
              (
                day: .thursday,
                period: .sixth,
                classroom: null,
              ),
              (
                day: .thursday,
                period: .seventh,
                classroom: null,
              ),
            ],
            status: null,
            language: null,
            syllabusId: '24595',
            remarks: '肢體美學C',
          ),
          (
            number: '352902',
            course: (
              id: '1410145',
              nameZh: '智慧財產權',
              nameEn: 'Intellectual Property',
            ),
            phase: 1,
            credits: 2.0,
            hours: 2,
            type: '通',
            teacher: (
              id: '24534',
              nameZh: '陳慧貞',
              nameEn: 'HUIJEN CHEN',
            ),
            classes: [
              (id: '2648', nameZh: '博雅課程(三)', nameEn: 'Core Curriculum (III)'),
            ],
            schedule: [
              (
                day: .monday,
                period: .fifth,
                classroom: (id: '562', name: '先鋒502'),
              ),
              (
                day: .monday,
                period: .sixth,
                classroom: (id: '562', name: '先鋒502'),
              ),
            ],
            status: null,
            language: null,
            syllabusId: '24534',
            remarks: '社會與法治向度',
          ),
          (
            number: '353181',
            course: (
              id: '0199998',
              nameZh: '生成式AI文字與圖像生成原理實務',
              nameEn:
                  'Generative AI: Text and Image Synthesis Principles and Practice',
            ),
            phase: 1,
            credits: 3.0,
            hours: 3,
            type: '選',
            teacher: (
              id: '11551',
              nameZh: '黃正民',
              nameEn: 'Huang Cheng-Ming',
            ),
            classes: [
              (id: '450', nameZh: '遠距教學(大)', nameEn: 'Distance Education (U)'),
            ],
            schedule: [
              (
                day: .friday,
                period: .second,
                classroom: (id: '561', name: '先鋒501'),
              ),
              (
                day: .friday,
                period: .third,
                classroom: (id: '561', name: '先鋒501'),
              ),
              (
                day: .friday,
                period: .fourth,
                classroom: (id: '561', name: '先鋒501'),
              ),
            ],
            status: null,
            language: null,
            syllabusId: '11551',
            remarks: null,
          ),
        ];
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
