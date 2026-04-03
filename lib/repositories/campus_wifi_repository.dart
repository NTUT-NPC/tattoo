import 'package:riverpod/riverpod.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/services/campus_wifi/campus_wifi_platform.dart';
import 'package:tattoo/services/campus_wifi/ntut8021x_state_store.dart';

final campusWifiRepositoryProvider = Provider<CampusWifiRepository>((ref) {
  return CampusWifiRepository(
    authRepository: ref.watch(authRepositoryProvider),
    platform: ref.watch(campusWifiPlatformProvider),
    autoReprovision: ref.watch(ntut8021xAutoReprovisionProvider),
    stateStore: ref.watch(ntut8021xStateStoreProvider),
  );
});

enum Ntut8021xAssistantStatus {
  ready,
  notLoggedIn,
  credentialsMissing,
  unsupportedPlatform,
}

enum Ntut8021xScreenMode { normal, compatRetry, manualOnly }

enum Ntut8021xPendingPromptReason {
  credentialChanged,
  suggestionFallbackRequired,
}

typedef Ntut8021xPendingCompatPromptReason = Ntut8021xPendingPromptReason;

enum Ntut8021xProvisioningMode { suggestion, compat, none }

enum Ntut8021xProvisioningStatus {
  success,
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
        suggestionPermissionState: CampusWifiSuggestionPermissionState.unknown,
      );

  final bool isSupported;
  final int? androidSdkInt;
  final bool canOpenWifiSettings;
  final bool canOpenWifiPanel;
  final bool canProvisionNtut8021xSuggestion;
  final bool canProvisionNtut8021xCompat;
  final CampusWifiSuggestionPermissionState suggestionPermissionState;

  bool get isAndroid10 => androidSdkInt == 29;

  bool get isAndroid11OrNewer => (androidSdkInt ?? 0) >= 30;

  bool get isAndroid12OrNewer => (androidSdkInt ?? 0) >= 31;

  bool get isLegacyAndroidManualOnly => (androidSdkInt ?? 0) < 29;

  bool get isSuggestionPermissionDisallowed =>
      suggestionPermissionState ==
      CampusWifiSuggestionPermissionState.disallowed;

  bool get canProvisionNtut8021x =>
      canProvisionNtut8021xSuggestion || canProvisionNtut8021xCompat;
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
      capabilities.canProvisionNtut8021xSuggestion;

  bool get canRetryWithCompat =>
      status == Ntut8021xAssistantStatus.ready &&
      screenMode == Ntut8021xScreenMode.compatRetry &&
      capabilities.canProvisionNtut8021xCompat &&
      capabilities.isAndroid11OrNewer &&
      canCopyIdentity &&
      canCopyPassword;

  bool get canUseCompatMode => canRetryWithCompat;
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
    required this.usedCompatFallback,
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
        usedCompatFallback: false,
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
  final bool usedCompatFallback;

  Ntut8021xPendingPromptReason? get pendingCompatPromptReason =>
      pendingPromptReason;

  bool get fallbackTriggered => usedCompatFallback;

  List<int> get addNetworkResultCodes => compatNetworkResultCodes;

  bool get isSuccess =>
      status == Ntut8021xProvisioningStatus.success ||
      status == Ntut8021xProvisioningStatus.successPendingWifi ||
      status == Ntut8021xProvisioningStatus.compatSuccess;
}

class CampusWifiRepository {
  CampusWifiRepository({
    required AuthRepository authRepository,
    required CampusWifiPlatform platform,
    required Ntut8021xAutoReprovision autoReprovision,
    required Ntut8021xStateStore stateStore,
  }) : _authRepository = authRepository,
       _platform = platform,
       _autoReprovision = autoReprovision,
       _stateStore = stateStore;

  final AuthRepository _authRepository;
  final CampusWifiPlatform _platform;
  final Ntut8021xAutoReprovision _autoReprovision;
  final Ntut8021xStateStore _stateStore;

