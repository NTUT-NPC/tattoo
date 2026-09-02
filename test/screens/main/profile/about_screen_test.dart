import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/models/contributor.dart';
import 'package:tattoo/repositories/preferences_repository.dart';
import 'package:tattoo/screens/main/profile/about_screen.dart';
import 'package:tattoo/screens/main/profile/preference_providers.dart';
import 'package:tattoo/services/github_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    LocaleSettings.setLocale(AppLocale.zhTw);
    PackageInfo.setMockInitialValues(
      appName: 'Tattoo',
      packageName: 'com.tat.tattoo',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  testWidgets(
    'shows standard links and Weblate button when preference is enabled',
    (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferenceValueProvider(
              PrefKey.showWeblateButton,
            ).overrideWithValue(true),
            contributorsProvider.overrideWith(
              (ref) async => [
                Contributor(
                  login: 'alice',
                  avatarUrl: 'https://example.com/alice.png',
                  htmlUrl: 'https://github.com/alice',
                  type: 'User',
                ),
              ],
            ),
          ],
          child: const MaterialApp(home: AboutScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('GitHub'), findsOneWidget);
      expect(find.text(t.about.openSourceLicenses), findsOneWidget);
      expect(find.text('Weblate'), findsOneWidget);
      expect(find.text(t.about.privacyPolicy), findsOneWidget);
      expect(find.text('alice'), findsOneWidget);
    },
  );

  testWidgets(
    'hides Weblate button when preference is disabled while keeping standard links',
    (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferenceValueProvider(
              PrefKey.showWeblateButton,
            ).overrideWithValue(false),
          ],
          child: const MaterialApp(home: AboutScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('GitHub'), findsOneWidget);
      expect(find.text(t.about.openSourceLicenses), findsOneWidget);
      expect(find.text('Weblate'), findsNothing);
      expect(find.text(t.about.privacyPolicy), findsOneWidget);
    },
  );
}
