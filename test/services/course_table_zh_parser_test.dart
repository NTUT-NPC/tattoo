import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/models/course.dart';
import 'package:tattoo/services/course/course_service.dart';
import 'package:tattoo/services/course/ntut_course_service.dart';

/// Parser tests backed by a de-identified snapshot of the Chinese course table.
///
/// Live integration tests only see the semesters the test account happens to
/// have. This fixture pins the grid shapes behind
/// https://github.com/NTUT-NPC/tattoo/issues/423 — a team-taught course with no
/// classroom, a single-teacher course with no classroom, and a link-less row.
void main() {
  group('zh course table parser', () {
    late List<ScheduleDto> table;

    setUpAll(() {
      final html = File(
        'test/fixtures/course/course_table_zh_y111_t1.html',
      ).readAsStringSync();
      table = NtutCourseService().parseZhCourseTable(html);
    });

    ReferenceDto? classroomOf(String courseName) {
      final schedule = table
          .firstWhere((dto) => dto.course?.nameZh == courseName)
          .schedule;
      expect(schedule, isNotEmpty, reason: '$courseName should be scheduled');
      return schedule!.first.classroom;
    }

    test('reads the classroom from the Croom.jsp anchor', () {
      expect(classroomOf('日文(一)'), (id: '423', name: '六教226'));
      expect(classroomOf('工程圖學'), (id: '498', name: '綜科715'));
    });

    test('leaves the classroom null when the cell has no Croom.jsp anchor', () {
      // 機械基礎實習(一) is team-taught, so its last anchor is a teacher.
      expect(classroomOf('機械基礎實習(一)'), isNull);
      // 體育 has a single teacher and no classroom.
      expect(classroomOf('體育'), isNull);
    });

    test('never mistakes a teacher for a classroom', () {
      for (final dto in table) {
        final teacherNames = (dto.teachers ?? const [])
            .map((teacher) => teacher.nameZh)
            .nonNulls
            .toSet();
        for (final meeting in dto.schedule ?? const []) {
          expect(
            teacherNames,
            isNot(contains(meeting.classroom?.name)),
            reason:
                '${dto.course?.nameZh} parsed a teacher name as its classroom',
          );
        }
      }
    });

    test('keeps link-less rows as a course with no classroom', () {
      final classMeeting = table.firstWhere(
        (dto) => dto.course?.nameZh == '班週會及導師時間',
      );
      expect(classMeeting.schedule, isNotEmpty);
      for (final meeting in classMeeting.schedule!) {
        expect(meeting.classroom, isNull);
      }
    });

    test('parses every scheduled meeting of a multi-period course', () {
      final practical = table.firstWhere(
        (dto) => dto.course?.nameZh == '機械基礎實習(一)',
      );
      expect(
        practical.schedule!.map((meeting) => meeting.period).toSet(),
        {Period.first, Period.second, Period.third, Period.fourth},
      );
      expect(
        practical.schedule!.map((meeting) => meeting.day).toSet(),
        {DayOfWeek.wednesday},
      );
    });
  });
}
