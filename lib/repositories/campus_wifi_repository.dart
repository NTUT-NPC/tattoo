import 'package:riverpod/riverpod.dart';
import 'package:tattoo/models/campus_wifi.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/services/campus_wifi/campus_wifi_platform.dart';
import 'package:tattoo/services/campus_wifi/campus_wifi_provisioner.dart';
import 'package:tattoo/services/campus_wifi/ntut8021x_auto_reprovision.dart';
import 'package:tattoo/services/campus_wifi/ntut8021x_state_store.dart';

final campusWifiRepositoryProvider = Provider<CampusWifiRepository>((ref) {
  return CampusWifiRepository(
    authRepository: ref.watch(authRepositoryProvider),
    platform: ref.watch(campusWifiPlatformProvider),
    provisioner: ref.watch(campusWifiProvisionerProvider),
    autoReprovision: ref.watch(ntut8021xAutoReprovisionProvider),
    stateStore: ref.watch(ntut8021xStateStoreProvider),
  );
});

class CampusWifiRepository {
  CampusWifiRepository({
    required this._authRepository,
    required this._platform,
    required this._provisioner,
    required this._autoReprovision,
    required this._stateStore,
  });

  final AuthRepository _authRepository;
  final CampusWifiPlatform _platform;
  final CampusWifiProvisioner _provisioner;
  final Ntut8021xAutoReprovision _autoReprovision;
  final Ntut8021xStateStore _stateStore;

  Future<Ntut8021xAssistantData> getNtut8021xAssistantData() async {
    final capabilities = await _provisioner.getCapabilities();
    final storedState = await _stateStore.read();
    final lastProvisioningMode = _provisioningModeFromStored(
      storedState.lastProvisioningMode,
    );
    final pendingPromptReason =
        _pendingPromptReasonFromStored(storedState.pendingCompatPromptReason) ??
        _provisioner.implicitPendingReason(
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
      screenMode: _provisioner.screenMode(
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

    final result = await _provisioner.provision(
      identity: data.identity!,
      password: data.password!,
      capabilities: data.capabilities,
    );
    if (result.isSuccess) await _autoReprovision.enable();
    return result;
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
        !data.capabilities.canSaveToSystem) {
      return const Ntut8021xProvisioningResult.unsupported();
    }

    final result = await _provisioner.saveToSystem(
      identity: resolvedIdentity,
      password: resolvedPassword,
      capabilities: data.capabilities,
      pendingPromptReason: pendingPromptReason ?? data.pendingPromptReason,
    );
    if (result.isSuccess) await _autoReprovision.enable();
    return result;
  }

  Future<bool> openWifiSettings() => _platform.openWifiSettings();

  Future<bool> openWifiPanel() => _platform.openWifiPanel();

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

  Ntut8021xProvisioningMode _provisioningModeFromStored(
    Ntut8021xStoredProvisioningMode mode,
  ) {
    return switch (mode) {
      Ntut8021xStoredProvisioningMode.suggestion =>
        Ntut8021xProvisioningMode.suggestion,
      Ntut8021xStoredProvisioningMode.compat =>
        Ntut8021xProvisioningMode.compat,
      Ntut8021xStoredProvisioningMode.direct =>
        Ntut8021xProvisioningMode.direct,
      Ntut8021xStoredProvisioningMode.none => Ntut8021xProvisioningMode.none,
    };
  }
}
