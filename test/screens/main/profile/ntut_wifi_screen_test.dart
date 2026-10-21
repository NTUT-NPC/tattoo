import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tattoo/components/notices.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/models/campus_wifi.dart';
import 'package:tattoo/repositories/campus_wifi_repository.dart';
import 'package:tattoo/screens/main/profile/ntut_wifi_screen.dart';
import 'package:tattoo/utils/auto_spacing.dart';

void main() {
  for (final locale in AppLocale.values) {
    for (final (size, scale) in [
      (const Size(390, 844), 1.0),
      (const Size(320, 568), 1.0),
      (const Size(320, 568), 2.0),
    ]) {
      testWidgets(
        'iOS ${locale.name} guide and fixed actions at $size, text scale $scale',
        (
          tester,
        ) async {
          await _pumpScreen(tester, size: size, scale: scale, locale: locale);

          expect(
            find.text(t.ntutWifi.manualGuide.openIos.spaced),
            findsOneWidget,
          );
          expect(
            find.text(t.ntutWifi.manualGuide.trustIos.spaced),
            findsOneWidget,
          );
          expect(
            find.text(t.ntutWifi.manualGuide.openAndroid.spaced),
            findsNothing,
          );
          expect(
            find.text(t.ntutWifi.manualGuide.configureAndroid.spaced),
            findsNothing,
          );
          expect(
            find.text(t.ntutWifi.actions.openWifiSettings.spaced),
            findsNothing,
          );
          expect(
            find.text(t.ntutWifi.actions.openWifiPermissionSettings.spaced),
            findsNothing,
          );
          expect(
            tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
            isNotNull,
          );
          expect(find.byType(OutlinedButton), findsOneWidget);
          final initialPosition = tester.getRect(find.byType(FilledButton));
          await tester.dragFrom(
            tester.getTopLeft(find.byType(CustomScrollView)) +
                const Offset(20, 20),
            const Offset(0, -5000),
          );
          await tester.pumpAndSettle();
          expect(tester.getRect(find.byType(FilledButton)), initialPosition);
          expect(
            tester
                .getBottomRight(
                  find.text(t.ntutWifi.manualGuide.trustIos.spaced),
                )
                .dy,
            lessThanOrEqualTo(initialPosition.top),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final sdk in [29, 30]) {
    testWidgets('Android API $sdk denial notice opens permission settings', (
      tester,
    ) async {
      final repository = _PermissionSettingsRepository();
      await _pumpScreen(
        tester,
        androidSdkInt: sdk,
        permissionDenied: true,
        repository: repository,
      );
      final notice = find.widgetWithText(
        BackgroundNotice,
        t.ntutWifi.permissionRequired.spaced,
      );
      final action = find.descendant(
        of: notice,
        matching: find.text(
          t.ntutWifi.actions.openWifiPermissionSettings.spaced,
        ),
      );
      expect(notice, findsOneWidget);
      expect(action, findsOneWidget);
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(repository.opened, isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Android with allowed permission hides the denial notice', (
    tester,
  ) async {
    await _pumpScreen(tester, androidSdkInt: 30);
    expect(find.text(t.ntutWifi.permissionRequired.spaced), findsNothing);
    expect(
      find.text(t.ntutWifi.actions.openWifiPermissionSettings.spaced),
      findsNothing,
    );
  });

  testWidgets('iOS without credentials disables setup but permits removal', (
    tester,
  ) async {
    await _pumpScreen(tester, credentials: false);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNotNull,
    );
    expect(
      find.text(
        '${t.ntutWifi.credentialsMissing}\n${t.ntutWifi.accountHint}'.spaced,
      ),
      findsOneWidget,
    );
    expect(find.text(t.ntutWifi.manualGuide.copyPassword.spaced), findsNothing);
  });

  testWidgets('iOS simulator hides removal and disables setup', (tester) async {
    await _pumpScreen(tester, supported: false);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.text(t.ntutWifi.manualGuide.openIos.spaced), findsOneWidget);
    expect(find.text(t.ntutWifi.ios.deviceRequired.spaced), findsOneWidget);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double scale = 1,
  AppLocale locale = .zhTw,
  bool credentials = true,
  bool supported = true,
  int? androidSdkInt,
  bool permissionDenied = false,
  CampusWifiRepository? repository,
}) async {
  final previousLocale = LocaleSettings.currentLocale;
  await tester.runAsync(() => LocaleSettings.setLocale(locale));
  addTearDown(() => LocaleSettings.setLocaleSync(previousLocale));
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final data = Ntut8021xAssistantData(
    status: credentials ? .ready : .credentialsMissing,
    capabilities: CampusWifiCapabilities(
      isSupported: true,
      androidSdkInt: androidSdkInt,
      canOpenWifiSettings: androidSdkInt != null,
      canOpenWifiPanel: false,
      canProvisionNtut8021xSuggestion: androidSdkInt != null && supported,
      canProvisionNtut8021xCompat: (androidSdkInt ?? 0) >= 30 && supported,
      canProvisionAutomatically: supported,
      canSaveToSystem: supported,
      canRemoveNtut8021x: supported,
      suggestionPermissionState: permissionDenied ? .disallowed : .allowed,
    ),
    screenMode: !supported
        ? .manualOnly
        : permissionDenied
        ? .permissionRequired
        : .normal,
    lastProvisioningMode: !supported
        ? .none
        : androidSdkInt == null
        ? .direct
        : .suggestion,
    showImmediatePromptCandidate: false,
    identity: '111360109',
    password: credentials ? 'test-password' : null,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ntutWifiAssistantProvider.overrideWith((ref) async => data),
        if (repository case final repository?)
          campusWifiRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        theme: ThemeData(platform: androidSdkInt == null ? .iOS : .android),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: .linear(scale)),
          child: child!,
        ),
        home: const NtutWifiScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _PermissionSettingsRepository implements CampusWifiRepository {
  bool opened = false;

  @override
  Future<bool> openWifiPermissionSettings() async {
    opened = true;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
