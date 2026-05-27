import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tattoo/services/campus_wifi/ntut8021x_state_store.dart';
import 'package:tattoo/utils/shared_preferences.dart';

const _campusWifiChannel = MethodChannel('club.ntut.tattoo/campus_wifi');
const ntut8021xAutoReprovisionPreferenceKey = 'ntut8021xAutoReprovisionEnabled';

bool get _isAndroidPlatform =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

void _logCampusWifi(String message) {
  log(message, name: 'CampusWifi');
  debugPrint('[CampusWifi] $message');
}

/// Raw capabilities returned from the platform channel before repository mapping.
typedef CampusWifiCapabilitiesDto = ({
  bool isSupported,
  int? androidSdkInt,
  bool canOpenWifiSettings,
  bool canOpenWifiPanel,
  bool canProvisionNtut8021xSuggestion,
  bool canProvisionNtut8021xCompat,
  String suggestionPermissionState,
});

/// Raw provisioning payload returned from the platform channel.
typedef Ntut8021xProvisioningDto = ({
  String status,
  int? androidSdkInt,
  bool usedHiddenCaPath,
  bool? wifiEnabled,
  int? networkSuggestionStatus,
  int? approvalStatus,
  String? suggestionPermissionState,
  int? compatResultCode,
  List<int> compatNetworkResultCodes,
  String? message,
});

/// Provides the platform bridge used by the campus Wi-Fi repository.
final campusWifiPlatformProvider = Provider<CampusWifiPlatform>((_) {
  return const MethodChannelCampusWifiPlatform(_campusWifiChannel);
});

final ntut8021xAutoReprovisionProvider = Provider<Ntut8021xAutoReprovision>((
  ref,
) {
  return Ntut8021xAutoReprovision(
    prefs: ref.watch(sharedPreferencesProvider),
    platform: ref.watch(campusWifiPlatformProvider),
    stateStore: ref.watch(ntut8021xStateStoreProvider),
  );
});

/// Native/platform-facing bridge for campus Wi-Fi actions.
abstract interface class CampusWifiPlatform {
  Future<CampusWifiCapabilitiesDto> getCapabilities();

  Future<bool> openWifiSettings();

  Future<bool> openWifiPanel();

  Future<Ntut8021xProvisioningDto> provisionNtut8021x({
    required String identity,
    required String password,
    String? previousIdentity,
    String? previousPassword,
  });

  Future<Ntut8021xProvisioningDto> saveNtut8021xToSystem({
    required String identity,
    required String password,
  });
}

/// MethodChannel-backed implementation of [CampusWifiPlatform].
class MethodChannelCampusWifiPlatform implements CampusWifiPlatform {
  const MethodChannelCampusWifiPlatform(this._channel);

  final MethodChannel _channel;

  @override
  Future<CampusWifiCapabilitiesDto> getCapabilities() async {
    return _invokeOnAndroid(
      fallback: (
        isSupported: false,
        androidSdkInt: null,
        canOpenWifiSettings: false,
        canOpenWifiPanel: false,
        canProvisionNtut8021xSuggestion: false,
        canProvisionNtut8021xCompat: false,
        suggestionPermissionState: 'unknown',
      ),
      invoke: () async {
        final result = await _channel.invokeMapMethod<String, Object?>(
          'getCapabilities',
        );
        return (
          isSupported: true,
          androidSdkInt: result.readInt('sdkInt'),
          canOpenWifiSettings: result.readBool('canOpenWifiSettings') ?? true,
          canOpenWifiPanel: result.readBool('canOpenWifiPanel') ?? false,
          canProvisionNtut8021xSuggestion:
              result.readBool('canProvisionNtut8021xSuggestion') ??
              result.readBool('canProvisionNtut8021x') ??
              false,
          canProvisionNtut8021xCompat:
              result.readBool('canProvisionNtut8021xCompat') ?? false,
          suggestionPermissionState:
              result.readString('suggestionPermissionState') ?? 'unknown',
        );
      },
    );
  }

  @override
  Future<bool> openWifiSettings() async {
    return _invokeBooleanMethod('openWifiSettings');
  }

  @override
  Future<bool> openWifiPanel() async {
    return _invokeBooleanMethod('openWifiPanel');
  }

  @override
  Future<Ntut8021xProvisioningDto> provisionNtut8021x({
    required String identity,
    required String password,
    String? previousIdentity,
    String? previousPassword,
  }) async {
    return _invokeProvisioningMethod(
      method: 'provisionNtut8021x',
      arguments: {
        'identity': identity,
        'password': password,
        'previousIdentity': previousIdentity,
        'previousPassword': previousPassword,
      },
    );
  }

  @override
  Future<Ntut8021xProvisioningDto> saveNtut8021xToSystem({
    required String identity,
    required String password,
  }) async {
    return _invokeProvisioningMethod(
      method: 'saveNtut8021xToSystem',
      arguments: {
        'identity': identity,
        'password': password,
      },
    );
  }

  Future<Ntut8021xProvisioningDto> _invokeProvisioningMethod({
    required String method,
    required Map<String, Object?> arguments,
  }) async {
    return _invokeOnAndroid(
      fallback: (
        status: 'unsupportedPlatform',
        androidSdkInt: null,
        usedHiddenCaPath: false,
        wifiEnabled: null,
        networkSuggestionStatus: null,
        approvalStatus: null,
        suggestionPermissionState: 'unknown',
        compatResultCode: null,
        compatNetworkResultCodes: const <int>[],
        message: null,
      ),
      invoke: () async {
        final result = await _channel.invokeMapMethod<String, Object?>(
          method,
          arguments,
        );
        return (
          status: result.readString('status') ?? 'failed',
          androidSdkInt: result.readInt('sdkInt'),
          wifiEnabled: result.readBool('wifiEnabled'),
          usedHiddenCaPath: result.readBool('usedHiddenCaPath') ?? false,
          networkSuggestionStatus: result.readInt('networkSuggestionStatus'),
          approvalStatus: result.readInt('approvalStatus'),
          suggestionPermissionState:
              result.readString('suggestionPermissionState') ?? 'unknown',
          compatResultCode: result.readInt('compatResultCode'),
          compatNetworkResultCodes:
              result.readIntList('addNetworkResultCodes') ?? const <int>[],
          message: result.readString('message'),
        );
      },
    );
  }

