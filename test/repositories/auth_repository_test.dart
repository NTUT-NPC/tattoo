import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/services/portal/mock_portal_service.dart';
import 'package:tattoo/services/portal/portal_service.dart';
import 'package:tattoo/services/student_query/mock_student_query_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthRepository', () {
    late Map<String, String> secureStorage;
    late AppDatabase database;
    late _RecordingPortalService portalService;
    late List<_CredentialRefreshCall> refreshCalls;
    late AuthRepository repository;

    setUp(() {
      secureStorage = {};
      FlutterSecureStoragePlatform.instance = _InMemorySecureStoragePlatform(
        secureStorage,
      );
      database = AppDatabase(NativeDatabase.memory());
      portalService = _RecordingPortalService();
      refreshCalls = [];
      repository = AuthRepository(
        portalService: portalService,
        studentQueryService: MockStudentQueryService(),
        database: database,
        secureStorage: const FlutterSecureStorage(),
        onSessionCreated: _noop,
        onSessionDestroyed: _noopDestroyed,
        onCredentialsUpdated:
            ({
              required username,
              required password,
              previousUsername,
              previousPassword,
            }) async {
              refreshCalls.add(
                (
                  username: username,
                  password: password,
                  previousUsername: previousUsername,
                  previousPassword: previousPassword,
                ),
              );
            },
      );
    });

    tearDown(() async {
      await database.close();
    });

    test(
      'login triggers NTUT-802.1X refresh with the previous credentials',
      () async {
        secureStorage['username'] = '111360109';
        secureStorage['password'] = 'old-password';

        await repository.login('111360109', 'new-password');

        expect(refreshCalls, [
          (
            username: '111360109',
            password: 'new-password',
            previousUsername: '111360109',
            previousPassword: 'old-password',
          ),
        ]);
      },
    );

    test(
      'changePassword triggers NTUT-802.1X refresh with the old password',
      () async {
        await repository.login('111360109', 'old-password');
        refreshCalls.clear();

        await repository.changePassword('old-password', 'new-password');

        expect(portalService.changePasswordCalls, [
          (currentPassword: 'old-password', newPassword: 'new-password'),
        ]);
        expect(refreshCalls, [
          (
            username: '111360109',
            password: 'new-password',
            previousUsername: '111360109',
            previousPassword: 'old-password',
          ),
        ]);
        expect(
          await repository.getStoredCredentials(),
          (username: '111360109', password: 'new-password'),
        );
        expect(
          portalService.loginCalls.last,
          (username: '111360109', password: 'new-password'),
        );
      },
    );
  });
}

typedef _CredentialRefreshCall = ({
  String username,
  String password,
  String? previousUsername,
  String? previousPassword,
});

class _RecordingPortalService extends MockPortalService {
  final loginCalls = <({String username, String password})>[];
  final changePasswordCalls =
      <({String currentPassword, String newPassword})>[];

  @override
  Future<UserDto> login(String username, String password) async {
    loginCalls.add((username: username, password: password));
    return super.login(username, password);
  }

  @override
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    changePasswordCalls.add(
      (currentPassword: currentPassword, newPassword: newPassword),
    );
  }
}

class _InMemorySecureStoragePlatform extends FlutterSecureStoragePlatform {
  _InMemorySecureStoragePlatform(this._data);

  final Map<String, String> _data;

  @override
  Future<bool> containsKey({
    required String key,
    required Map<String, String> options,
  }) async {
    return _data.containsKey(key);
  }

  @override
  Future<void> delete({
    required String key,
    required Map<String, String> options,
  }) async {
    _data.remove(key);
  }

  @override
  Future<void> deleteAll({required Map<String, String> options}) async {
    _data.clear();
  }

  @override
  Future<String?> read({
    required String key,
    required Map<String, String> options,
  }) async {
    return _data[key];
  }

  @override
  Future<Map<String, String>> readAll({
    required Map<String, String> options,
  }) async {
    return Map<String, String>.from(_data);
  }

  @override
  Future<void> write({
    required String key,
    required String value,
    required Map<String, String> options,
  }) async {
    _data[key] = value;
  }
}

void _noop() {}

void _noopDestroyed([_]) {}