  Future<Ntut8021xAssistantData> getNtut8021xAssistantData() async {
    final capabilities = await _getCapabilities();
    final storedState = await _stateStore.read();
    final lastProvisioningMode = _provisioningModeFromStored(
      storedState.lastProvisioningMode,
    );
    final pendingPromptReason =
        _pendingPromptReasonFromStored(storedState.pendingCompatPromptReason) ??
        _deriveImplicitPendingReason(
          capabilities: capabilities,
          lastProvisioningMode: lastProvisioningMode,
        );

    if (!capabilities.isSupported) {
      return Ntut8021xAssistantData(
        status: Ntut8021xAssistantStatus.unsupportedPlatform,
        capabilities: capabilities,
        screenMode: Ntut8021xScreenMode.manualOnly,
        lastProvisioningMode: lastProvisioningMode,
        pendingPromptReason: pendingPromptReason,
        showImmediatePromptCandidate: storedState.pendingImmediatePrompt,
      );
    }

    final user = await _authRepository.getLocalUser();
    if (user == null) {
      return Ntut8021xAssistantData(
        status: Ntut8021xAssistantStatus.notLoggedIn,
        capabilities: capabilities,
        screenMode: Ntut8021xScreenMode.normal,
        lastProvisioningMode: lastProvisioningMode,
        pendingPromptReason: pendingPromptReason,
        showImmediatePromptCandidate: storedState.pendingImmediatePrompt,
      );
    }

    final credentials = await _authRepository.getStoredCredentials();
    final status = credentials == null
        ? Ntut8021xAssistantStatus.credentialsMissing
        : Ntut8021xAssistantStatus.ready;

    return Ntut8021xAssistantData(
      status: status,
      capabilities: capabilities,
      screenMode: _deriveScreenMode(
        status: status,
        capabilities: capabilities,
        pendingPromptReason: pendingPromptReason,
      ),
      lastProvisioningMode: lastProvisioningMode,
      pendingPromptReason: pendingPromptReason,
      showImmediatePromptCandidate: storedState.pendingImmediatePrompt,
      identity: credentials?.username ?? user.studentId,
      password: credentials?.password,
    );
  }

  Future<Ntut8021xImmediatePromptData?> consumePendingImmediatePrompt() async {
    final storedReason = await _stateStore.consumePendingCompatPrompt();
    final reason = _pendingPromptReasonFromStored(storedReason);
    if (reason == null) return null;

    final credentials = await _authRepository.getStoredCredentials();
    if (credentials == null) return null;

    return Ntut8021xImmediatePromptData(
      reason: reason,
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
    final suggestionResult = _provisioningResultFromDto(
      provisioning,
      defaultMode: Ntut8021xProvisioningMode.suggestion,
    );

    if (_isSuggestionSuccess(suggestionResult.status)) {
      await _autoReprovision.enable();
      await _stateStore.markProvisioned(
        mode: Ntut8021xStoredProvisioningMode.suggestion,
      );
      return suggestionResult;
    }

    if (_shouldAutoFallbackToCompat(
      capabilities: data.capabilities,
      result: suggestionResult,
    )) {
      final compatResult = await saveNtut8021xToSystem(
        identity: data.identity,
        password: data.password,
        pendingPromptReason:
            Ntut8021xPendingPromptReason.suggestionFallbackRequired,
      );
      return Ntut8021xProvisioningResult(
        status: compatResult.status,
        androidSdkInt: compatResult.androidSdkInt,
        usedHiddenCaPath: compatResult.usedHiddenCaPath,
        lastProvisioningMode: compatResult.lastProvisioningMode,
        pendingPromptReason: compatResult.pendingPromptReason,
        wifiEnabled: compatResult.wifiEnabled,
        networkSuggestionStatus: compatResult.networkSuggestionStatus,
        approvalStatus: compatResult.approvalStatus,
        compatResultCode: compatResult.compatResultCode,
        compatNetworkResultCode: compatResult.compatNetworkResultCode,
        compatNetworkResultCodes: compatResult.compatNetworkResultCodes,
        message: compatResult.message,
        usedCompatFallback: true,
      );
    }

    if (data.capabilities.isAndroid11OrNewer &&
        data.capabilities.canProvisionNtut8021xCompat) {
      await _stateStore.setPendingCompatPrompt(
        reason: Ntut8021xStoredPendingPromptReason.suggestionFallbackRequired,
        immediate: false,
      );
      return _copyResultWithPendingReason(
        suggestionResult,
        Ntut8021xPendingPromptReason.suggestionFallbackRequired,
      );
    }

    return suggestionResult;
  }

  Future<Ntut8021xProvisioningResult> saveNtut8021xToSystem({
    String? identity,
    String? password,
    Ntut8021xPendingPromptReason? pendingPromptReason,
  }) async {
    final data = await getNtut8021xAssistantData();
    final resolvedIdentity = identity ?? data.identity;
    final resolvedPassword = password ?? data.password;
    if (resolvedIdentity == null ||
        resolvedPassword == null ||
        !data.capabilities.canProvisionNtut8021xCompat ||
        !data.capabilities.isAndroid11OrNewer) {
      return const Ntut8021xProvisioningResult.unsupported();
    }

    final provisioning = await _platform.saveNtut8021xToSystem(
      identity: resolvedIdentity,
      password: resolvedPassword,
    );
    final compatResult = _provisioningResultFromDto(
      provisioning,
      defaultMode: Ntut8021xProvisioningMode.compat,
    );

    if (compatResult.status == Ntut8021xProvisioningStatus.compatSuccess) {
      await _autoReprovision.enable();
      await _stateStore.markProvisioned(
        mode: Ntut8021xStoredProvisioningMode.compat,
      );
      return compatResult;
    }

    final nextPendingPromptReason =
        pendingPromptReason ??
        data.pendingPromptReason ??
        Ntut8021xPendingPromptReason.suggestionFallbackRequired;
    await _stateStore.setPendingCompatPrompt(
      reason: _storedPendingPromptReason(nextPendingPromptReason),
      immediate: false,
    );
    return _copyResultWithPendingReason(compatResult, nextPendingPromptReason);
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
      canProvisionNtut8021xSuggestion:
          capabilities.canProvisionNtut8021xSuggestion,
      canProvisionNtut8021xCompat: capabilities.canProvisionNtut8021xCompat,
      suggestionPermissionState: _suggestionPermissionStateFromWire(
        capabilities.suggestionPermissionState,
      ),
    );
  }

