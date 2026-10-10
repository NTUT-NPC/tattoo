import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/services/course/ntut_course_service.dart';

void main() {
  group('NtutCourseService zh course table parser', () {
    late NtutCourseService service;

    setUp(() {
      service = NtutCourseService();
    });

    test('parses classroom from Croom.jsp for single instructor', () {
      final courseName = '機械基礎實習(一)';
      final html = _buildZhCourseTableHtml(
        courseName: courseName,
        gridCellInnerHtml: _buildCell([
          _a('Curr.jsp?format=-2&code=5900001', courseName),
          _a('Teach.jsp?format=-3&code=9001', '林桂安'),
          _a('./Croom.jsp?format=-3&code=310', '綜科715 (e)'),
        ]),
      );

      final classroom = _parseClassroom(service, html);
      expect(classroom?.id, '310');
      expect(classroom?.name, '綜科715');
    });

    test('parses classroom from Croom.jsp for multi instructor', () {
      final courseName = '機械基礎實習(一)';
      final html = _buildZhCourseTableHtml(
        courseName: courseName,
        gridCellInnerHtml: _buildCell([
          _a('Curr.jsp?format=-2&code=5900001', courseName),
          _a('Teach.jsp?format=-3&code=9001', '王老師'),
          _a('Teach.jsp?format=-3&code=9002', '李老師'),
          _a(
            'https://aps.ntut.edu.tw/course/tw/Croom.jsp?format=-3&code=561',
            '先鋒501(e)',
          ),
        ]),
      );

      final classroom = _parseClassroom(service, html);
      expect(classroom?.id, '561');
      expect(classroom?.name, '先鋒501');
    });

    test('returns null classroom for single instructor without classroom', () {
      final courseName = '機械基礎實習(一)';
      final html = _buildZhCourseTableHtml(
        courseName: courseName,
        gridCellInnerHtml: _buildCell([
          _a('Curr.jsp?format=-2&code=5900001', courseName),
          _a('Teach.jsp?format=-3&code=9001', '林桂安'),
        ]),
      );

      expect(_parseClassroom(service, html), isNull);
    });

    test('returns null classroom for multi instructor without classroom', () {
      final courseName = '機械基礎實習(一)';
      final html = _buildZhCourseTableHtml(
        courseName: courseName,
        gridCellInnerHtml: _buildCell([
          _a('Curr.jsp?format=-2&code=5900001', courseName),
          _a('Teach.jsp?format=-3&code=9001', '王老師'),
          _a('Teach.jsp?format=-3&code=9002', '李老師'),
        ]),
      );

      expect(_parseClassroom(service, html), isNull);
    });

    test('falls back to trailing plain text classroom when no Croom.jsp', () {
      final courseName = '機械基礎實習(一)';
      final html = _buildZhCourseTableHtml(
        courseName: courseName,
        gridCellInnerHtml: _buildCell([
          _a('Curr.jsp?format=-2&code=5900001', courseName),
          _a('Teach.jsp?format=-3&code=9001', '林桂安'),
          '機電工廠A區',
        ]),
      );

      final classroom = _parseClassroom(service, html);
      expect(classroom?.id, isNull);
      expect(classroom?.name, '機電工廠A區');
    });

    test('does not treat unknown link as classroom', () {
      final courseName = '機械基礎實習(一)';
      final html = _buildZhCourseTableHtml(
        courseName: courseName,
        gridCellInnerHtml: _buildCell([
          _a('Curr.jsp?format=-2&code=5900001', courseName),
          _a('Teach.jsp?format=-3&code=9001', '林桂安'),
          _a('Unknown.jsp?code=999', '未知連結'),
        ]),
      );

      expect(_parseClassroom(service, html), isNull);
    });

    test('uses trailing plain text after unknown link as classroom fallback', () {
      final courseName = '機械基礎實習(一)';
      final html = _buildZhCourseTableHtml(
        courseName: courseName,
        gridCellInnerHtml: _buildCell([
          _a('Curr.jsp?format=-2&code=5900001', courseName),
          _a('Teach.jsp?format=-3&code=9001', '林桂安'),
          _a('Unknown.jsp?code=999', '未知連結'),
          '共同科館201',
        ]),
      );

      final classroom = _parseClassroom(service, html);
      expect(classroom?.id, isNull);
      expect(classroom?.name, '共同科館201');
    });
  });
}

({String? id, String? name})? _parseClassroom(
  NtutCourseService service,
  String html,
) {
  final table = service.parseZhCourseTableForTest(html);
  final target = table.singleWhere((schedule) => schedule.number == '5900001');
  return target.schedule?.single.classroom;
}

String _buildCell(List<String> entries) => entries.join('<br>');

String _a(String href, String text) => '<a href="$href">$text</a>';

String _buildZhCourseTableHtml({
  required String courseName,
  required String gridCellInnerHtml,
}) {
  return '''
<html>
  <body>
    <table border="1">
      <tr>
        <td align="center" colspan="6">學號：111590001</td>
      </tr>
      <tr>
        <th>節次</th>
        <th>一</th>
      </tr>
      <tr>
        <th>第 1 節<br>08:10 - 09:00</th>
        <td align="center">$gridCellInnerHtml</td>
      </tr>
    </table>
    <table border="1">
      <tr><th>課號</th></tr>
      <tr><th>header</th></tr>
      <tr>
        <td>5900001</td>
        <td><a href="Curr.jsp?format=-2&code=5900001">$courseName</a></td>
        <td>1</td>
        <td>2</td>
        <td>2</td>
        <td>必</td>
        <td><a href="Teach.jsp?code=9001">林桂安</a></td>
        <td><a href="Subj.jsp?code=61001">智動一</a></td>
        <td></td>
        <td></td>
        <td></td>
        <td></td>
        <td></td>
        <td></td>
        <td></td>
        <td></td>
        <td>選上</td>
        <td>中文</td>
        <td></td>
        <td></td>
      </tr>
      <tr><td colspan="20">Total</td></tr>
    </table>
  </body>
</html>
''';
}
