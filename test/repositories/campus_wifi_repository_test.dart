import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/repositories/campus_wifi_repository.dart';
import 'package:tattoo/services/portal/mock_portal_service.dart';
import 'package:tattoo/services/student_query/mock_student_query_service.dart';

void main() {
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
      );

      final data = await repository.getNtut8021xAssistantData();

      expect(data.status, Ntut8021xAssistantStatus.credentialsMissing);
      expect(data.identity, _testUser.studentId);
      expect(data.password, isNull);
    });

    test('reuses stored credentials when provisioning NTUT-802.1X', () async {
      final platform = _FakeCampusWifiPlatform();
      final authRepository = _FakeAuthRepository(
        localUser: _testUser,
        credentials: (username: '111360109', password: 'portal-password'),
      );
      addTearDown(authRepository.close);

      final repository = CampusWifiRepository(
        authRepository: authRepository,
        platform: platform,
      );

      final result = await repository.provisionNtut8021x();

      expect(result.status, Ntut8021xProvisioningStatus.success);
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

  static const capabilities = CampusWifiCapabilities(
    isSupported: true,
    androidSdkInt: 34,
    canOpenWifiSettings: true,
    canOpenWifiPanel: true,
    canProvisionNtut8021x: true,
  );

  String? provisionedIdentity;
  String? provisionedPassword;

  @override
  Future<CampusWifiCapabilities> getCapabilities() async => capabilities;

  @override
  Future<bool> openWifiPanel() async => capabilities.canOpenWifiPanel;

  @override
  Future<bool> openWifiSettings() async => capabilities.canOpenWifiSettings;

  @override
  Future<Ntut8021xProvisioningResult> provisionNtut8021x({
    required String identity,
    required String password,
  }) async {
    provisionedIdentity = identity;
    provisionedPassword = password;
    return const Ntut8021xProvisioningResult(
      status: Ntut8021xProvisioningStatus.success,
      androidSdkInt: 34,
      usedHiddenCaPath: true,
      wifiEnabled: true,
    );
  }
}

void _noop() {}

void _noopDestroyed([_]) {}
