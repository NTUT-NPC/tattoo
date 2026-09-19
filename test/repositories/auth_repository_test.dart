import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/services/portal/mock_portal_service.dart';
import 'package:tattoo/services/portal/portal_service.dart';
import 'package:tattoo/services/student_query/mock_student_query_service.dart';
import 'package:tattoo/utils/http.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthRepository', () {
    late Map<String, String> secureStorage;
    late AppDatabase database;
    late _RecordingPortalService portalService;
    late List<_CredentialRefreshCall> refreshCalls;
    late AuthRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
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
        isDemo: false,
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

    test('login removes legacy plaintext credentials', () async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        'UserDataJsonKey',
        '{"account":"111360109","password":"old-password","info":null}',
      );

      await repository.login('111360109', 'new-password');

      expect(preferences.containsKey('UserDataJsonKey'), isFalse);
    });

    test(
      'a timed-out SSO fails without re-authenticating',
      () async {
        await repository.login('111360109', 'password');
        portalService.loginCalls.clear();
        portalService.ssoError = DioException.requestCancelled(
          requestOptions: RequestOptions(path: 'oauth2Server.do'),
          reason: 'I-School Plus SSO timed out',
          stackTrace: StackTrace.current,
        );

        await expectLater(
          repository.withAuth(
            () async => 'unreachable',
            sso: [.iSchoolPlusService],
          ),
          throwsA(isA<DioException>()),
        );

        // Re-authenticating would repeat the twenty-second SSO deadline
        // before the UI could report the network failure.
        expect(portalService.loginCalls, isEmpty);
        expect(portalService.ssoCalls, 1);
      },
    );

    test(
      'logout preserves the session when legacy deletion fails',
      () async {
        await repository.login('111360109', 'password');
        SharedPreferencesStorePlatform.instance =
            _FailingRemovePreferencesStore({
              'flutter.UserDataJsonKey':
                  '{"account":"111360109","password":"password","info":null}',
            });
        SharedPreferences.resetStatic();

        await expectLater(repository.logout(), throwsStateError);

        expect(
          await database.select(database.users).getSingleOrNull(),
          isNotNull,
        );
        expect(secureStorage['username'], '111360109');
        expect(secureStorage['password'], 'password');
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
  Object? ssoError;
  var ssoCalls = 0;

  @override
  Future<void> sso(String serviceCode) async {
    ssoCalls++;
    if (ssoError case final error?) throw error;
    return super.sso(serviceCode);
  }

  @override
  Future<UserDto> login(String username, String password) async {
    loginCalls.add((username: username, password: password));
    return super.login(username, password);
  }

  @override
  Future<void> changePassword({
    required String newPassword,
    String? currentPassword,
    bool isExpired = false,
  }) async {
    changePasswordCalls.add(
      (currentPassword: currentPassword ?? '', newPassword: newPassword),
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

class _FailingRemovePreferencesStore extends InMemorySharedPreferencesStore {
  _FailingRemovePreferencesStore(super.data) : super.withData();

  @override
  Future<bool> remove(String key) async => false;
}

void _noop() {}

void _noopDestroyed([_]) {}
