import 'package:tattoo/models/campus_wifi.dart';
import 'package:tattoo/services/campus_wifi/campus_wifi_platform.dart';
import 'package:tattoo/services/campus_wifi/campus_wifi_provisioner.dart';
import 'package:tattoo/services/campus_wifi/ntut8021x_state_store.dart';

class IosCampusWifiProvisioner implements CampusWifiProvisioner {
  IosCampusWifiProvisioner({
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
      androidSdkInt: null,
      canOpenWifiSettings: capabilities.canOpenWifiSettings,
      canOpenWifiPanel: capabilities.canOpenWifiPanel,
      canProvisionNtut8021xSuggestion: false,
      canProvisionNtut8021xCompat: false,
      canProvisionAutomatically: capabilities.canProvisionNtut8021x,
      canSaveToSystem: capabilities.canProvisionNtut8021x,
      suggestionPermissionState: CampusWifiSuggestionPermissionState.unknown,
    );
  }

  @override
  Ntut8021xScreenMode screenMode({
    required Ntut8021xAssistantStatus status,
    required CampusWifiCapabilities capabilities,
    required Ntut8021xPendingPromptReason? pendingPromptReason,
  }) => capabilities.isSupported && capabilities.canProvisionAutomatically
      ? Ntut8021xScreenMode.normal
      : Ntut8021xScreenMode.manualOnly;

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
    return _handleProvisioningResult(provisioning);
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
    return _handleProvisioningResult(provisioning);
  }

  Future<Ntut8021xProvisioningResult> _handleProvisioningResult(
    Ntut8021xProvisioningDto provisioning,
  ) async {
    final status = switch (provisioning.status) {
      'configured' => Ntut8021xProvisioningStatus.configured,
      'cancelled' => Ntut8021xProvisioningStatus.cancelled,
      'alreadyAssociated' => Ntut8021xProvisioningStatus.alreadyAssociated,
      'unsupportedPlatform' => Ntut8021xProvisioningStatus.unsupportedPlatform,
      _ => Ntut8021xProvisioningStatus.failed,
    };
    if (status == Ntut8021xProvisioningStatus.configured) {
      await _stateStore.markProvisioned(
        mode: Ntut8021xStoredProvisioningMode.direct,
      );
    }
    return Ntut8021xProvisioningResult(
      status: status,
      androidSdkInt: null,
      usedHiddenCaPath: false,
      lastProvisioningMode: Ntut8021xProvisioningMode.direct,
      usedCompatFallback: false,
      compatNetworkResultCodes: const <int>[],
      message: provisioning.message,
    );
  }

  @override
  Future<void> refreshCredentials({
    required String identity,
    required String password,
    String? previousIdentity,
    String? previousPassword,
  }) => _stateStore.setPendingCompatPrompt(
    reason: Ntut8021xStoredPendingPromptReason.credentialChanged,
    immediate: true,
  );
}
