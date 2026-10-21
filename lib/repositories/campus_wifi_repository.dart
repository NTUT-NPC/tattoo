import 'package:riverpod/riverpod.dart';
import 'package:tattoo/models/campus_wifi.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/repositories/preferences_repository.dart';
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
    isWifiEnabled: () =>
        ref.read(preferencesRepositoryProvider).get(PrefKey.showWifiButton),
  );
});

class CampusWifiRepository {
  CampusWifiRepository({
    required this._authRepository,
    required this._platform,
    required this._provisioner,
    required this._autoReprovision,
    required this._stateStore,
    required this._isWifiEnabled,
  });

  final AuthRepository _authRepository;
  final CampusWifiPlatform _platform;
  final CampusWifiProvisioner _provisioner;
  final Ntut8021xAutoReprovision _autoReprovision;
  final Ntut8021xStateStore _stateStore;
  final Future<bool> Function() _isWifiEnabled;
  Future<void> _pendingConfigurationChange = Future<void>.value();

  static const _disabledAssistantData = Ntut8021xAssistantData(
    status: Ntut8021xAssistantStatus.unsupportedPlatform,
    capabilities: CampusWifiCapabilities.unsupported(),
    screenMode: Ntut8021xScreenMode.manualOnly,
    lastProvisioningMode: Ntut8021xProvisioningMode.none,
    showImmediatePromptCandidate: false,
  );

  Future<Ntut8021xAssistantData> getNtut8021xAssistantData() async {
    if (!await _isWifiEnabled()) return _disabledAssistantData;
    final capabilities = await _provisioner.getCapabilities();
    var storedState = await _stateStore.read();
    if (capabilities.isSuggestionPermissionDisallowed &&
        storedState.pendingCompatPromptReason ==
            Ntut8021xStoredPendingPromptReason.suggestionFallbackRequired) {
      await _stateStore.clearPendingCompatPrompt();
      storedState = await _stateStore.read();
    }
    if (!await _isWifiEnabled()) return _disabledAssistantData;
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
    if (!await _isWifiEnabled()) return _disabledAssistantData;
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
    if (!await _isWifiEnabled()) return null;
    if ((await _provisioner.getCapabilities())
            .isSuggestionPermissionDisallowed &&
        (await _stateStore.read()).pendingCompatPromptReason ==
            Ntut8021xStoredPendingPromptReason.suggestionFallbackRequired) {
      await _stateStore.clearPendingCompatPrompt();
      return null;
    }
    final storedReason = await _stateStore.consumePendingCompatPrompt();
    final reason = _pendingPromptReasonFromStored(storedReason);
    if (reason == null) return null;

    final credentials = await _authRepository.getStoredCredentials();
    if (credentials == null) return null;
    if (!await _isWifiEnabled()) return null;

    return Ntut8021xImmediatePromptData(
      reason: reason,
      identity: credentials.username,
      password: credentials.password,
    );
  }

  /// Queues setup through its final state and auto-refresh preference writes.
  Future<Ntut8021xProvisioningResult> provisionNtut8021x() =>
      _changeConfiguration(_provisionNtut8021x);

  Future<Ntut8021xProvisioningResult> _provisionNtut8021x() async {
    final data = await getNtut8021xAssistantData();
    if (!data.canProvisionAutomatically || !await _isWifiEnabled()) {
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
  }) => _changeConfiguration(
    () => _saveNtut8021xToSystem(
      identity: identity,
      password: password,
      pendingPromptReason: pendingPromptReason,
    ),
  );

  Future<Ntut8021xProvisioningResult> _saveNtut8021xToSystem({
    String? identity,
    String? password,
    Ntut8021xPendingPromptReason? pendingPromptReason,
  }) async {
    final data = await getNtut8021xAssistantData();
    final resolvedIdentity = identity ?? data.identity;
    final resolvedPassword = password ?? data.password;
    if (resolvedIdentity == null ||
        resolvedPassword == null ||
        !data.capabilities.canSaveToSystem ||
        !await _isWifiEnabled()) {
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

  /// Removes app-owned configuration after earlier manual setup finishes.
  /// User-owned saved networks are never removed.
  Future<Ntut8021xRemovalStatus> removeNtut8021x() =>
      _changeConfiguration(_removeNtut8021x);

  Future<Ntut8021xRemovalStatus> _removeNtut8021x() async {
    final capabilities = await _provisioner.getCapabilities();
    if (!capabilities.canRemoveNtut8021x) {
      return .unsupportedPlatform;
    }

    final status = await _autoReprovision.removeNtut8021x();
    if (status != Ntut8021xRemovalStatus.removed &&
        status != Ntut8021xRemovalStatus.removalRequested &&
        status != Ntut8021xRemovalStatus.manualRemovalRequired) {
      return status;
    }

    await _stateStore.markProvisioned(mode: .none);
    return status;
  }

  Future<T> _changeConfiguration<T>(Future<T> Function() change) {
    final operation = _pendingConfigurationChange.then((_) => change());
    // Keep failed operations visible to callers without blocking later changes.
    _pendingConfigurationChange = operation.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return operation;
  }

  Future<bool> openWifiSettings() async =>
      await _isWifiEnabled() && await _platform.openWifiSettings();

  Future<bool> openWifiPanel() async =>
      await _isWifiEnabled() && await _platform.openWifiPanel();

  Future<bool> openWifiPermissionSettings() async =>
      await _isWifiEnabled() && await _platform.openWifiPermissionSettings();

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