  Ntut8021xScreenMode _deriveScreenMode({
    required Ntut8021xAssistantStatus status,
    required CampusWifiCapabilities capabilities,
    required Ntut8021xPendingPromptReason? pendingPromptReason,
  }) {
    if (!capabilities.isSupported || capabilities.isLegacyAndroidManualOnly) {
      return Ntut8021xScreenMode.manualOnly;
    }

    if (status != Ntut8021xAssistantStatus.ready) {
      return Ntut8021xScreenMode.normal;
    }

    if (pendingPromptReason != null &&
        capabilities.isAndroid11OrNewer &&
        capabilities.canProvisionNtut8021xCompat) {
      return Ntut8021xScreenMode.compatRetry;
    }

    if (capabilities.isSuggestionPermissionDisallowed) {
      if (capabilities.isAndroid11OrNewer &&
          capabilities.canProvisionNtut8021xCompat) {
        return Ntut8021xScreenMode.compatRetry;
      }
      return Ntut8021xScreenMode.manualOnly;
    }

    if (!capabilities.canProvisionNtut8021xSuggestion) {
      return Ntut8021xScreenMode.manualOnly;
    }

    return Ntut8021xScreenMode.normal;
  }

  Ntut8021xPendingPromptReason? _deriveImplicitPendingReason({
    required CampusWifiCapabilities capabilities,
    required Ntut8021xProvisioningMode lastProvisioningMode,
  }) {
    if (lastProvisioningMode == Ntut8021xProvisioningMode.compat) {
      return null;
    }

    if (capabilities.isAndroid11OrNewer &&
        capabilities.canProvisionNtut8021xCompat &&
        capabilities.isSuggestionPermissionDisallowed) {
      return Ntut8021xPendingPromptReason.suggestionFallbackRequired;
    }

    return null;
  }

  bool _shouldAutoFallbackToCompat({
    required CampusWifiCapabilities capabilities,
    required Ntut8021xProvisioningResult result,
  }) {
    return capabilities.isAndroid11OrNewer &&
        capabilities.canProvisionNtut8021xCompat &&
        (result.status == Ntut8021xProvisioningStatus.approvalRejected ||
            result.pendingPromptReason ==
                Ntut8021xPendingPromptReason.suggestionFallbackRequired);
  }

  Ntut8021xProvisioningResult _provisioningResultFromDto(
    Ntut8021xProvisioningDto provisioning, {
    required Ntut8021xProvisioningMode defaultMode,
  }) {
    final status = _provisioningStatusFromWire(provisioning.status);
    final pendingPromptReason = _pendingPromptReasonFromProvisioning(
      status: status,
      suggestionPermissionState: provisioning.suggestionPermissionState,
    );
    return Ntut8021xProvisioningResult(
      status: status,
      androidSdkInt: provisioning.androidSdkInt,
      usedHiddenCaPath: provisioning.usedHiddenCaPath,
      lastProvisioningMode: switch (status) {
        Ntut8021xProvisioningStatus.success ||
        Ntut8021xProvisioningStatus.successPendingWifi =>
          Ntut8021xProvisioningMode.suggestion,
        Ntut8021xProvisioningStatus.compatSuccess ||
        Ntut8021xProvisioningStatus.compatAlreadyExists ||
        Ntut8021xProvisioningStatus.compatCancelled ||
        Ntut8021xProvisioningStatus.compatFailed =>
          Ntut8021xProvisioningMode.compat,
        _ => defaultMode,
      },
      pendingPromptReason: pendingPromptReason,
      wifiEnabled: provisioning.wifiEnabled,
      networkSuggestionStatus: provisioning.networkSuggestionStatus,
      approvalStatus: provisioning.approvalStatus,
      compatResultCode: provisioning.compatResultCode,
      compatNetworkResultCode: provisioning.compatNetworkResultCodes.isEmpty
          ? null
          : provisioning.compatNetworkResultCodes.first,
      compatNetworkResultCodes: provisioning.compatNetworkResultCodes,
      message: provisioning.message,
      usedCompatFallback: false,
    );
  }

