import 'package:flutter/foundation.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tattoo/models/campus_wifi.dart';
import 'package:tattoo/services/campus_wifi/android_campus_wifi_provisioner.dart';
import 'package:tattoo/services/campus_wifi/campus_wifi_platform.dart';
import 'package:tattoo/services/campus_wifi/ios_campus_wifi_provisioner.dart';
import 'package:tattoo/services/campus_wifi/ntut8021x_state_store.dart';

final campusWifiProvisionerProvider = Provider<CampusWifiProvisioner>((ref) {
  final platform = ref.watch(campusWifiPlatformProvider);
  final stateStore = ref.watch(ntut8021xStateStoreProvider);
  return switch (kIsWeb ? null : defaultTargetPlatform) {
    TargetPlatform.android => AndroidCampusWifiProvisioner(
      platform: platform,
      stateStore: stateStore,
    ),
    TargetPlatform.iOS => IosCampusWifiProvisioner(
      platform: platform,
      stateStore: stateStore,
    ),
    _ => const UnsupportedCampusWifiProvisioner(),
  };
});

/// Platform-specific Wi-Fi policy, selected at composition time, not by capabilities.
abstract interface class CampusWifiProvisioner {
  Future<CampusWifiCapabilities> getCapabilities();

  Ntut8021xScreenMode screenMode({
    required Ntut8021xAssistantStatus status,
    required CampusWifiCapabilities capabilities,
    required Ntut8021xPendingPromptReason? pendingPromptReason,
  });

  Ntut8021xPendingPromptReason? implicitPendingReason({
    required CampusWifiCapabilities capabilities,
    required Ntut8021xProvisioningMode lastProvisioningMode,
  });

  Future<Ntut8021xProvisioningResult> provision({
    required String identity,
    required String password,
    required CampusWifiCapabilities capabilities,
  });

  Future<Ntut8021xProvisioningResult> saveToSystem({
    required String identity,
    required String password,
    required CampusWifiCapabilities capabilities,
    required Ntut8021xPendingPromptReason? pendingPromptReason,
  });

  /// Removes app-owned configuration using the selected platform policy.
  Future<Ntut8021xRemovalStatus> remove({
    required Ntut8021xStoredProvisioningMode lastProvisioningMode,
  });

  Future<void> refreshCredentials({
    required String identity,
    required String password,
    String? previousIdentity,
    String? previousPassword,
  });
}

class UnsupportedCampusWifiProvisioner implements CampusWifiProvisioner {
  const UnsupportedCampusWifiProvisioner();

  @override
  Future<CampusWifiCapabilities> getCapabilities() async =>
      const CampusWifiCapabilities.unsupported();

  @override
  Ntut8021xScreenMode screenMode({
    required Ntut8021xAssistantStatus status,
    required CampusWifiCapabilities capabilities,
    required Ntut8021xPendingPromptReason? pendingPromptReason,
  }) => Ntut8021xScreenMode.manualOnly;

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
  }) async => const Ntut8021xProvisioningResult.unsupported();

  @override
  Future<Ntut8021xProvisioningResult> saveToSystem({
    required String identity,
    required String password,
    required CampusWifiCapabilities capabilities,
    required Ntut8021xPendingPromptReason? pendingPromptReason,
  }) async => const Ntut8021xProvisioningResult.unsupported();

  @override
  Future<Ntut8021xRemovalStatus> remove({
    required Ntut8021xStoredProvisioningMode lastProvisioningMode,
  }) async => Ntut8021xRemovalStatus.unsupportedPlatform;

  @override
  Future<void> refreshCredentials({
    required String identity,
    required String password,
    String? previousIdentity,
    String? previousPassword,
  }) async {}
}
