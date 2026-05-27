import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/campus_wifi_repository.dart';
import 'package:tattoo/screens/main/profile/ntut_wifi_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    LocaleSettings.setLocale(AppLocale.zhTw);
  });

  group('NtutWifiScreen', () {
    testWidgets('shows suggestion action in normal mode', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const NtutWifiScreen(),
          overrides: [
            ntutWifiAssistantProvider.overrideWith(
              (ref) async => const Ntut8021xAssistantData(
                status: Ntut8021xAssistantStatus.ready,
                capabilities: CampusWifiCapabilities(
                  isSupported: true,
                  androidSdkInt: 34,
                  canOpenWifiSettings: true,
                  canOpenWifiPanel: true,
                  canProvisionNtut8021xSuggestion: true,
                  canProvisionNtut8021xCompat: true,
                  suggestionPermissionState:
                      CampusWifiSuggestionPermissionState.allowed,
                ),
                screenMode: Ntut8021xScreenMode.normal,
                lastProvisioningMode: Ntut8021xProvisioningMode.suggestion,
                showImmediatePromptCandidate: false,
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
      expect(find.text(t.ntutWifi.actions.retryCompatProvision), findsNothing);
      expect(find.text(t.ntutWifi.actions.openWifiSettings), findsOneWidget);
      expect(find.text(t.ntutWifi.actions.openWifiPanel), findsOneWidget);
      expect(
        find.text(t.ntutWifi.fieldValues.systemCertificates),
        findsOneWidget,
      );
    });

    testWidgets(
      'shows compat retry state when suggestion fallback is required',
      (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(
            const NtutWifiScreen(),
            overrides: [
              ntutWifiAssistantProvider.overrideWith(
                (ref) async => const Ntut8021xAssistantData(
                  status: Ntut8021xAssistantStatus.ready,
                  capabilities: CampusWifiCapabilities(
                    isSupported: true,
                    androidSdkInt: 30,
                    canOpenWifiSettings: true,
                    canOpenWifiPanel: true,
                    canProvisionNtut8021xSuggestion: true,
                    canProvisionNtut8021xCompat: true,
                    suggestionPermissionState:
                        CampusWifiSuggestionPermissionState.disallowed,
                  ),
                  screenMode: Ntut8021xScreenMode.compatRetry,
                  lastProvisioningMode: Ntut8021xProvisioningMode.suggestion,
                  pendingPromptReason:
                      Ntut8021xPendingPromptReason.suggestionFallbackRequired,
                  showImmediatePromptCandidate: false,
                  identity: '111360109',
                  password: 'portal-password',
                ),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(t.ntutWifi.actions.autoProvision), findsNothing);
        expect(
          find.text(t.ntutWifi.actions.retryCompatProvision),
          findsOneWidget,
        );
        expect(
          find.text(t.ntutWifi.suggestionFallbackRequired),
          findsOneWidget,
        );
      },
    );

    testWidgets('shows manual-only state on legacy Android', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const NtutWifiScreen(),
          overrides: [
            ntutWifiAssistantProvider.overrideWith(
              (ref) async => const Ntut8021xAssistantData(
                status: Ntut8021xAssistantStatus.ready,
                capabilities: CampusWifiCapabilities(
                  isSupported: true,
                  androidSdkInt: 28,
                  canOpenWifiSettings: true,
                  canOpenWifiPanel: false,
                  canProvisionNtut8021xSuggestion: false,
                  canProvisionNtut8021xCompat: false,
                  suggestionPermissionState:
                      CampusWifiSuggestionPermissionState.unknown,
                ),
                screenMode: Ntut8021xScreenMode.manualOnly,
                lastProvisioningMode: Ntut8021xProvisioningMode.none,
                showImmediatePromptCandidate: false,
                identity: '111360109',
                password: 'portal-password',
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.ntutWifi.legacyManualOnly), findsOneWidget);
      expect(find.text(t.ntutWifi.actions.autoProvision), findsNothing);
      expect(find.text(t.ntutWifi.actions.retryCompatProvision), findsNothing);
      expect(find.text(t.ntutWifi.actions.openWifiSettings), findsOneWidget);
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
