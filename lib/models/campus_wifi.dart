enum Ntut8021xAssistantStatus {
  ready,
  notLoggedIn,
  credentialsMissing,
  unsupportedPlatform,
}

enum Ntut8021xScreenMode { normal, permissionRequired, compatRetry, manualOnly }

enum Ntut8021xPendingPromptReason {
  credentialChanged,
  suggestionFallbackRequired,
}

typedef Ntut8021xPendingCompatPromptReason = Ntut8021xPendingPromptReason;

enum Ntut8021xProvisioningMode { suggestion, compat, direct, none }

enum Ntut8021xProvisioningStatus {
  success,
  configured,
  cancelled,
  alreadyAssociated,
  successPendingWifi,
  approvalPending,
  approvalRejected,
  validationUnavailable,
  unsupportedPlatform,
  failed,
  compatSuccess,
  compatAlreadyExists,
  compatCancelled,
  compatFailed,
}

enum Ntut8021xRemovalStatus {
  removed,
  removalRequested,
  manualRemovalRequired,
  unsupportedPlatform,
  failed,
}

enum CampusWifiSuggestionPermissionState { allowed, disallowed, unknown }

typedef Ntut8021xSuggestionPermissionState =
    CampusWifiSuggestionPermissionState;

class CampusWifiCapabilities {
  const CampusWifiCapabilities({
    required this.isSupported,
    required this.androidSdkInt,
    required this.canOpenWifiSettings,
    required this.canOpenWifiPanel,
    required this.canProvisionNtut8021xSuggestion,
    required this.canProvisionNtut8021xCompat,
    required this.canProvisionAutomatically,
    required this.canSaveToSystem,
    required this.canRemoveNtut8021x,
    required this.suggestionPermissionState,
  });

  const CampusWifiCapabilities.unsupported()
    : this(
        isSupported: false,
        androidSdkInt: null,
        canOpenWifiSettings: false,
        canOpenWifiPanel: false,
        canProvisionNtut8021xSuggestion: false,
        canProvisionNtut8021xCompat: false,
        canProvisionAutomatically: false,
        canSaveToSystem: false,
        canRemoveNtut8021x: false,
        suggestionPermissionState: CampusWifiSuggestionPermissionState.unknown,
      );

  final bool isSupported;
  final int? androidSdkInt;
  final bool canOpenWifiSettings;
  final bool canOpenWifiPanel;
  final bool canProvisionNtut8021xSuggestion;
  final bool canProvisionNtut8021xCompat;
  final bool canProvisionAutomatically;
  final bool canSaveToSystem;
  final bool canRemoveNtut8021x;
  final CampusWifiSuggestionPermissionState suggestionPermissionState;

  bool get isAndroid10 => androidSdkInt == 29;

  bool get isAndroid11OrNewer => (androidSdkInt ?? 0) >= 30;

  bool get isAndroid12OrNewer => (androidSdkInt ?? 0) >= 31;

  bool get isLegacyAndroidManualOnly => switch (androidSdkInt) {
    final sdk? => sdk < 29,
    null => false,
  };

  bool get isSuggestionPermissionDisallowed =>
      suggestionPermissionState ==
      CampusWifiSuggestionPermissionState.disallowed;

  bool get canProvisionNtut8021x =>
      canProvisionAutomatically || canSaveToSystem;
}

class Ntut8021xAssistantData {
  const Ntut8021xAssistantData({
    required this.status,
    required this.capabilities,
    required this.screenMode,
    required this.lastProvisioningMode,
    required this.showImmediatePromptCandidate,
    this.pendingPromptReason,
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
  final Ntut8021xScreenMode screenMode;
  final Ntut8021xProvisioningMode lastProvisioningMode;
  final Ntut8021xPendingPromptReason? pendingPromptReason;
  final bool showImmediatePromptCandidate;
  final String? identity;
  final String? password;

  Ntut8021xPendingPromptReason? get pendingCompatPromptReason =>
      pendingPromptReason;

  bool get canCopyIdentity => identity != null && identity!.isNotEmpty;

  bool get canCopyPassword => password != null && password!.isNotEmpty;

  bool get canProvisionAutomatically =>
      status == Ntut8021xAssistantStatus.ready &&
      screenMode == Ntut8021xScreenMode.normal &&
      capabilities.canProvisionAutomatically;

  bool get canRetryWithCompat =>
      status == Ntut8021xAssistantStatus.ready &&
      (screenMode == Ntut8021xScreenMode.compatRetry ||
          screenMode == Ntut8021xScreenMode.permissionRequired) &&
      capabilities.canProvisionNtut8021xCompat &&
      capabilities.isAndroid11OrNewer &&
      canCopyIdentity &&
      canCopyPassword;

  bool get canUseCompatMode => canRetryWithCompat;

  bool get canRemoveConfiguration =>
      capabilities.canRemoveNtut8021x &&
      screenMode != .manualOnly &&
      !canUseCompatMode &&
      lastProvisioningMode != .compat;
}

class Ntut8021xImmediatePromptData {
  const Ntut8021xImmediatePromptData({
    required this.reason,
    required this.identity,
    required this.password,
  });

  final Ntut8021xPendingPromptReason reason;
  final String identity;
  final String password;
}

class Ntut8021xProvisioningResult {
  const Ntut8021xProvisioningResult({
    required this.status,
    required this.androidSdkInt,
    required this.usedHiddenCaPath,
    required this.lastProvisioningMode,
    required this.compatNetworkResultCodes,
    this.pendingPromptReason,
    this.wifiEnabled,
    this.networkSuggestionStatus,
    this.approvalStatus,
    this.compatResultCode,
    this.compatNetworkResultCode,
    this.message,
  });

  const Ntut8021xProvisioningResult.unsupported()
    : this(
        status: Ntut8021xProvisioningStatus.unsupportedPlatform,
        androidSdkInt: null,
        usedHiddenCaPath: false,
        lastProvisioningMode: Ntut8021xProvisioningMode.none,
        pendingPromptReason: null,
        compatNetworkResultCodes: const <int>[],
      );

  final Ntut8021xProvisioningStatus status;
  final int? androidSdkInt;
  final bool usedHiddenCaPath;
  final Ntut8021xProvisioningMode lastProvisioningMode;
  final Ntut8021xPendingPromptReason? pendingPromptReason;
  final bool? wifiEnabled;
  final int? networkSuggestionStatus;
  final int? approvalStatus;
  final int? compatResultCode;
  final int? compatNetworkResultCode;
  final List<int> compatNetworkResultCodes;
  final String? message;

  Ntut8021xPendingPromptReason? get pendingCompatPromptReason =>
      pendingPromptReason;

  List<int> get addNetworkResultCodes => compatNetworkResultCodes;

  bool get isSuccess =>
      status == Ntut8021xProvisioningStatus.success ||
      status == Ntut8021xProvisioningStatus.configured ||
      status == Ntut8021xProvisioningStatus.successPendingWifi ||
      status == Ntut8021xProvisioningStatus.compatSuccess;
}
