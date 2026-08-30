import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/course_repository.dart';
import 'package:tattoo/screens/main/course_table/course_table_cell.dart';
import 'package:tattoo/screens/main/course_table/course_table_colors.dart';
import 'package:tattoo/screens/main/course_table/course_table_grid.dart';
import 'package:tattoo/screens/main/course_table/course_table_providers.dart';
import 'package:tattoo/screens/main/course_table/course_table_screen.dart';
import 'package:tattoo/screens/main/course_table/course_table_weekly.dart';
import 'package:tattoo/screens/main/user_providers.dart';

void main() {
  setUpAll(() async => LocaleSettings.setLocale(.zhTw));

  testWidgets('groups courses by day and keeps grid colors', (tester) async {
    tester.view.physicalSize = const Size(420, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      TranslationProvider(
        child: const MaterialApp(
          home: Scaffold(
            body: CourseTableWeekly(courseTableData: _courseTableData),
          ),
        ),
      ),
    );

    expect(find.text('星期一'), findsOneWidget);
    expect(find.text('星期三'), findsOneWidget);
    expect(find.text('未安排時間的課程'), findsOneWidget);
    expect(find.text('1–2'), findsOneWidget);
    expect(find.text('4–5'), findsOneWidget);

    final expectedColors = buildCourseTableColorMap(_courseTableData);
    final cells = tester
        .widgetList<CourseTableListCell>(find.byType(CourseTableListCell))
        .toList(growable: false);
    expect(cells, hasLength(3));
    for (final cell in cells) {
      expect(
        cell.indicatorColor,
        expectedColors[cell.courseTableCellData.id],
      );
    }
  });

  testWidgets('floating action toggles weekly and grid views', (tester) async {
    const semester = Semester(
      id: 1,
      year: 114,
      term: 2,
      inCourseSemesterList: true,
      inScoreSemesterList: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((ref) => Stream.value(null)),
          courseTableSemestersProvider.overrideWith(
            (ref) => Stream.value([semester]),
          ),
          courseTableProvider(
            semester.id,
          ).overrideWith((ref) => Stream.value(_courseTableData)),
        ],
        child: TranslationProvider(
          child: const MaterialApp(home: CourseTableScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CourseTableGrid), findsOneWidget);
    expect(find.byType(CourseTableWeekly), findsNothing);

    await tester.tap(find.byTooltip('切換至週檢視'));
    await tester.pumpAndSettle();

    expect(find.byType(CourseTableGrid), findsNothing);
    expect(find.byType(CourseTableWeekly), findsOneWidget);
    expect(find.byTooltip('切換至網格檢視'), findsOneWidget);
  });
}

const CourseTableData _courseTableData = (
  scheduled: {
    (day: .monday, period: .first): (
      id: 20,
      number: 'CSIE3002',
      span: 2,
      crossesNoon: false,
      courseName: '作業系統',
      classroomName: '共同科館201',
      credits: 3.0,
      hours: 3,
    ),
    (day: .wednesday, period: .fourth): (
      id: 10,
      number: 'CSIE3702',
      span: 2,
      crossesNoon: true,
      courseName: '軟體工程',
      classroomName: '科研B112',
      credits: 3.0,
      hours: 3,
    ),
  },
  unscheduled: [
    (
      id: 30,
      number: 'CSIE4999',
      span: 0,
      crossesNoon: false,
      courseName: '校外實習',
      classroomName: null,
      credits: 9.0,
      hours: 9,
    ),
  ],
  hasWeekdayCourse: true,
  hasSaturdayCourse: false,
  hasSundayCourse: false,
  hasAMCourse: true,
  hasPMCourse: true,
  hasNoonCourse: false,
  hasEveningCourse: false,
  earliestPeriod: .first,
  latestPeriod: .fifth,
  totalCredits: 15.0,
  totalHours: 15,
);
