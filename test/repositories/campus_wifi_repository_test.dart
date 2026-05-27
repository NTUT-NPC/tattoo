import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/repositories/campus_wifi_repository.dart';
import 'package:tattoo/services/campus_wifi/campus_wifi_platform.dart';
import 'package:tattoo/services/campus_wifi/ntut8021x_state_store.dart';
import 'package:tattoo/services/portal/mock_portal_service.dart';
import 'package:tattoo/services/student_query/mock_student_query_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        _InMemorySharedPreferencesAsyncPlatform();
  });

  group('CampusWifiRepository', () {
    test('returns ready data with normal screen mode', () async {
      final authRepository = _FakeAuthRepository(
        localUser: _testUser,
        credentials: (username: '111360109', password: 'portal-password'),
      );
      addTearDown(authRepository.close);

      final repository = _buildRepository(
        authRepository: authRepository,
        platform: _FakeCampusWifiPlatform(),
      );

      final data = await repository.getNtut8021xAssistantData();

      expect(data.status, Ntut8021xAssistantStatus.ready);
      expect(data.identity, '111360109');
      expect(data.password, 'portal-password');
      expect(data.screenMode, Ntut8021xScreenMode.normal);
      expect(data.capabilities.canProvisionNtut8021xSuggestion, isTrue);
    });

    test(
      'android 11+ permission denied switches to compat retry mode',
      () async {
        final authRepository = _FakeAuthRepository(
          localUser: _testUser,
          credentials: (username: '111360109', password: 'portal-password'),
        );
        addTearDown(authRepository.close);

        final repository = _buildRepository(
          authRepository: authRepository,
          platform: _FakeCampusWifiPlatform(
            capabilities: const (
              isSupported: true,
              androidSdkInt: 30,
              canOpenWifiSettings: true,
              canOpenWifiPanel: true,
              canProvisionNtut8021xSuggestion: true,
              canProvisionNtut8021xCompat: true,
              suggestionPermissionState: 'disallowed',
            ),
          ),
        );

        final data = await repository.getNtut8021xAssistantData();

        expect(data.screenMode, Ntut8021xScreenMode.compatRetry);
      },
    );

    test(
      'android 10 permission denied falls back to manual only mode',
      () async {
        final authRepository = _FakeAuthRepository(
          localUser: _testUser,
          credentials: (username: '111360109', password: 'portal-password'),
        );
        addTearDown(authRepository.close);

        final repository = _buildRepository(
          authRepository: authRepository,
          platform: _FakeCampusWifiPlatform(
            capabilities: const (
              isSupported: true,
              androidSdkInt: 29,
              canOpenWifiSettings: true,
              canOpenWifiPanel: true,
              canProvisionNtut8021xSuggestion: true,
              canProvisionNtut8021xCompat: false,
              suggestionPermissionState: 'disallowed',
            ),
          ),
        );

        final data = await repository.getNtut8021xAssistantData();

        expect(data.screenMode, Ntut8021xScreenMode.manualOnly);
      },
    );

    test(
      'consumePendingImmediatePrompt returns prompt from local state',
      () async {
        final authRepository = _FakeAuthRepository(
          localUser: _testUser,
          credentials: (username: '111360109', password: 'portal-password'),
        );
        addTearDown(authRepository.close);

        final prefs = SharedPreferencesAsync();
        final stateStore = Ntut8021xStateStore(prefs);
        await stateStore.setPendingCompatPrompt(
          reason: Ntut8021xStoredPendingPromptReason.credentialChanged,
          immediate: true,
        );

        final repository = _buildRepository(
          authRepository: authRepository,
          platform: _FakeCampusWifiPlatform(),
          stateStore: stateStore,
        );

        final prompt = await repository.consumePendingImmediatePrompt();

        expect(prompt, isNotNull);
        expect(prompt!.reason, Ntut8021xPendingPromptReason.credentialChanged);
        expect(prompt.identity, '111360109');
        expect(prompt.password, 'portal-password');
      },
    );

    test('android 11 suggestion rejection falls back to compat save', () async {
      final authRepository = _FakeAuthRepository(
        localUser: _testUser,
        credentials: (username: '111360109', password: 'portal-password'),
      );
      addTearDown(authRepository.close);

      final repository = _buildRepository(
        authRepository: authRepository,
        platform: _FakeCampusWifiPlatform(
          provisioningResult: const (
            status: 'approvalRejected',
            androidSdkInt: 30,
            usedHiddenCaPath: true,
            wifiEnabled: true,
            networkSuggestionStatus: 1,
            approvalStatus: null,
            compatResultCode: null,
            compatNetworkResultCodes: <int>[],
            suggestionPermissionState: 'disallowed',
            message: null,
          ),
          compatResult: const (
            status: 'compatSuccess',
            androidSdkInt: 30,
            usedHiddenCaPath: true,
            wifiEnabled: true,
            networkSuggestionStatus: null,
            approvalStatus: null,
            compatResultCode: 0,
            compatNetworkResultCodes: <int>[0],
            suggestionPermissionState: null,
            message: null,
          ),
        ),
      );

      final result = await repository.provisionNtut8021x();

      expect(result.status, Ntut8021xProvisioningStatus.compatSuccess);
      expect(result.fallbackTriggered, isTrue);
    });

    test('compat already-exists keeps the pending prompt active', () async {
      final authRepository = _FakeAuthRepository(
        localUser: _testUser,
        credentials: (username: '111360109', password: 'portal-password'),
      );
      addTearDown(authRepository.close);

      final stateStore = Ntut8021xStateStore(SharedPreferencesAsync());
      await stateStore.markProvisioned(
        mode: Ntut8021xStoredProvisioningMode.compat,
      );

      final repository = _buildRepository(
        authRepository: authRepository,
        stateStore: stateStore,
        platform: _FakeCampusWifiPlatform(
          compatResult: const (
            status: 'compatAlreadyExists',
            androidSdkInt: 30,
            usedHiddenCaPath: true,
            wifiEnabled: true,
            networkSuggestionStatus: null,
            approvalStatus: null,
            compatResultCode: 0,
            compatNetworkResultCodes: <int>[
              1,
            ],
            suggestionPermissionState: null,
            message: null,
          ),
        ),
      );

      final result = await repository.saveNtut8021xToSystem(
        pendingPromptReason: Ntut8021xPendingPromptReason.credentialChanged,
      );

      final storedState = await stateStore.read();
      expect(result.status, Ntut8021xProvisioningStatus.compatAlreadyExists);
      expect(result.isSuccess, isFalse);
      expect(
        result.pendingPromptReason,
        Ntut8021xPendingPromptReason.credentialChanged,
      );
      expect(
        storedState.pendingCompatPromptReason,
        Ntut8021xStoredPendingPromptReason.credentialChanged,
      );
      expect(
        storedState.lastProvisioningMode,
        Ntut8021xStoredProvisioningMode.compat,
      );
    });
  });
}

