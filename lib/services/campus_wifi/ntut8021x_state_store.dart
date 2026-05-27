import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tattoo/utils/shared_preferences.dart';

enum Ntut8021xStoredProvisioningMode { none, suggestion, compat }

enum Ntut8021xStoredPendingPromptReason {
  credentialChanged,
  suggestionFallbackRequired,
}

class Ntut8021xStoredState {
  const Ntut8021xStoredState({
    required this.lastProvisioningMode,
    required this.pendingCompatPromptReason,
    required this.pendingImmediatePrompt,
  });

  const Ntut8021xStoredState.initial()
    : this(
        lastProvisioningMode: Ntut8021xStoredProvisioningMode.none,
        pendingCompatPromptReason: null,
        pendingImmediatePrompt: false,
      );

  final Ntut8021xStoredProvisioningMode lastProvisioningMode;
  final Ntut8021xStoredPendingPromptReason? pendingCompatPromptReason;
  final bool pendingImmediatePrompt;
}

final ntut8021xStateStoreProvider = Provider<Ntut8021xStateStore>((ref) {
  return Ntut8021xStateStore(ref.watch(sharedPreferencesProvider));
});

class Ntut8021xStateStore {
  Ntut8021xStateStore(this._prefs);

  static const _modeKey = 'ntut8021x.lastProvisioningMode';
  static const _legacyFingerprintKey = 'ntut8021x.lastCredentialFingerprint';
  static const _pendingReasonKey = 'ntut8021x.pendingCompatPromptReason';
  static const _pendingImmediateKey = 'ntut8021x.pendingImmediatePrompt';

  final SharedPreferencesAsync _prefs;

  Future<Ntut8021xStoredState> read() async {
    await _prefs.remove(_legacyFingerprintKey);
    final mode = _decodeMode(await _prefs.getString(_modeKey));
    final pendingReason = _decodeReason(
      await _prefs.getString(_pendingReasonKey),
    );
    final pendingImmediate =
        await _prefs.getBool(_pendingImmediateKey) ?? false;

    return Ntut8021xStoredState(
      lastProvisioningMode: mode,
      pendingCompatPromptReason: pendingReason,
      pendingImmediatePrompt: pendingImmediate,
    );
  }

  Future<void> markProvisioned({
    required Ntut8021xStoredProvisioningMode mode,
  }) async {
    await _prefs.remove(_legacyFingerprintKey);
    await _prefs.setString(_modeKey, mode.name);
    await clearPendingCompatPrompt();
  }

  Future<void> setPendingCompatPrompt({
    required Ntut8021xStoredPendingPromptReason reason,
    required bool immediate,
  }) async {
    await _prefs.setString(_pendingReasonKey, reason.name);
    await _prefs.setBool(_pendingImmediateKey, immediate);
  }

  Future<void> clearPendingCompatPrompt() async {
    await _prefs.remove(_pendingReasonKey);
    await _prefs.setBool(_pendingImmediateKey, false);
  }

  Future<Ntut8021xStoredPendingPromptReason?>
  consumePendingCompatPrompt() async {
    final state = await read();
    if (!state.pendingImmediatePrompt) {
      return null;
    }

    await _prefs.setBool(_pendingImmediateKey, false);
    return state.pendingCompatPromptReason;
  }

  Ntut8021xStoredProvisioningMode _decodeMode(String? value) {
    return Ntut8021xStoredProvisioningMode.values.firstWhere(
      (candidate) => candidate.name == value,
      orElse: () => Ntut8021xStoredProvisioningMode.none,
    );
  }

  Ntut8021xStoredPendingPromptReason? _decodeReason(String? value) {
    for (final candidate in Ntut8021xStoredPendingPromptReason.values) {
      if (candidate.name == value) return candidate;
    }
    return null;
  }
}
