import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/screens/main/course_table/course_materials_list.dart';
import 'package:tattoo/screens/main/course_table/course_table_providers.dart';

void main() {
  const file = CourseMaterial(
    id: 1,
    courseOffering: 1,
    title: 'Lecture',
    href: 'file',
    iSchoolCourseId: '101',
    streamable: false,
  );
  const stream = CourseMaterial(
    id: 2,
    courseOffering: 1,
    title: 'Recording',
    href: 'stream',
    iSchoolCourseId: '101',
    streamable: true,
  );
  testWidgets(
    'only files offer download; streams explain the unavailable action',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: TranslationProvider(
            child: const MaterialApp(
              home: Scaffold(
                body: CourseMaterialsList(materials: [file, stream]),
              ),
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.download_outlined), findsOneWidget);
      expect(find.byIcon(Icons.video_library_outlined), findsOneWidget);
      expect(
        find.textContaining(t.courseTable.detail.materials.streamUnavailable),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('a failed type lookup can be retried and enables file download', (
    tester,
  ) async {
    final unresolved = file.copyWith(streamable: const Value(null));
    var attempts = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          courseMaterialTypeProvider(unresolved).overrideWith((ref) async {
            attempts++;
            if (attempts == 1) {
              throw Exception('Offline');
            }
            return false;
          }),
        ],
        child: TranslationProvider(
          child: MaterialApp(
            home: Scaffold(body: CourseMaterialsList(materials: [unresolved])),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.download_outlined), findsNothing);
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.byIcon(Icons.download_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
