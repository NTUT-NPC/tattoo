import 'package:riverpod/riverpod.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/services/campus_wifi/campus_wifi_platform.dart';

/// Provides the [CampusWifiRepository] instance.
final campusWifiRepositoryProvider = Provider<CampusWifiRepository>((ref) {
  return CampusWifiRepository(
    authRepository: ref.watch(authRepositoryProvider),
    platform: ref.watch(campusWifiPlatformProvider),
  );
});

enum Ntut8021xAssistantStatus {
  ready,
  notLoggedIn,
  credentialsMissing,
  unsupportedPlatform,
}

enum Ntut8021xProvisioningStatus {
  success,
  successPendingWifi,
  approvalPending,
  approvalRejected,
  validationUnavailable,
  unsupportedPlatform,
  failed,
}

class CampusWifiCapabilities {
  const CampusWifiCapabilities({
    required this.isSupported,
    required this.androidSdkInt,
    required this.canOpenWifiSettings,
    required this.canOpenWifiPanel,
    required this.canProvisionNtut8021x,
  });

  const CampusWifiCapabilities.unsupported()
    : this(
        isSupported: false,
        androidSdkInt: null,
        canOpenWifiSettings: false,
        canOpenWifiPanel: false,
        canProvisionNtut8021x: false,
      );

  final bool isSupported;
  final int? androidSdkInt;
  final bool canOpenWifiSettings;
  final bool canOpenWifiPanel;
  final bool canProvisionNtut8021x;

  bool get isAndroid12OrNewer => (androidSdkInt ?? 0) >= 31;
}

class Ntut8021xAssistantData {
  const Ntut8021xAssistantData({
    required this.status,
    required this.capabilities,
    this.identity,
    this.password,
  });

  static const ssid = 'NTUT-802.1X';
  static const eapMethod = 'PEAP';
  static const phase2Authentication = 'GTC';
  static const domainSuffix = 'ntut.edu.tw';
  static const certificateMode = '使用系統憑證';

  final Ntut8021xAssistantStatus status;
  final CampusWifiCapabilities capabilities;
  final String? identity;
  final String? password;

  bool get canCopyIdentity => identity != null && identity!.isNotEmpty;
  bool get canCopyPassword => password != null && password!.isNotEmpty;
  bool get canProvisionAutomatically =>
      status == Ntut8021xAssistantStatus.ready &&
      capabilities.canProvisionNtut8021x;
}

class Ntut8021xProvisioningResult {
  const Ntut8021xProvisioningResult({
    required this.status,
    required this.androidSdkInt,
    required this.usedHiddenCaPath,
    this.wifiEnabled,
    this.networkSuggestionStatus,
    this.approvalStatus,
    this.message,
  });

  const Ntut8021xProvisioningResult.unsupported()
    : this(
        status: Ntut8021xProvisioningStatus.unsupportedPlatform,
        androidSdkInt: null,
        usedHiddenCaPath: false,
      );

  final Ntut8021xProvisioningStatus status;
  final int? androidSdkInt;
  final bool usedHiddenCaPath;
  final bool? wifiEnabled;
  final int? networkSuggestionStatus;
  final int? approvalStatus;
  final String? message;

  bool get isSuccess =>
      status == Ntut8021xProvisioningStatus.success ||
      status == Ntut8021xProvisioningStatus.successPendingWifi;
}

/// Coordinates the NTUT-802.1X setup assistant data and platform actions.
class CampusWifiRepository {
  CampusWifiRepository({
    required AuthRepository authRepository,
    required CampusWifiPlatform platform,
  }) : _authRepository = authRepository,
       _platform = platform;

  final AuthRepository _authRepository;
  final CampusWifiPlatform _platform;

  Future<Ntut8021xAssistantData> getNtut8021xAssistantData() async {
    final capabilities = await _getCapabilities();
    if (!capabilities.isSupported) {
      return Ntut8021xAssistantData(
        status: Ntut8021xAssistantStatus.unsupportedPlatform,
        capabilities: capabilities,
      );
    }

    final user = await _authRepository.getLocalUser();
    if (user == null) {
      return Ntut8021xAssistantData(
        status: Ntut8021xAssistantStatus.notLoggedIn,
        capabilities: capabilities,
      );
    }

    final credentials = await _authRepository.getStoredCredentials();
    if (credentials == null) {
      return Ntut8021xAssistantData(
        status: Ntut8021xAssistantStatus.credentialsMissing,
        capabilities: capabilities,
        identity: user.studentId,
      );
    }

    return Ntut8021xAssistantData(
      status: Ntut8021xAssistantStatus.ready,
      capabilities: capabilities,
      identity: credentials.username,
      password: credentials.password,
    );
  }

  Future<Ntut8021xProvisioningResult> provisionNtut8021x() async {
    final data = await getNtut8021xAssistantData();
    if (!data.canProvisionAutomatically) {
      return const Ntut8021xProvisioningResult.unsupported();
    }

    final provisioning = await _platform.provisionNtut8021x(
      identity: data.identity!,
      password: data.password!,
    );
    return _provisioningResultFromDto(provisioning);
  }

  Future<bool> openWifiSettings() => _platform.openWifiSettings();

  Future<bool> openWifiPanel() => _platform.openWifiPanel();

  Future<CampusWifiCapabilities> _getCapabilities() async {
    final capabilities = await _platform.getCapabilities();
    return CampusWifiCapabilities(
      isSupported: capabilities.isSupported,
      androidSdkInt: capabilities.androidSdkInt,
      canOpenWifiSettings: capabilities.canOpenWifiSettings,
      canOpenWifiPanel: capabilities.canOpenWifiPanel,
      canProvisionNtut8021x: capabilities.canProvisionNtut8021x,
    );
  }

  Ntut8021xProvisioningResult _provisioningResultFromDto(
    Ntut8021xProvisioningDto provisioning,
  ) {
    return Ntut8021xProvisioningResult(
      status: _provisioningStatusFromWire(provisioning.status),
      androidSdkInt: provisioning.androidSdkInt,
      usedHiddenCaPath: provisioning.usedHiddenCaPath,
      wifiEnabled: provisioning.wifiEnabled,
      networkSuggestionStatus: provisioning.networkSuggestionStatus,
      approvalStatus: provisioning.approvalStatus,
      message: provisioning.message,
    );
  }

  Ntut8021xProvisioningStatus _provisioningStatusFromWire(String status) {
    return switch (status) {
      'success' => Ntut8021xProvisioningStatus.success,
      'successPendingWifi' => Ntut8021xProvisioningStatus.successPendingWifi,
      'approvalPending' => Ntut8021xProvisioningStatus.approvalPending,
      'approvalRejected' => Ntut8021xProvisioningStatus.approvalRejected,
      'validationUnavailable' =>
        Ntut8021xProvisioningStatus.validationUnavailable,
      'unsupportedPlatform' => Ntut8021xProvisioningStatus.unsupportedPlatform,
      _ => Ntut8021xProvisioningStatus.failed,
    };
  }
}
