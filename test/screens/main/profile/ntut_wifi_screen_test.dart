import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/campus_wifi_repository.dart';
import 'package:tattoo/screens/main/profile/ntut_wifi_entry_tile.dart';
import 'package:tattoo/screens/main/profile/ntut_wifi_providers.dart';
import 'package:tattoo/screens/main/profile/ntut_wifi_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    LocaleSettings.setLocale(AppLocale.zhTw);
  });

  group('NtutWifiEntryTile', () {
    testWidgets('shows the profile entry on Android', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Scaffold(body: NtutWifiEntryTile()),
          platform: TargetPlatform.android,
        ),
      );

      expect(find.text(t.profile.options.ntutWifi), findsOneWidget);
      expect(find.text(t.ntutWifi.entryDescription), findsOneWidget);
    });

    testWidgets('hides the profile entry on non-Android platforms', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const Scaffold(body: NtutWifiEntryTile()),
          platform: TargetPlatform.iOS,
        ),
      );

      expect(find.text(t.profile.options.ntutWifi), findsNothing);
      expect(find.text(t.ntutWifi.entryDescription), findsNothing);
    });
  });

  group('NtutWifiScreen', () {
    testWidgets('shows the ready state with identity and password actions', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const NtutWifiScreen(),
          overrides: [
            ntutWifiAssistantProvider.overrideWith(
              (ref) => const Ntut8021xAssistantData(
                status: Ntut8021xAssistantStatus.ready,
                capabilities: CampusWifiCapabilities(
                  isSupported: true,
                  androidSdkInt: 34,
                  canOpenWifiSettings: true,
                  canOpenWifiPanel: true,
                  canProvisionNtut8021x: true,
                ),
                identity: '111360109',
                password: 'portal-password',
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(t.ntutWifi.sections.recommendedSettings),
        findsOneWidget,
      );
      expect(find.text('111360109'), findsOneWidget);
      expect(find.text(t.ntutWifi.fieldValues.passwordSaved), findsOneWidget);
      expect(find.text(t.ntutWifi.actions.autoProvision), findsOneWidget);
      expect(find.text(t.ntutWifi.actions.openWifiSettings), findsOneWidget);
      expect(find.text(t.ntutWifi.actions.openWifiPanel), findsOneWidget);
      expect(
        find.text(t.ntutWifi.fieldValues.systemCertificates),
        findsOneWidget,
      );
    });

    testWidgets('shows the logged-out warning state', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const NtutWifiScreen(),
          overrides: [
            ntutWifiAssistantProvider.overrideWith(
              (ref) => const Ntut8021xAssistantData(
                status: Ntut8021xAssistantStatus.notLoggedIn,
                capabilities: CampusWifiCapabilities(
                  isSupported: true,
                  androidSdkInt: 34,
                  canOpenWifiSettings: false,
                  canOpenWifiPanel: false,
                  canProvisionNtut8021x: false,
                ),
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.ntutWifi.notLoggedIn), findsOneWidget);
      expect(find.text(t.general.notLoggedIn), findsOneWidget);
      expect(
        find.text(t.ntutWifi.fieldValues.passwordUnavailable),
        findsOneWidget,
      );
      expect(find.text(t.general.copy), findsNothing);
      expect(find.text(t.ntutWifi.actions.autoProvision), findsNothing);
    });
  });
}

Widget _buildApp(
  Widget child, {
  TargetPlatform platform = TargetPlatform.android,
  List overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides.cast(),
    child: MaterialApp(
      theme: ThemeData(useMaterial3: true, platform: platform),
      home: child,
    ),
  );
}