CampusWifiRepository _buildRepository({
  required _FakeAuthRepository authRepository,
  required _FakeCampusWifiPlatform platform,
  Ntut8021xStateStore? stateStore,
}) {
  final prefs = SharedPreferencesAsync();
  final resolvedStateStore = stateStore ?? Ntut8021xStateStore(prefs);
  return CampusWifiRepository(
    authRepository: authRepository,
    platform: platform,
    autoReprovision: Ntut8021xAutoReprovision(
      prefs: prefs,
      platform: platform,
      stateStore: resolvedStateStore,
    ),
    stateStore: resolvedStateStore,
  );
}

const _testUser = User(
  id: 1,
  studentId: '111360109',
  nameZh: '王大同',
  avatarFilename: '',
  email: 't111360109@ntut.edu.tw',
);

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository._(
    this._database, {
    this.localUser,
    this.credentials,
  }) : super(
         portalService: MockPortalService(),
         studentQueryService: MockStudentQueryService(),
         database: _database,
         secureStorage: const FlutterSecureStorage(),
         onSessionCreated: _noop,
         onSessionDestroyed: _noopDestroyed,
       );

  factory _FakeAuthRepository({
    User? localUser,
    ({String username, String password})? credentials,
  }) {
    final database = AppDatabase(NativeDatabase.memory());
    return _FakeAuthRepository._(
      database,
      localUser: localUser,
      credentials: credentials,
    );
  }

  final AppDatabase _database;
  final User? localUser;
  final ({String username, String password})? credentials;

  Future<void> close() => _database.close();

  @override
  Future<User?> getLocalUser() async => localUser;

  @override
  Future<({String username, String password})?> getStoredCredentials() async {
    return credentials;
  }
}

class _FakeCampusWifiPlatform implements CampusWifiPlatform {
  _FakeCampusWifiPlatform({
    this.capabilities = const (
      isSupported: true,
      androidSdkInt: 34,
      canOpenWifiSettings: true,
      canOpenWifiPanel: true,
      canProvisionNtut8021xSuggestion: true,
      canProvisionNtut8021xCompat: true,
      suggestionPermissionState: 'allowed',
    ),
    this.provisioningResult = const (
      status: 'success',
      androidSdkInt: 34,
      usedHiddenCaPath: true,
      wifiEnabled: true,
      networkSuggestionStatus: null,
      approvalStatus: null,
      compatResultCode: null,
      compatNetworkResultCodes: <int>[],
      suggestionPermissionState: null,
      message: null,
    ),
    this.compatResult = const (
      status: 'compatSuccess',
      androidSdkInt: 34,
      usedHiddenCaPath: true,
      wifiEnabled: true,
      networkSuggestionStatus: null,
      approvalStatus: null,
      compatResultCode: 0,
      compatNetworkResultCodes: <int>[0],
      suggestionPermissionState: null,
      message: null,
    ),
  });

  final CampusWifiCapabilitiesDto capabilities;

  final Ntut8021xProvisioningDto provisioningResult;
  final Ntut8021xProvisioningDto compatResult;

  @override
  Future<CampusWifiCapabilitiesDto> getCapabilities() async => capabilities;

  @override
  Future<bool> openWifiPanel() async => capabilities.canOpenWifiPanel;

  @override
  Future<bool> openWifiSettings() async => capabilities.canOpenWifiSettings;

  @override
  Future<Ntut8021xProvisioningDto> provisionNtut8021x({
    required String identity,
    required String password,
    String? previousIdentity,
    String? previousPassword,
  }) async {
    return provisioningResult;
  }

  @override
  Future<Ntut8021xProvisioningDto> saveNtut8021xToSystem({
    required String identity,
    required String password,
  }) async {
    return compatResult;
  }
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