  Future<bool> _invokeBooleanMethod(String method) async {
    return _invokeOnAndroid(
      fallback: false,
      invoke: () async => await _channel.invokeMethod<bool>(method) ?? false,
    );
  }

  Future<T> _invokeOnAndroid<T>({
    required T fallback,
    required Future<T> Function() invoke,
  }) async {
    if (!_isAndroidPlatform) return fallback;

    try {
      return await invoke();
    } on MissingPluginException {
      return fallback;
    }
  }
}

/// Manages whether NTUT-802.1X should be automatically re-provisioned when
/// credentials change, and performs the refresh when enabled.
class Ntut8021xAutoReprovision {
  Ntut8021xAutoReprovision({
    required SharedPreferencesAsync prefs,
    required CampusWifiPlatform platform,
    required Ntut8021xStateStore stateStore,
  }) : _prefs = prefs,
       _platform = platform,
       _stateStore = stateStore;

  final SharedPreferencesAsync _prefs;
  final CampusWifiPlatform _platform;
  final Ntut8021xStateStore _stateStore;

  Future<bool> isEnabled() async {
    final enabled =
        await _prefs.getBool(ntut8021xAutoReprovisionPreferenceKey) ?? false;
    _logCampusWifi('Read auto reprovision flag: enabled=$enabled');
    return enabled;
  }

  Future<void> enable() async {
    await _prefs.setBool(ntut8021xAutoReprovisionPreferenceKey, true);
    _logCampusWifi('Updated auto reprovision flag: enabled=true');
  }

  Future<void> reprovisionIfEnabled({
    required String identity,
    required String password,
    String? previousIdentity,
    String? previousPassword,
  }) async {
    final enabled = await isEnabled();
    if (!enabled) {
      _logCampusWifi(
        'Skipped NTUT-802.1X auto reprovision because the flag is disabled',
      );
      return;
    }

    final storedState = await _stateStore.read();
    if (storedState.lastProvisioningMode ==
        Ntut8021xStoredProvisioningMode.none) {
      _logCampusWifi(
        'Skipped NTUT-802.1X auto reprovision because no provisioning mode is stored',
      );
      return;
    }

    if (previousIdentity == identity && previousPassword == password) {
      _logCampusWifi(
        'Skipped NTUT-802.1X auto reprovision because credentials did not change',
      );
      return;
    }

    if (storedState.lastProvisioningMode ==
        Ntut8021xStoredProvisioningMode.compat) {
      await _stateStore.setPendingCompatPrompt(
        reason: Ntut8021xStoredPendingPromptReason.credentialChanged,
        immediate: true,
      );
      _logCampusWifi(
        'Queued NTUT-802.1X compat prompt because last provisioning used compat mode',
      );
      return;
    }

    final capabilities = await _platform.getCapabilities();
    if (!capabilities.canProvisionNtut8021xSuggestion) {
      await _queueCompatPromptIfAvailable(capabilities, immediate: true);
      _logCampusWifi(
        'Skipped NTUT-802.1X auto reprovision because suggestion mode is unavailable',
      );
      return;
    }

    if (capabilities.suggestionPermissionState == 'disallowed') {
      await _queueCompatPromptIfAvailable(capabilities, immediate: true);
      _logCampusWifi(
        'Queued NTUT-802.1X compat prompt because suggestion permission is disallowed',
      );
      return;
    }

    _logCampusWifi(
      'Starting NTUT-802.1X auto reprovision; '
      'hasPreviousCredentials=${previousIdentity != null && previousPassword != null}',
    );

    final result = await _platform.provisionNtut8021x(
      identity: identity,
      password: password,
      previousIdentity: previousIdentity,
      previousPassword: previousPassword,
    );

    if (_isSuggestionSuccess(result.status)) {
      await _stateStore.markProvisioned(
        mode: Ntut8021xStoredProvisioningMode.suggestion,
      );
      _logCampusWifi('Finished NTUT-802.1X auto reprovision successfully');
      return;
    }

    await _queueCompatPromptIfAvailable(capabilities, immediate: true);
    _logCampusWifi(
      'Finished NTUT-802.1X auto reprovision without silent success; '
      'result=${result.status}',
    );
  }

  Future<void> _queueCompatPromptIfAvailable(
    CampusWifiCapabilitiesDto capabilities, {
    required bool immediate,
  }) async {
    if ((capabilities.androidSdkInt ?? 0) < 30 ||
        !capabilities.canProvisionNtut8021xCompat) {
      return;
    }
    await _stateStore.setPendingCompatPrompt(
      reason: Ntut8021xStoredPendingPromptReason.suggestionFallbackRequired,
      immediate: immediate,
    );
  }

  bool _isSuggestionSuccess(String status) {
    return status == 'success' || status == 'successPendingWifi';
  }
}

extension on Map<String, Object?>? {
  bool? readBool(String key) => this?[key] as bool?;

  int? readInt(String key) => this?[key] as int?;

  String? readString(String key) => this?[key] as String?;

  List<int>? readIntList(String key) {
    final value = this?[key];
    if (value is! List) return null;
    return value.whereType<num>().map((item) => item.toInt()).toList();
  }
}
