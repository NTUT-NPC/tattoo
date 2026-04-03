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
import 'package:tattoo/services/portal/mock_portal_service.dart';
import 'package:tattoo/services/student_query/mock_student_query_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferencesAsyncPlatform.instance =
        _InMemorySharedPreferencesAsyncPlatform();
  });

  group('CampusWifiRepository', () {
    test('returns NTUT-802.1X credentials for a signed-in user', () async {
      final authRepository = _FakeAuthRepository(
        localUser: _testUser,
        credentials: (username: '111360109', password: 'portal-password'),
      );
      addTearDown(authRepository.close);

      final repository = CampusWifiRepository(
        authRepository: authRepository,
        platform: _FakeCampusWifiPlatform(),
        autoReprovision: _FakeNtut8021xAutoReprovision(),
      );

      final data = await repository.getNtut8021xAssistantData();

      expect(data.status, Ntut8021xAssistantStatus.ready);
      expect(data.identity, '111360109');
      expect(data.password, 'portal-password');
      expect(data.capabilities.androidSdkInt, 34);
      expect(data.capabilities.canOpenWifiSettings, isTrue);
      expect(data.capabilities.canOpenWifiPanel, isTrue);
      expect(data.capabilities.canProvisionNtut8021x, isTrue);
      expect(Ntut8021xAssistantData.ssid, 'NTUT-802.1X');
      expect(Ntut8021xAssistantData.eapMethod, 'PEAP');
      expect(Ntut8021xAssistantData.phase2Authentication, 'GTC');
    });

    test('returns notLoggedIn when no local session exists', () async {
      final authRepository = _FakeAuthRepository();
      addTearDown(authRepository.close);

      final repository = CampusWifiRepository(
        authRepository: authRepository,
        platform: _FakeCampusWifiPlatform(),
        autoReprovision: _FakeNtut8021xAutoReprovision(),
      );

      final data = await repository.getNtut8021xAssistantData();

      expect(data.status, Ntut8021xAssistantStatus.notLoggedIn);
      expect(data.identity, isNull);
      expect(data.password, isNull);
    });

    test('returns credentialsMissing when password is unavailable', () async {
      final authRepository = _FakeAuthRepository(localUser: _testUser);
      addTearDown(authRepository.close);

      final repository = CampusWifiRepository(
        authRepository: authRepository,
        platform: _FakeCampusWifiPlatform(),
        autoReprovision: _FakeNtut8021xAutoReprovision(),
      );

      final data = await repository.getNtut8021xAssistantData();

      expect(data.status, Ntut8021xAssistantStatus.credentialsMissing);
      expect(data.identity, _testUser.studentId);
      expect(data.password, isNull);
    });

    test('reuses stored credentials when provisioning NTUT-802.1X', () async {
      final platform = _FakeCampusWifiPlatform();
      final autoReprovision = _FakeNtut8021xAutoReprovision();
      final authRepository = _FakeAuthRepository(
        localUser: _testUser,
        credentials: (username: '111360109', password: 'portal-password'),
      );
      addTearDown(authRepository.close);

      final repository = CampusWifiRepository(
        authRepository: authRepository,
        platform: platform,
        autoReprovision: autoReprovision,
      );

      final result = await repository.provisionNtut8021x();

      expect(result.status, Ntut8021xProvisioningStatus.success);
      expect(autoReprovision.enabled, isTrue);
      expect(platform.provisionedIdentity, '111360109');
      expect(platform.provisionedPassword, 'portal-password');
    });
  });
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
  _FakeCampusWifiPlatform();

  static const capabilities = (
    isSupported: true,
    androidSdkInt: 34,
    canOpenWifiSettings: true,
    canOpenWifiPanel: true,
    canProvisionNtut8021x: true,
  );

  String? provisionedIdentity;
  String? provisionedPassword;
  String? provisionedPreviousIdentity;
  String? provisionedPreviousPassword;

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
    provisionedIdentity = identity;
    provisionedPassword = password;
    provisionedPreviousIdentity = previousIdentity;
    provisionedPreviousPassword = previousPassword;
    return const (
      status: 'success',
      androidSdkInt: 34,
      usedHiddenCaPath: true,
      wifiEnabled: true,
      networkSuggestionStatus: null,
      approvalStatus: null,
      message: null,
    );
  }
}

class _FakeNtut8021xAutoReprovision extends Ntut8021xAutoReprovision {
  _FakeNtut8021xAutoReprovision()
    : super(
        prefs: SharedPreferencesAsync(),
        platform: _FakeCampusWifiPlatform(),
      );

  bool enabled = false;

  @override
  Future<void> enable() async {
    enabled = true;
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
