import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:tattoo/models/campus_wifi.dart';
import 'package:tattoo/services/campus_wifi/campus_wifi_platform.dart';
import 'package:tattoo/services/campus_wifi/campus_wifi_provisioner.dart';
import 'package:tattoo/services/campus_wifi/ntut8021x_state_store.dart';

class AndroidCampusWifiProvisioner implements CampusWifiProvisioner {
  AndroidCampusWifiProvisioner({
    required this._platform,
    required this._stateStore,
  });

  final CampusWifiPlatform _platform;
  final Ntut8021xStateStore _stateStore;

  @override
  Future<CampusWifiCapabilities> getCapabilities() async {
    final capabilities = await _platform.getCapabilities();
    return CampusWifiCapabilities(
      isSupported: capabilities.isSupported,
      androidSdkInt: capabilities.androidSdkInt,
      canOpenWifiSettings: capabilities.canOpenWifiSettings,
      canOpenWifiPanel: capabilities.canOpenWifiPanel,
      canProvisionNtut8021xSuggestion:
          capabilities.canProvisionNtut8021xSuggestion,
      canProvisionNtut8021xCompat: capabilities.canProvisionNtut8021xCompat,
      canProvisionAutomatically:
          capabilities.canProvisionNtut8021xSuggestion &&
          (capabilities.androidSdkInt == null ||
              capabilities.androidSdkInt! >= 29),
      canSaveToSystem:
          capabilities.canProvisionNtut8021xCompat &&
          (capabilities.androidSdkInt ?? 0) >= 30,
      canRemoveNtut8021x:
          capabilities.isSupported && (capabilities.androidSdkInt ?? 0) >= 29,
      suggestionPermissionState:
          switch (capabilities.suggestionPermissionState) {
            'allowed' => CampusWifiSuggestionPermissionState.allowed,
            'disallowed' => CampusWifiSuggestionPermissionState.disallowed,
            _ => CampusWifiSuggestionPermissionState.unknown,
          },
    );
  }

