import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/components/i_school_plus_network_guide.dart';
import 'package:tattoo/i18n/strings.g.dart';

void main() {
  setUp(() => LocaleSettings.setLocale(.enUs));

  Widget buildGuide({
    required bool retryEnabled,
    required bool retryInProgress,
    required VoidCallback onRetry,
  }) {
    return TranslationProvider(
      child: MaterialApp(
        home: Scaffold(
          body: ISchoolPlusNetworkGuide(
            guideUrl: Uri.parse('https://example.com/guide'),
            onRetry: onRetry,
            retryEnabled: retryEnabled,
            retryInProgress: retryInProgress,
          ),
        ),
      ),
    );
  }

  testWidgets('explains why retry is disabled during an active attempt', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildGuide(
        retryEnabled: false,
        retryInProgress: true,
        onRetry: () {},
      ),
    );

    final retry = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(retry.onPressed, isNull);
    expect(find.text(t.iSchoolPlus.network.stillTrying), findsOneWidget);
  });

  testWidgets('enables retry after the attempt settles', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      buildGuide(
        retryEnabled: true,
        retryInProgress: false,
        onRetry: () => retried = true,
      ),
    );

    await tester.tap(find.byType(FilledButton));
    expect(retried, isTrue);
    expect(find.text(t.iSchoolPlus.network.stillTrying), findsNothing);
  });
}
