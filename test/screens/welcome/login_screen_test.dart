import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/repositories/campus_wifi_repository.dart';
import 'package:tattoo/router/app_router.dart';
import 'package:tattoo/screens/welcome/login_screen.dart';
import 'package:tattoo/services/campus_wifi/campus_wifi_platform.dart';
import 'package:tattoo/services/campus_wifi/ntut8021x_state_store.dart';
import 'package:tattoo/services/portal/mock_portal_service.dart';
import 'package:tattoo/services/student_query/mock_student_query_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    LocaleSettings.setLocale(AppLocale.zhTw);
  });

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        _InMemorySharedPreferencesAsyncPlatform();
  });

  group('LoginScreen', () {
    testWidgets('shows compat update prompt and can skip immediate update', (
      tester,
    ) async {
      final authRepository = _FakeAuthRepository();
      final campusWifiRepository = _FakeCampusWifiRepository(
        authRepository: authRepository,
        pendingPrompt: const Ntut8021xImmediatePromptData(
          reason: Ntut8021xPendingPromptReason.credentialChanged,
          identity: '111360109',
          password: 'portal-password',
        ),
      );
      addTearDown(authRepository.close);
      addTearDown(campusWifiRepository.dispose);

      await tester.pumpWidget(
        _buildApp(
          authRepository: authRepository,
          campusWifiRepository: campusWifiRepository,
        ),
      );

      await tester.enterText(find.byType(TextField).at(0), '111360109');
      await tester.enterText(find.byType(TextField).at(1), 'portal-password');
      await tester.tap(find.text(t.login.loginButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(t.ntutWifi.compatPrompt.title), findsOneWidget);
      expect(
        find.text(t.ntutWifi.compatPrompt.credentialChanged),
        findsOneWidget,
      );

      await tester.tap(find.text(t.ntutWifi.compatPrompt.later));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(campusWifiRepository.saveCallCount, 0);
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('saves compat profile when update-now is selected', (
      tester,
    ) async {
      final authRepository = _FakeAuthRepository();
      final campusWifiRepository = _FakeCampusWifiRepository(
        authRepository: authRepository,
        pendingPrompt: const Ntut8021xImmediatePromptData(
          reason: Ntut8021xPendingPromptReason.suggestionFallbackRequired,
          identity: '111360109',
          password: 'portal-password',
        ),
      );
      addTearDown(authRepository.close);
      addTearDown(campusWifiRepository.dispose);

      await tester.pumpWidget(
        _buildApp(
          authRepository: authRepository,
          campusWifiRepository: campusWifiRepository,
        ),
      );

      await tester.enterText(find.byType(TextField).at(0), '111360109');
      await tester.enterText(find.byType(TextField).at(1), 'portal-password');
      await tester.tap(find.text(t.login.loginButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text(t.ntutWifi.compatPrompt.updateNow));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(campusWifiRepository.saveCallCount, 1);
      expect(find.text('home'), findsOneWidget);
    });
  });
}

Widget _buildApp({
  required AuthRepository authRepository,
  required CampusWifiRepository campusWifiRepository,
}) {
  final router = GoRouter(
    initialLocation: AppRoutes.login,
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const Scaffold(body: Text('home')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(authRepository),
      campusWifiRepositoryProvider.overrideWithValue(campusWifiRepository),
    ],
    child: MaterialApp.router(
      theme: ThemeData(useMaterial3: true, platform: TargetPlatform.android),
      routerConfig: router,
    ),
  );
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository._(this._database)
    : super(
        portalService: MockPortalService(),
        studentQueryService: MockStudentQueryService(),
        database: _database,
        secureStorage: const FlutterSecureStorage(),
        onSessionCreated: _noop,
        onSessionDestroyed: _noopDestroyed,
      );

  factory _FakeAuthRepository() {
    return _FakeAuthRepository._(AppDatabase(NativeDatabase.memory()));
  }

  final AppDatabase _database;

  Future<void> close() => _database.close();

  @override
  Future<User> login(String username, String password) async {
    return const User(
      id: 1,
      studentId: '111360109',
      nameZh: '王大同',
      avatarFilename: '',
      email: 't111360109@ntut.edu.tw',
    );
  }
}

class _FakeCampusWifiRepository extends CampusWifiRepository {
  _FakeCampusWifiRepository({
    required super.authRepository,
    this.pendingPrompt,
    Ntut8021xProvisioningResult? saveResult,
  }) : saveResult =
           saveResult ??
           const Ntut8021xProvisioningResult(
             status: Ntut8021xProvisioningStatus.compatSuccess,
             androidSdkInt: 30,
             usedHiddenCaPath: true,
             lastProvisioningMode: Ntut8021xProvisioningMode.compat,
             usedCompatFallback: false,
             compatNetworkResultCodes: <int>[0],
           ),
       super(
         platform: _FakeCampusWifiPlatform(),
         autoReprovision: _FakeNtut8021xAutoReprovision(),
         stateStore: Ntut8021xStateStore(SharedPreferencesAsync()),
       );

  final Ntut8021xImmediatePromptData? pendingPrompt;
  final Ntut8021xProvisioningResult saveResult;
  int saveCallCount = 0;

  Future<void> dispose() async {}

  @override
  Future<Ntut8021xImmediatePromptData?> consumePendingImmediatePrompt() async {
    return pendingPrompt;
  }

  @override
  Future<Ntut8021xProvisioningResult> saveNtut8021xToSystem({
    String? identity,
    String? password,
    Ntut8021xPendingPromptReason? pendingPromptReason,
  }) async {
    saveCallCount++;
    return saveResult;
  }
}

class _FakeCampusWifiPlatform implements CampusWifiPlatform {
  @override
  Future<CampusWifiCapabilitiesDto> getCapabilities() async {
    return const (
      isSupported: true,
      androidSdkInt: 30,
      canOpenWifiSettings: true,
      canOpenWifiPanel: true,
      canProvisionNtut8021xSuggestion: true,
      canProvisionNtut8021xCompat: true,
      suggestionPermissionState: 'allowed',
    );
  }

  @override
  Future<bool> openWifiPanel() async => true;

  @override
  Future<bool> openWifiSettings() async => true;

  @override
  Future<Ntut8021xProvisioningDto> provisionNtut8021x({
    required String identity,
    required String password,
    String? previousIdentity,
    String? previousPassword,
  }) async {
    return const (
      status: 'success',
      androidSdkInt: 30,
      usedHiddenCaPath: true,
      wifiEnabled: true,
      networkSuggestionStatus: null,
      approvalStatus: null,
      suggestionPermissionState: 'allowed',
      compatResultCode: null,
      compatNetworkResultCodes: <int>[],
      message: null,
    );
  }

  @override
  Future<Ntut8021xProvisioningDto> saveNtut8021xToSystem({
    required String identity,
    required String password,
  }) async {
    return const (
      status: 'compatSuccess',
      androidSdkInt: 30,
      usedHiddenCaPath: true,
      wifiEnabled: true,
      networkSuggestionStatus: null,
      approvalStatus: null,
      suggestionPermissionState: 'allowed',
      compatResultCode: 1,
      compatNetworkResultCodes: <int>[0],
      message: null,
    );
  }
}

class _FakeNtut8021xAutoReprovision extends Ntut8021xAutoReprovision {
  _FakeNtut8021xAutoReprovision()
    : super(
        prefs: SharedPreferencesAsync(),
        platform: _FakeCampusWifiPlatform(),
        stateStore: Ntut8021xStateStore(SharedPreferencesAsync()),
      );
}

void _noop() {}

void _noopDestroyed([_]) {}

final class _InMemorySharedPreferencesAsyncPlatform
    extends SharedPreferencesAsyncPlatform {
  final _store = <String, Object>{};

  @override
  Future<void> clear(
    ClearPreferencesParameters parameters,
    SharedPreferencesOptions options,
  ) async {
    final allowList = parameters.filter.allowList;
    if (allowList == null) {
      _store.clear();
      return;
    }
    _store.removeWhere((key, _) => allowList.contains(key));
  }

  @override
  Future<bool?> getBool(String key, SharedPreferencesOptions options) async {
    return _store[key] as bool?;
  }

  @override
  Future<double?> getDouble(
    String key,
    SharedPreferencesOptions options,
  ) async {
    return _store[key] as double?;
  }

  @override
  Future<int?> getInt(String key, SharedPreferencesOptions options) async {
    return _store[key] as int?;
  }

  @override
  Future<Map<String, Object>> getPreferences(
    GetPreferencesParameters parameters,
    SharedPreferencesOptions options,
  ) async {
    final allowList = parameters.filter.allowList;
    if (allowList == null) return Map<String, Object>.from(_store);
    return Map<String, Object>.fromEntries(
      _store.entries.where((entry) => allowList.contains(entry.key)),
    );
  }

  @override
  Future<Set<String>> getKeys(
    GetPreferencesParameters parameters,
    SharedPreferencesOptions options,
  ) async {
    final allowList = parameters.filter.allowList;
    if (allowList == null) return _store.keys.toSet();
    return _store.keys.where(allowList.contains).toSet();
  }

  @override
  Future<String?> getString(
    String key,
    SharedPreferencesOptions options,
  ) async {
    return _store[key] as String?;
  }

  @override
  Future<List<String>?> getStringList(
    String key,
    SharedPreferencesOptions options,
  ) async {
    return _store[key] as List<String>?;
  }

  @override
  Future<void> setBool(
    String key,
    bool value,
    SharedPreferencesOptions options,
  ) async {
    _store[key] = value;
  }

  @override
  Future<void> setDouble(
    String key,
    double value,
    SharedPreferencesOptions options,
  ) async {
    _store[key] = value;
  }

  @override
  Future<void> setInt(
    String key,
    int value,
    SharedPreferencesOptions options,
  ) async {
    _store[key] = value;
  }

  @override
  Future<void> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) async {
    _store[key] = value;
  }

  @override
  Future<void> setStringList(
    String key,
    List<String> value,
    SharedPreferencesOptions options,
  ) async {
    _store[key] = value;
  }
}
