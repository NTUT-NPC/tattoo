import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';
import 'package:tattoo/services/campus_wifi/campus_wifi_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        _InMemorySharedPreferencesAsyncPlatform();
  });

  group('Ntut8021xAutoReprovision', () {
    test('does nothing while the preference is disabled', () async {
      final platform = _FakeCampusWifiPlatform();
      final autoReprovision = Ntut8021xAutoReprovision(
        prefs: SharedPreferencesAsync(),
        platform: platform,
      );

      await autoReprovision.reprovisionIfEnabled(
        identity: '111360109',
        password: 'portal-password',
      );

      expect(platform.provisionCallCount, 0);
    });

    test(
      'reprovisions with previous credentials after being enabled',
      () async {
        final platform = _FakeCampusWifiPlatform();
        final autoReprovision = Ntut8021xAutoReprovision(
          prefs: SharedPreferencesAsync(),
          platform: platform,
        );

        await autoReprovision.enable();
        await autoReprovision.reprovisionIfEnabled(
          identity: '111360109',
          password: 'new-password',
          previousIdentity: '111360109',
          previousPassword: 'old-password',
        );

        expect(await autoReprovision.isEnabled(), isTrue);
        expect(platform.provisionCallCount, 1);
        expect(platform.identity, '111360109');
        expect(platform.password, 'new-password');
        expect(platform.previousIdentity, '111360109');
        expect(platform.previousPassword, 'old-password');
      },
    );
  });
}

class _FakeCampusWifiPlatform implements CampusWifiPlatform {
  int provisionCallCount = 0;
  String? identity;
  String? password;
  String? previousIdentity;
  String? previousPassword;

  @override
  Future<CampusWifiCapabilitiesDto> getCapabilities() async {
    throw UnimplementedError();
  }

  @override
  Future<bool> openWifiPanel() async => false;

  @override
  Future<bool> openWifiSettings() async => false;

  @override
  Future<Ntut8021xProvisioningDto> provisionNtut8021x({
    required String identity,
    required String password,
    String? previousIdentity,
    String? previousPassword,
  }) async {
    provisionCallCount++;
    this.identity = identity;
    this.password = password;
    this.previousIdentity = previousIdentity;
    this.previousPassword = previousPassword;
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
