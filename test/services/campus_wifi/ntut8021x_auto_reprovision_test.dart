import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';
import 'package:tattoo/services/campus_wifi/campus_wifi_platform.dart';
import 'package:tattoo/services/campus_wifi/ntut8021x_state_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        _InMemorySharedPreferencesAsyncPlatform();
  });

  group('Ntut8021xAutoReprovision', () {
    test('does nothing while the preference is disabled', () async {
      final platform = _FakeCampusWifiPlatform();
      final stateStore = Ntut8021xStateStore(SharedPreferencesAsync());
      final autoReprovision = Ntut8021xAutoReprovision(
        prefs: SharedPreferencesAsync(),
        platform: platform,
        stateStore: stateStore,
      );

      await autoReprovision.reprovisionIfEnabled(
        identity: '111360109',
        password: 'portal-password',
      );

      expect(platform.provisionCallCount, 0);
      expect((await stateStore.read()).pendingCompatPromptReason, isNull);
    });

    test(
      'queues a compat prompt when compat mode credentials change',
      () async {
        final platform = _FakeCampusWifiPlatform();
        final stateStore = Ntut8021xStateStore(SharedPreferencesAsync());
        final autoReprovision = Ntut8021xAutoReprovision(
          prefs: SharedPreferencesAsync(),
          platform: platform,
          stateStore: stateStore,
        );

        await autoReprovision.enable();
        await stateStore.markProvisioned(
          mode: Ntut8021xStoredProvisioningMode.compat,
        );

        await autoReprovision.reprovisionIfEnabled(
          identity: '111360109',
          password: 'new-password',
        );

        final state = await stateStore.read();
        expect(platform.provisionCallCount, 0);
        expect(
          state.pendingCompatPromptReason,
          Ntut8021xStoredPendingPromptReason.credentialChanged,
        );
        expect(state.pendingImmediatePrompt, isTrue);
      },
    );

    test(
      'silently reprovisions when suggestion mode credentials change',
      () async {
        final platform = _FakeCampusWifiPlatform();
        final stateStore = Ntut8021xStateStore(SharedPreferencesAsync());
        final autoReprovision = Ntut8021xAutoReprovision(
          prefs: SharedPreferencesAsync(),
          platform: platform,
          stateStore: stateStore,
        );

        await autoReprovision.enable();
        await stateStore.markProvisioned(
          mode: Ntut8021xStoredProvisioningMode.suggestion,
        );

        await autoReprovision.reprovisionIfEnabled(
          identity: '111360109',
          password: 'new-password',
          previousIdentity: '111360109',
          previousPassword: 'old-password',
        );

        final state = await stateStore.read();
        expect(platform.provisionCallCount, 1);
        expect(platform.identity, '111360109');
        expect(platform.password, 'new-password');
        expect(platform.previousIdentity, '111360109');
        expect(platform.previousPassword, 'old-password');
        expect(
          state.lastProvisioningMode,
          Ntut8021xStoredProvisioningMode.suggestion,
        );
        expect(state.pendingCompatPromptReason, isNull);
      },
    );

    test('does not reprovision when credentials did not change', () async {
      final platform = _FakeCampusWifiPlatform();
      final stateStore = Ntut8021xStateStore(SharedPreferencesAsync());
      final autoReprovision = Ntut8021xAutoReprovision(
        prefs: SharedPreferencesAsync(),
        platform: platform,
        stateStore: stateStore,
      );

      await autoReprovision.enable();
      await stateStore.markProvisioned(
        mode: Ntut8021xStoredProvisioningMode.suggestion,
      );

      await autoReprovision.reprovisionIfEnabled(
        identity: '111360109',
        password: 'portal-password',
        previousIdentity: '111360109',
        previousPassword: 'portal-password',
      );

      expect(platform.provisionCallCount, 0);
      expect((await stateStore.read()).pendingCompatPromptReason, isNull);
    });

    test(
      'queues compat prompt when suggestion refresh fails on Android 11+',
      () async {
        final platform = _FakeCampusWifiPlatform(
          capabilities: const (
            isSupported: true,
            androidSdkInt: 30,
            canOpenWifiSettings: true,
            canOpenWifiPanel: true,
            canProvisionNtut8021xSuggestion: true,
            canProvisionNtut8021xCompat: true,
            suggestionPermissionState: 'allowed',
          ),
          provisioningResult: const (
            status: 'approvalRejected',
            androidSdkInt: 30,
            usedHiddenCaPath: true,
            wifiEnabled: true,
            networkSuggestionStatus: 1,
            approvalStatus: null,
            suggestionPermissionState: 'disallowed',
            compatResultCode: null,
            compatNetworkResultCodes: <int>[],
            message: null,
          ),
        );
        final stateStore = Ntut8021xStateStore(SharedPreferencesAsync());
        final autoReprovision = Ntut8021xAutoReprovision(
          prefs: SharedPreferencesAsync(),
          platform: platform,
          stateStore: stateStore,
        );

        await autoReprovision.enable();
        await stateStore.markProvisioned(
          mode: Ntut8021xStoredProvisioningMode.suggestion,
        );

        await autoReprovision.reprovisionIfEnabled(
          identity: '111360109',
          password: 'new-password',
        );

        final state = await stateStore.read();
        expect(platform.provisionCallCount, 1);
        expect(
          state.pendingCompatPromptReason,
          Ntut8021xStoredPendingPromptReason.suggestionFallbackRequired,
        );
        expect(state.pendingImmediatePrompt, isTrue);
      },
    );
  });
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
      suggestionPermissionState: 'allowed',
      compatResultCode: null,
      compatNetworkResultCodes: <int>[],
      message: null,
    ),
  });

  final CampusWifiCapabilitiesDto capabilities;
  final Ntut8021xProvisioningDto provisioningResult;

  int provisionCallCount = 0;
  String? identity;
  String? password;
  String? previousIdentity;
  String? previousPassword;

  @override
  Future<CampusWifiCapabilitiesDto> getCapabilities() async => capabilities;

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
    return provisioningResult;
  }

  @override
  Future<Ntut8021xProvisioningDto> saveNtut8021xToSystem({
    required String identity,
    required String password,
  }) {
    throw UnimplementedError();
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
