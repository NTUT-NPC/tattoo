import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod/riverpod.dart';

const _campusWifiChannel = MethodChannel('club.ntut.tattoo/campus_wifi');

bool get _isMobilePlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

void _logCampusWifi(String message) {
  log(message, name: 'CampusWifi');
  debugPrint('[CampusWifi] $message');
}

/// Raw capabilities returned from the platform channel before provisioner mapping.
typedef CampusWifiCapabilitiesDto = ({
  bool isSupported,
  int? androidSdkInt,
  bool canOpenWifiSettings,
  bool canOpenWifiPanel,
  bool canProvisionNtut8021xSuggestion,
  bool canProvisionNtut8021xCompat,
  bool canProvisionNtut8021x,
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

/// Provides the platform bridge used by campus Wi-Fi actions.
final campusWifiPlatformProvider = Provider<CampusWifiPlatform>((_) {
  return const MethodChannelCampusWifiPlatform(_campusWifiChannel);
});

/// Native/platform-facing bridge for campus Wi-Fi actions.
abstract interface class CampusWifiPlatform {
  Future<CampusWifiCapabilitiesDto> getCapabilities();

  Future<bool> openWifiSettings();

  Future<bool> openWifiPanel();

  /// Opens Android Wi-Fi control settings, falling back to this app's details.
  Future<bool> openWifiPermissionSettings();

  /// Removes only app-managed configurations; no portal credentials are needed.
  Future<String> removeNtut8021x();

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
    return _invokeOnMobile(
      fallback: (
        isSupported: false,
        androidSdkInt: null,
        canOpenWifiSettings: false,
        canOpenWifiPanel: false,
        canProvisionNtut8021xSuggestion: false,
        canProvisionNtut8021xCompat: false,
        canProvisionNtut8021x: false,
        suggestionPermissionState: 'unknown',
      ),
      invoke: () async {
        final result = await _channel.invokeMapMethod<String, Object?>(
          'getCapabilities',
        );
        return (
          isSupported: result.readBool('isSupported') ?? result != null,
          androidSdkInt: result.readInt('sdkInt'),
          canOpenWifiSettings: result.readBool('canOpenWifiSettings') ?? false,
          canOpenWifiPanel: result.readBool('canOpenWifiPanel') ?? false,
          canProvisionNtut8021xSuggestion:
              result.readBool('canProvisionNtut8021xSuggestion') ?? false,
          canProvisionNtut8021xCompat:
              result.readBool('canProvisionNtut8021xCompat') ?? false,
          canProvisionNtut8021x:
              result.readBool('canProvisionNtut8021x') ??
              ((result.readBool('canProvisionNtut8021xSuggestion') ?? false) ||
                  (result.readBool('canProvisionNtut8021xCompat') ?? false)),
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
  Future<bool> openWifiPermissionSettings() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    return _invokeBooleanMethod('openWifiPermissionSettings');
  }

  @override
  Future<String> removeNtut8021x() {
    return _invokeOnMobile(
      fallback: _isMobilePlatform ? 'failed' : 'unsupportedPlatform',
      invoke: () async =>
          await _channel.invokeMethod<String>('removeNtut8021x') ?? 'failed',
    );
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
    return _invokeOnMobile(
      fallback: (
        status: _isMobilePlatform ? 'failed' : 'unsupportedPlatform',
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
    return _invokeOnMobile(
      fallback: false,
      invoke: () async => await _channel.invokeMethod<bool>(method) ?? false,
    );
  }

  Future<T> _invokeOnMobile<T>({
    required T fallback,
    required Future<T> Function() invoke,
  }) async {
    if (!_isMobilePlatform) return fallback;

    try {
      return await invoke();
    } on MissingPluginException {
      return fallback;
    } on PlatformException catch (e) {
      _logCampusWifi(
        'PlatformException in platform channel invoke: ${e.code} (${e.message})',
      );
      return fallback;
    }
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