  Ntut8021xProvisioningResult _copyResultWithPendingReason(
    Ntut8021xProvisioningResult result,
    Ntut8021xPendingPromptReason pendingPromptReason,
  ) {
    return Ntut8021xProvisioningResult(
      status: result.status,
      androidSdkInt: result.androidSdkInt,
      usedHiddenCaPath: result.usedHiddenCaPath,
      lastProvisioningMode: result.lastProvisioningMode,
      pendingPromptReason: pendingPromptReason,
      wifiEnabled: result.wifiEnabled,
      networkSuggestionStatus: result.networkSuggestionStatus,
      approvalStatus: result.approvalStatus,
      compatResultCode: result.compatResultCode,
      compatNetworkResultCode: result.compatNetworkResultCode,
      compatNetworkResultCodes: result.compatNetworkResultCodes,
      message: result.message,
      usedCompatFallback: result.usedCompatFallback,
    );
  }

  Ntut8021xPendingPromptReason? _pendingPromptReasonFromProvisioning({
    required Ntut8021xProvisioningStatus status,
    required String? suggestionPermissionState,
  }) {
    if (status == Ntut8021xProvisioningStatus.approvalRejected) {
      return Ntut8021xPendingPromptReason.suggestionFallbackRequired;
    }
    if (suggestionPermissionState == 'disallowed') {
      return Ntut8021xPendingPromptReason.suggestionFallbackRequired;
    }
    return null;
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
      'compatSuccess' => Ntut8021xProvisioningStatus.compatSuccess,
      'compatAlreadyExists' => Ntut8021xProvisioningStatus.compatAlreadyExists,
      'compatCancelled' => Ntut8021xProvisioningStatus.compatCancelled,
      'compatFailed' => Ntut8021xProvisioningStatus.compatFailed,
      _ => Ntut8021xProvisioningStatus.failed,
    };
  }

  CampusWifiSuggestionPermissionState _suggestionPermissionStateFromWire(
    String state,
  ) {
    return switch (state) {
      'allowed' => CampusWifiSuggestionPermissionState.allowed,
      'disallowed' => CampusWifiSuggestionPermissionState.disallowed,
      _ => CampusWifiSuggestionPermissionState.unknown,
    };
  }

  Ntut8021xPendingPromptReason? _pendingPromptReasonFromStored(
    Ntut8021xStoredPendingPromptReason? reason,
  ) {
    return switch (reason) {
      Ntut8021xStoredPendingPromptReason.credentialChanged =>
        Ntut8021xPendingPromptReason.credentialChanged,
      Ntut8021xStoredPendingPromptReason.suggestionFallbackRequired =>
        Ntut8021xPendingPromptReason.suggestionFallbackRequired,
      null => null,
    };
  }

  Ntut8021xStoredPendingPromptReason _storedPendingPromptReason(
    Ntut8021xPendingPromptReason reason,
  ) {
    return switch (reason) {
      Ntut8021xPendingPromptReason.credentialChanged =>
        Ntut8021xStoredPendingPromptReason.credentialChanged,
      Ntut8021xPendingPromptReason.suggestionFallbackRequired =>
        Ntut8021xStoredPendingPromptReason.suggestionFallbackRequired,
    };
  }

  Ntut8021xProvisioningMode _provisioningModeFromStored(
    Ntut8021xStoredProvisioningMode mode,
  ) {
    return switch (mode) {
      Ntut8021xStoredProvisioningMode.suggestion =>
        Ntut8021xProvisioningMode.suggestion,
      Ntut8021xStoredProvisioningMode.compat =>
        Ntut8021xProvisioningMode.compat,
      Ntut8021xStoredProvisioningMode.none => Ntut8021xProvisioningMode.none,
    };
  }

  bool _isSuggestionSuccess(Ntut8021xProvisioningStatus status) {
    return status == Ntut8021xProvisioningStatus.success ||
        status == Ntut8021xProvisioningStatus.successPendingWifi;
  }
}