  @override
  Ntut8021xScreenMode screenMode({
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
    if (capabilities.isSuggestionPermissionDisallowed) {
      return Ntut8021xScreenMode.permissionRequired;
    }
    if (pendingPromptReason != null &&
        capabilities.isAndroid11OrNewer &&
        capabilities.canProvisionNtut8021xCompat) {
      return Ntut8021xScreenMode.compatRetry;
    }
    if (!capabilities.canProvisionNtut8021xSuggestion) {
      return Ntut8021xScreenMode.manualOnly;
    }
    return Ntut8021xScreenMode.normal;
  }

  @override
  Ntut8021xPendingPromptReason? implicitPendingReason({
    required CampusWifiCapabilities capabilities,
    required Ntut8021xProvisioningMode lastProvisioningMode,
  }) => null;

  @override
  Future<Ntut8021xProvisioningResult> provision({
    required String identity,
    required String password,
    required CampusWifiCapabilities capabilities,
  }) async {
    if (!capabilities.isSupported || !capabilities.canProvisionAutomatically) {
      return const Ntut8021xProvisioningResult.unsupported();
    }
    final provisioning = await _platform.provisionNtut8021x(
      identity: identity,
      password: password,
    );
    final suggestionResult = _provisioningResultFromDto(
      provisioning,
      defaultMode: Ntut8021xProvisioningMode.suggestion,
    );
    if (_isSuggestionSuccess(suggestionResult.status) &&
        provisioning.suggestionPermissionState != 'disallowed') {
      await _stateStore.markProvisioned(
        mode: Ntut8021xStoredProvisioningMode.suggestion,
      );
      return suggestionResult;
    }
    if (suggestionResult.status ==
            Ntut8021xProvisioningStatus.approvalRejected ||
        suggestionResult.status ==
            Ntut8021xProvisioningStatus.approvalPending ||
        provisioning.suggestionPermissionState == 'disallowed') {
      await _clearSuggestionFallbackPrompt();
      return suggestionResult;
    }
    if (capabilities.isAndroid11OrNewer &&
        capabilities.canProvisionNtut8021xCompat) {
      await _stateStore.setPendingCompatPrompt(
        reason: Ntut8021xStoredPendingPromptReason.suggestionFallbackRequired,
        immediate: false,
      );
      return _copyResult(
        suggestionResult,
        pendingPromptReason:
            Ntut8021xPendingPromptReason.suggestionFallbackRequired,
      );
    }
    return suggestionResult;
  }

  @override
  Future<Ntut8021xProvisioningResult> saveToSystem({
    required String identity,
    required String password,
    required CampusWifiCapabilities capabilities,
    required Ntut8021xPendingPromptReason? pendingPromptReason,
  }) async {
    if (!capabilities.isSupported || !capabilities.canSaveToSystem) {
      return const Ntut8021xProvisioningResult.unsupported();
    }
    final provisioning = await _platform.saveNtut8021xToSystem(
      identity: identity,
      password: password,
    );
    final compatResult = _provisioningResultFromDto(
      provisioning,
      defaultMode: Ntut8021xProvisioningMode.compat,
    );
    if (compatResult.status == Ntut8021xProvisioningStatus.compatSuccess) {
      await _stateStore.markProvisioned(
        mode: Ntut8021xStoredProvisioningMode.compat,
      );
      return compatResult;
    }
    final storedState = await _stateStore.read();
    final nextPendingPromptReason =
        pendingPromptReason ??
        switch (storedState.pendingCompatPromptReason) {
          Ntut8021xStoredPendingPromptReason.credentialChanged =>
            Ntut8021xPendingPromptReason.credentialChanged,
          _ => Ntut8021xPendingPromptReason.suggestionFallbackRequired,
        };
    await _stateStore.setPendingCompatPrompt(
      reason: switch (nextPendingPromptReason) {
        Ntut8021xPendingPromptReason.credentialChanged =>
          Ntut8021xStoredPendingPromptReason.credentialChanged,
        Ntut8021xPendingPromptReason.suggestionFallbackRequired =>
          Ntut8021xStoredPendingPromptReason.suggestionFallbackRequired,
      },
      immediate: false,
    );
    return _copyResult(
      compatResult,
      pendingPromptReason: nextPendingPromptReason,
    );
  }

  @override
  Future<Ntut8021xRemovalStatus> remove({
    required Ntut8021xStoredProvisioningMode lastProvisioningMode,
  }) async {
    final status = switch (await _platform.removeNtut8021x()) {
      'removed' => Ntut8021xRemovalStatus.removed,
      'removalRequested' => Ntut8021xRemovalStatus.removalRequested,
      'unsupportedPlatform' => Ntut8021xRemovalStatus.unsupportedPlatform,
      _ => Ntut8021xRemovalStatus.failed,
    };
    if ((status == Ntut8021xRemovalStatus.removed ||
            status == Ntut8021xRemovalStatus.removalRequested) &&
        lastProvisioningMode == Ntut8021xStoredProvisioningMode.compat) {
      return Ntut8021xRemovalStatus.manualRemovalRequired;
    }
    return status;
  }

  @override
  Future<void> refreshCredentials({
    required String identity,
    required String password,
    String? previousIdentity,
    String? previousPassword,
  }) async {
    final storedState = await _stateStore.read();
    if (storedState.lastProvisioningMode ==
            Ntut8021xStoredProvisioningMode.compat ||
        storedState.lastProvisioningMode ==
            Ntut8021xStoredProvisioningMode.direct) {
      await _stateStore.setPendingCompatPrompt(
        reason: Ntut8021xStoredPendingPromptReason.credentialChanged,
        immediate: true,
      );
      _logCampusWifi(
        'Queued NTUT-802.1X update prompt because provisioning requires consent',
      );
      return;
    }
    final capabilities = await getCapabilities();
    if (capabilities.isSuggestionPermissionDisallowed) {
      await _clearSuggestionFallbackPrompt();
      _logCampusWifi(
        'Skipped NTUT-802.1X refresh: Wi-Fi control permission is required',
      );
      return;
    }
    if (!capabilities.isSupported ||
        !capabilities.canProvisionNtut8021xSuggestion) {
      await _queueCompatPromptIfAvailable(capabilities);
      _logCampusWifi(
        'Skipped NTUT-802.1X auto reprovision because suggestion mode is unavailable',
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
    if (result.status == 'approvalRejected' ||
        result.status == 'approvalPending' ||
        result.suggestionPermissionState == 'disallowed') {
      await _clearSuggestionFallbackPrompt();
      _logCampusWifi(
        'Skipped compatibility fallback: Wi-Fi suggestion approval is required',
      );
      return;
    }
    if (result.status == 'success' || result.status == 'successPendingWifi') {
      await _stateStore.markProvisioned(
        mode: Ntut8021xStoredProvisioningMode.suggestion,
      );
      _logCampusWifi('Finished NTUT-802.1X auto reprovision successfully');
      return;
    }
    await _queueCompatPromptIfAvailable(capabilities);
    _logCampusWifi(
      'Finished NTUT-802.1X auto reprovision without silent success; '
      'result=${result.status}',
    );
  }

  Future<void> _clearSuggestionFallbackPrompt() async {
    if ((await _stateStore.read()).pendingCompatPromptReason ==
        Ntut8021xStoredPendingPromptReason.suggestionFallbackRequired) {
      await _stateStore.clearPendingCompatPrompt();
    }
  }

  Future<void> _queueCompatPromptIfAvailable(
    CampusWifiCapabilities capabilities,
  ) async {
    if (!capabilities.isSupported ||
        !capabilities.isAndroid11OrNewer ||
        !capabilities.canProvisionNtut8021xCompat) {
      return;
    }
    await _stateStore.setPendingCompatPrompt(
      reason: Ntut8021xStoredPendingPromptReason.suggestionFallbackRequired,
      immediate: true,
    );
  }

  Ntut8021xProvisioningResult _provisioningResultFromDto(
    Ntut8021xProvisioningDto provisioning, {
    required Ntut8021xProvisioningMode defaultMode,
  }) {
    var status = switch (provisioning.status) {
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
    if (provisioning.suggestionPermissionState == 'disallowed' &&
        _isSuggestionSuccess(status)) {
      status = Ntut8021xProvisioningStatus.approvalRejected;
    }
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
      wifiEnabled: provisioning.wifiEnabled,
      networkSuggestionStatus: provisioning.networkSuggestionStatus,
      approvalStatus: provisioning.approvalStatus,
      compatResultCode: provisioning.compatResultCode,
      compatNetworkResultCode: provisioning.compatNetworkResultCodes.isEmpty
          ? null
          : provisioning.compatNetworkResultCodes.first,
      compatNetworkResultCodes: provisioning.compatNetworkResultCodes,
      message: provisioning.message,
    );
  }

  Ntut8021xProvisioningResult _copyResult(
    Ntut8021xProvisioningResult result, {
    required Ntut8021xPendingPromptReason? pendingPromptReason,
  }) {
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
    );
  }

  bool _isSuggestionSuccess(Ntut8021xProvisioningStatus status) =>
      status == Ntut8021xProvisioningStatus.success ||
      status == Ntut8021xProvisioningStatus.successPendingWifi;
}

void _logCampusWifi(String message) {
  log(message, name: 'CampusWifi');
  debugPrint('[CampusWifi] $message');
}
