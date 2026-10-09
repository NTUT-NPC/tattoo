import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/course_repository.dart';
import 'package:tattoo/screens/main/course_table/course_materials_list.dart';

const _file = CourseMaterial(
  id: 1,
  courseOffering: 1,
  title: 'Lecture',
  href: 'file',
  iSchoolCourseId: '101',
  streamable: false,
);

Future<void> _showList(
  WidgetTester tester,
  _Repository repository,
  List<CourseMaterial> materials,
) => tester.pumpWidget(
  ProviderScope(
    overrides: [courseRepositoryProvider.overrideWithValue(repository)],
    child: TranslationProvider(
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CourseMaterialsList(materials: materials),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets(
    'unknown materials are immediately tappable without type requests',
    (tester) async {
      final repository = _Repository();
      final material = _file.copyWith(streamable: const Value(null));
      await _showList(tester, repository, [material]);
      await tester.pumpAndSettle();
      expect(repository.calls, 0);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.widget<ListTile>(find.byType(ListTile)).subtitle, isNull);
      expect(tester.widget<ListTile>(find.byType(ListTile)).leading, isNull);
      expect(find.byType(ListView), findsNothing);
      expect(find.byType(Scrollable), findsOneWidget);
      await tester.tap(find.text('Lecture'));
      await tester.pumpAndSettle();
      expect(repository.calls, 1);
      expect(find.text(t.courseTable.detail.materials.saved), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('tapping a known recording shows the unavailable message', (
    tester,
  ) async {
    final repository = _Repository();
    await _showList(tester, repository, [
      _file.copyWith(streamable: const Value(true)),
    ]);
    await tester.tap(find.text('Lecture'));
    await tester.pumpAndSettle();
    expect(repository.calls, 0);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(
      find.text(t.courseTable.detail.materials.streamUnavailable),
      findsOneWidget,
    );
  });

  testWidgets(
    'recordings discovered after tapping show the unavailable message',
    (tester) async {
      final repository = _Repository()..error = UnsupportedError('Stream');
      await _showList(tester, repository, [
        _file.copyWith(streamable: const Value(null)),
      ]);
      await tester.tap(find.text('Lecture'));
      await tester.pumpAndSettle();
      expect(repository.calls, 1);
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      expect(
        find.text(t.courseTable.detail.materials.streamUnavailable),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'only the tapped row runs a download and picker cancellation is silent',
    (tester) async {
      final repository = _Repository()..pending = Completer<bool>();
      await _showList(tester, repository, [
        _file,
        _file.copyWith(id: 2, title: const Value('Other')),
      ]);
      await tester.tap(find.text('Lecture'));
      await tester.pump();
      await tester.tap(find.text('Lecture'));
      await tester.pump();
      expect(repository.calls, 1);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      repository.pending!.complete(false);
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    },
  );
}

class _Repository extends Fake implements CourseRepository {
  var calls = 0;
  Object? error;
  Completer<bool>? pending;

  @override
  Future<bool> saveMaterial(
    CourseMaterial material, {
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    void Function()? onSaving,
  }) async {
    calls++;
    if (error case final value?) throw value;
    return pending?.future ?? true;
  }
}
