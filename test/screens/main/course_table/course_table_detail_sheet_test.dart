import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tattoo/screens/main/course_table/course_table_detail_sheet.dart';
import 'package:tattoo/screens/main/course_table/course_table_providers.dart';

void main() {
  testWidgets('keeps the modal background wide without filling the screen', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          courseOfferingProvider.overrideWith((ref, number) => null),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showCourseTableDetailSheet(
                context,
                number: '0000000',
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final bottomSheet = find.byType(BottomSheet);
    final bottomSheetSize = tester.getSize(bottomSheet);
    expect(bottomSheetSize.width, 1000);
    expect(bottomSheetSize.height, lessThan(800));
    expect(tester.getBottomRight(bottomSheet).dy, 800);
  });
}
