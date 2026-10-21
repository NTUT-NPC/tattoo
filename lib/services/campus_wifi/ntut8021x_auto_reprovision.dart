import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tattoo/services/campus_wifi/campus_wifi_provisioner.dart';
import 'package:tattoo/services/campus_wifi/ntut8021x_state_store.dart';
import 'package:tattoo/utils/shared_preferences.dart';

const ntut8021xAutoReprovisionPreferenceKey = 'ntut8021xAutoReprovisionEnabled';

final ntut8021xAutoReprovisionProvider = Provider<Ntut8021xAutoReprovision>((
  ref,
) {
  return Ntut8021xAutoReprovision(
    prefs: ref.watch(sharedPreferencesProvider),
    provisioner: ref.watch(campusWifiProvisionerProvider),
    stateStore: ref.watch(ntut8021xStateStoreProvider),
  );
});

/// Refreshes opted-in Wi-Fi credentials using the selected platform policy.
class Ntut8021xAutoReprovision {
  Ntut8021xAutoReprovision({
    required this._prefs,
    required this._provisioner,
    required this._stateStore,
  });

  final SharedPreferencesAsync _prefs;
  final CampusWifiProvisioner _provisioner;
  final Ntut8021xStateStore _stateStore;

  Future<bool> isEnabled() async {
    final enabled =
        await _prefs.getBool(ntut8021xAutoReprovisionPreferenceKey) ?? false;
    _logCampusWifi('Read auto reprovision flag: enabled=$enabled');
    return enabled;
  }

  Future<void> enable() async {
    await _prefs.setBool(ntut8021xAutoReprovisionPreferenceKey, true);
    _logCampusWifi('Updated auto reprovision flag: enabled=true');
  }

  Future<void> reprovisionIfEnabled({
    required String identity,
    required String password,
    String? previousIdentity,
    String? previousPassword,
  }) async {
    if (!await isEnabled()) {
      _logCampusWifi(
        'Skipped NTUT-802.1X auto reprovision because the flag is disabled',
      );
      return;
    }
    final storedState = await _stateStore.read();
    if (storedState.lastProvisioningMode ==
        Ntut8021xStoredProvisioningMode.none) {
      _logCampusWifi(
        'Skipped NTUT-802.1X auto reprovision because no provisioning mode is stored',
      );
      return;
    }
    if (previousIdentity == identity && previousPassword == password) {
      _logCampusWifi(
        'Skipped NTUT-802.1X auto reprovision because credentials did not change',
      );
      return;
    }
    await _provisioner.refreshCredentials(
      identity: identity,
      password: password,
      previousIdentity: previousIdentity,
      previousPassword: previousPassword,
    );
  }
}

void _logCampusWifi(String message) {
  log(message, name: 'CampusWifi');
  debugPrint('[CampusWifi] $message');
}
