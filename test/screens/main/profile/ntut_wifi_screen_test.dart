import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/repositories/campus_wifi_repository.dart';
import 'package:tattoo/repositories/preferences_repository.dart';
import 'package:tattoo/screens/main/profile/ntut_wifi_screen.dart';
import 'package:tattoo/screens/main/profile/profile_providers.dart';
import 'package:tattoo/screens/main/profile/profile_screen.dart';
import 'package:tattoo/screens/main/user_providers.dart';
import 'package:tattoo/services/portal/mock_portal_service.dart';
import 'package:tattoo/services/student_query/mock_student_query_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    SharedPreferencesAsyncPlatform.instance =
        _InMemorySharedPreferencesAsyncPlatform();
    LocaleSettings.setLocale(AppLocale.zhTw);
  });

  group('ProfileScreen', () {
    late _FakePreferencesRepository preferencesRepository;

    setUp(() {
      preferencesRepository = _FakePreferencesRepository();
    });

    tearDown(() async {
      await preferencesRepository.close();
    });

    testWidgets('shows the profile entry on Android', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const ProfileScreen(),
          platform: TargetPlatform.android,
          overrides: [
            userProfileProvider.overrideWith((ref) async => null),
            userAvatarProvider.overrideWith((ref) async => null),
            activeRegistrationProvider.overrideWith((ref) async => null),
            preferencesRepositoryProvider.overrideWith((ref) {
              return preferencesRepository;
            }),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.profile.options.ntutWifi), findsOneWidget);
      expect(find.text(t.ntutWifi.entryDescription), findsOneWidget);
    });

    testWidgets('hides the profile entry on non-Android platforms', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const ProfileScreen(),
          platform: TargetPlatform.iOS,
          overrides: [
            userProfileProvider.overrideWith((ref) async => null),
            userAvatarProvider.overrideWith((ref) async => null),
            activeRegistrationProvider.overrideWith((ref) async => null),
            preferencesRepositoryProvider.overrideWith((ref) {
              return preferencesRepository;
            }),
          ],
        ),
      );
      await tester.pumpAndSettle();

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

class _FakePreferencesRepository extends PreferencesRepository {
  _FakePreferencesRepository._(this._database)
    : super(
        prefs: SharedPreferencesAsync(),
        portalService: MockPortalService(),
        database: _database,
        authRepository: _FakeAuthRepository(_database),
      );

  factory _FakePreferencesRepository() {
    return _FakePreferencesRepository._(AppDatabase(NativeDatabase.memory()));
  }

  final AppDatabase _database;

  @override
  Future<T> get<T>(PrefKey<T> key) async => key.defaultValue;

  Future<void> close() => _database.close();
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository(this._database)
    : super(
        portalService: MockPortalService(),
        studentQueryService: MockStudentQueryService(),
        database: _database,
        secureStorage: const FlutterSecureStorage(),
        onSessionCreated: _noop,
        onSessionDestroyed: _noopDestroyed,
      );

  final AppDatabase _database;
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
