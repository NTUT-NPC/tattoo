import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/course_repository.dart';
import 'package:tattoo/screens/main/course_table/course_table_cell.dart';
import 'package:tattoo/screens/main/course_table/course_table_colors.dart';
import 'package:tattoo/screens/main/course_table/course_table_entrance_animation.dart';
import 'package:tattoo/screens/main/course_table/course_table_grid.dart';
import 'package:tattoo/screens/main/course_table/course_table_screen.dart';
import 'package:tattoo/screens/main/course_table/course_table_weekly.dart';
import 'package:tattoo/screens/main/course_table_providers.dart';
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

    final weeklyCenter = tester.getCenter(find.byType(CourseTableWeekly)).dx;
    for (final title in ['星期一', '星期三', '未安排時間的課程']) {
      expect(tester.getCenter(find.text(title)).dx, weeklyCenter);
    }

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

  testWidgets('weekly entries animate right to left from top to bottom', (
    tester,
  ) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: const MaterialApp(
          home: Scaffold(
            body: CourseTableWeekly(courseTableData: _courseTableData),
          ),
        ),
      ),
    );

    final animations = tester
        .widgetList<CourseTableEntranceAnimation>(
          find.byType(CourseTableEntranceAnimation),
        )
        .toList(growable: false);

    expect(animations, hasLength(3));
    expect(
      animations.map((animation) => animation.beginOffset),
      everyElement(const Offset(16, 0)),
    );
    expect(
      animations.map((animation) => animation.delay),
      const [
        Duration(milliseconds: 50),
        Duration(milliseconds: 90),
        Duration(milliseconds: 130),
      ],
    );
    expect(
      animations.map(
        (animation) => (animation.child as CourseTableListCell)
            .courseTableCellData
            .courseName,
      ),
      const ['作業系統', '軟體工程', '校外實習'],
    );
  });

  testWidgets('entries built while scrolling do not start late animations', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: Scaffold(
            body: CourseTableWeekly(
              courseTableData: _courseTableDataWithManyEntries(),
            ),
          ),
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Course 19'),
      500,
      scrollable: find.byType(Scrollable).first,
    );

    final lateEntrance = find.ancestor(
      of: find.text('Course 19'),
      matching: find.byType(CourseTableEntranceAnimation),
    );
    final animation = tester.widget<CourseTableEntranceAnimation>(
      lateEntrance,
    );

    expect(animation.timeline!.isCompleted, isFalse);
    expect(
      find.descendant(of: lateEntrance, matching: find.byType(Opacity)),
      findsNothing,
    );
  });

  testWidgets('list cells reserve a subtitle line and grow for wrapping', (
    tester,
  ) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: .min,
                  children: const [
                    CourseTableListCell(
                      key: Key('empty-subtitle'),
                      courseTableCellData: _specialCourse,
                      indicatorColor: Colors.blue,
                      trailingText: '5',
                    ),
                    CourseTableListCell(
                      key: Key('single-line-subtitle'),
                      courseTableCellData: _regularCourse,
                      indicatorColor: Colors.blue,
                      additionalSubtitle: '共同科館201',
                      trailingText: '5',
                    ),
                    CourseTableListCell(
                      key: Key('wrapping-subtitle'),
                      courseTableCellData: _regularCourse,
                      indicatorColor: Colors.blue,
                      additionalSubtitle: '共同科館201以及需要自然換行顯示的較長上課地點資訊',
                      trailingText: '5',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final emptyHeight = tester
        .getSize(find.byKey(const Key('empty-subtitle')))
        .height;
    final singleLineHeight = tester
        .getSize(find.byKey(const Key('single-line-subtitle')))
        .height;
    final wrappingHeight = tester
        .getSize(find.byKey(const Key('wrapping-subtitle')))
        .height;

    expect(emptyHeight, singleLineHeight);
    expect(wrappingHeight, greaterThan(singleLineHeight));
  });
}

const CourseTableCellData _specialCourse = (
  id: 1,
  number: null,
  span: 1,
  crossesNoon: false,
  courseName: '班週會及導師時間',
  classroomName: null,
  teacherNames: [],
  credits: 0,
  hours: 0,
);

const CourseTableCellData _regularCourse = (
  id: 2,
  number: 'CSIE3002',
  span: 1,
  crossesNoon: false,
  courseName: '作業系統',
  classroomName: null,
  teacherNames: ['測試教師'],
  credits: 3,
  hours: 3,
);

const CourseTableData _courseTableData = (
  scheduled: {
    (day: .monday, period: .first): (
      id: 20,
      number: 'CSIE3002',
      span: 2,
      crossesNoon: false,
      courseName: '作業系統',
      classroomName: '共同科館201',
      teacherNames: ['測試教師'],
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
      teacherNames: ['測試教師'],
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
      teacherNames: ['測試教師'],
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

CourseTableData _courseTableDataWithManyEntries() => (
  scheduled: _courseTableData.scheduled,
  unscheduled: [
    for (var i = 0; i < 20; i++)
      (
        id: 100 + i,
        number: 'TEST$i',
        span: 0,
        crossesNoon: false,
        courseName: 'Course $i',
        classroomName: null,
        teacherNames: ['測試教師'],
        credits: 1.0,
        hours: 1,
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
  totalCredits: 26.0,
  totalHours: 26,
);
