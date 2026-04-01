import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod/riverpod.dart';

const _campusWifiChannel = MethodChannel('club.ntut.tattoo/campus_wifi');

bool get _isAndroidPlatform =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// Raw capabilities returned from the platform channel before repository mapping.
typedef CampusWifiCapabilitiesDto = ({
  bool isSupported,
  int? androidSdkInt,
  bool canOpenWifiSettings,
  bool canOpenWifiPanel,
  bool canProvisionNtut8021x,
});

/// Raw provisioning payload returned from the platform channel.
typedef Ntut8021xProvisioningDto = ({
  String status,
  int? androidSdkInt,
  bool usedHiddenCaPath,
  bool? wifiEnabled,
  int? networkSuggestionStatus,
  int? approvalStatus,
  String? message,
});

/// Provides the platform bridge used by the campus Wi-Fi repository.
final campusWifiPlatformProvider = Provider<CampusWifiPlatform>((_) {
  return const MethodChannelCampusWifiPlatform(_campusWifiChannel);
});

/// Native/platform-facing bridge for campus Wi-Fi actions.
abstract interface class CampusWifiPlatform {
  Future<CampusWifiCapabilitiesDto> getCapabilities();

  Future<bool> openWifiSettings();

  Future<bool> openWifiPanel();

  Future<Ntut8021xProvisioningDto> provisionNtut8021x({
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
        canProvisionNtut8021x: false,
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
          canProvisionNtut8021x:
              result.readBool('canProvisionNtut8021x') ?? false,
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
  }) async {
    return _invokeOnAndroid(
      fallback: (
        status: 'unsupportedPlatform',
        androidSdkInt: null,
        usedHiddenCaPath: false,
        wifiEnabled: null,
        networkSuggestionStatus: null,
        approvalStatus: null,
        message: null,
      ),
      invoke: () async {
        final result = await _channel.invokeMapMethod<String, Object?>(
          'provisionNtut8021x',
          {
            'identity': identity,
            'password': password,
          },
        );
        return (
          status: result.readString('status') ?? 'failed',
          androidSdkInt: result.readInt('sdkInt'),
          wifiEnabled: result.readBool('wifiEnabled'),
          usedHiddenCaPath: result.readBool('usedHiddenCaPath') ?? false,
          networkSuggestionStatus: result.readInt('networkSuggestionStatus'),
          approvalStatus: result.readInt('approvalStatus'),
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

extension on Map<String, Object?>? {
  bool? readBool(String key) => this?[key] as bool?;

  int? readInt(String key) => this?[key] as int?;

  String? readString(String key) => this?[key] as String?;
}
