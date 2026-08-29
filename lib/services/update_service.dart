import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tattoo/services/firebase_service.dart';
import 'package:tattoo/utils/pref_type.dart';

/// Remote Config key for the version configuration JSON.
const _versionConfigKey = 'version_config';

/// Parsed contents of the `version_config` Remote Config value.
///
/// ```json
/// {
///   "is_focus_update": true,
///   "last_version": { "ios": "1.6.9", "android": "1.6.9" },
///   "last_version_detail": "..."
/// }
/// ```
///
/// When `isForcedUpdate` is `true`, the router blocks all navigation.
/// When `false`, an optional update banner is shown without blocking the user.
typedef VersionConfig = ({
  bool isForcedUpdate,
  String requiredVersion,
  String detail,
});

/// Compares two semver-like version strings (e.g. "1.6.9" vs "1.0.0").
///
/// Returns `true` when [current] is strictly older than [required].
bool _isOutdated(String current, String required) {
  final c = current.split('.').map(int.tryParse).nonNulls.toList();
  final r = required.split('.').map(int.tryParse).nonNulls.toList();
  final len = r.length > c.length ? r.length : c.length;
  for (var i = 0; i < len; i++) {
    final cv = i < c.length ? c[i] : 0;
    final rv = i < r.length ? r[i] : 0;
    if (cv < rv) return true;
    if (cv > rv) return false;
  }
  return false;
}

/// Reads and parses the `version_config` Remote Config JSON, or `null` if
/// Firebase is disabled, the key is absent, or the JSON is malformed.
VersionConfig? _parseVersionConfig() {
  final rcResult = firebaseService.getRemoteConfigTyped(
    _versionConfigKey,
    PrefType.string,
  );

  if (!rcResult.isRemote) return null;

  final raw = rcResult.value as String;
  if (raw.isEmpty) return null;

  try {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final isForcedUpdate = json['is_focus_update'] as bool? ?? false;
    final versions = json['last_version'] as Map<String, dynamic>? ?? {};
    final detail = json['last_version_detail'] as String? ?? '';

    final platformKey = Platform.isIOS ? 'ios' : 'android';
    final requiredVersion = versions[platformKey] as String? ?? '';

    return (
      isForcedUpdate: isForcedUpdate,
      requiredVersion: requiredVersion,
      detail: detail,
    );
  } catch (e) {
    log('Failed to parse version_config: $e', name: 'UpdateService');
    return null;
  }
}

/// Checks whether the running app version is older than the version declared
/// in Remote Config.
///
/// Returns `null` when Firebase is disabled, the config key is absent, or the
/// app is already up to date — regardless of `is_focus_update`.
/// Returns a [VersionConfig] record (with `isForcedUpdate` set accordingly)
/// when the running version is outdated, covering both forced and optional
/// update scenarios.
Future<VersionConfig?> checkForUpdate() async {
  final config = _parseVersionConfig();
  if (config == null) return null;
  if (config.requiredVersion.isEmpty) return null;

  final info = await PackageInfo.fromPlatform();
  final currentVersion = info.version;

  if (_isOutdated(currentVersion, config.requiredVersion)) {
    log(
      '${config.isForcedUpdate ? 'Force' : 'Optional'} update available: '
      'current=$currentVersion, required=${config.requiredVersion}',
      name: 'UpdateService',
    );
    return config;
  }

  return null;
}

/// Holds the pending [VersionConfig] whenever the running version is outdated,
/// or `null` when up to date.
///
/// - `config.isForcedUpdate == true` → router gates all navigation to
///   [ForceUpdateScreen].
/// - `config.isForcedUpdate == false` → home screen shows a dismissible
///   optional-update banner without blocking the user.
class UpdateConfigNotifier extends Notifier<VersionConfig?> {
  @override
  VersionConfig? build() => null;

  void set(VersionConfig? config) => state = config;
}

final updateConfigProvider =
    NotifierProvider<UpdateConfigNotifier, VersionConfig?>(
      UpdateConfigNotifier.new,
    );

/// Session-scoped flag: `true` once the user dismisses the optional update
/// banner. Resets to `false` on each app launch or when a new update config
/// is fetched (e.g. via a Remote Config push).
class OptionalUpdateDismissedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void dismiss() => state = true;
  void reset() => state = false;
}

final optionalUpdateDismissedProvider =
    NotifierProvider<OptionalUpdateDismissedNotifier, bool>(
      OptionalUpdateDismissedNotifier.new,
    );

// ignore: avoid_classes_with_only_static_members
/// Coordinates the update check and wires Remote Config live updates.
class UpdateService {
  UpdateService._();

  /// Runs the initial update check and registers a listener so that a Remote
  /// Config push during the session triggers a recheck.
  ///
  /// Call once at app start, after Remote Config has been initialized.
  static Future<void> init(ProviderContainer container) async {
    await _check(container);

    // Re-check whenever Remote Config is updated at runtime.
    firebaseService.onConfigUpdated.listen((_) async {
      // Reset dismissal so the user sees the new config's banner/gate.
      container.read(optionalUpdateDismissedProvider.notifier).reset();
      await _check(container);
    });
  }

  static Future<void> _check(ProviderContainer container) async {
    final config = await checkForUpdate();
    container.read(updateConfigProvider.notifier).set(config);
  }
}
