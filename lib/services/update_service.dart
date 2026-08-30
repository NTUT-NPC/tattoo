import 'dart:developer';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tattoo/services/firebase_service.dart';

/// Parsed contents of the update configuration from Remote Config.
///
/// When `isForcedUpdate` is `true`, the router blocks all navigation.
/// When `false`, an optional update banner is shown without blocking the user.
typedef VersionConfig = ({
  bool isForcedUpdate,
  String requiredVersion,
  String detail,
});

/// Compares two Semantic Versioning (SemVer) strings (e.g., "1.6.9", "1.0.0-pr.666").
///
/// Returns `true` when [current] is strictly older than [required].
bool _isOutdated(String current, String required) =>
    Version.parse(current) < Version.parse(required);

/// Reads and parses the update parameters from Remote Config.
///
/// Parameters:
/// - `isForceUpdate` (bool)
/// - `latestVersionName` (string)
/// - `updateNote` (string)
///
/// Returns `null` if Firebase is disabled, or if `latestVersionName` has no
/// remote value (defaults to no action).
VersionConfig? _parseVersionConfig() {
  final latestVersionRc = firebaseService.getRemoteConfigTyped(
    'latestVersionName',
    .string,
  );

  // If there's no latest version configured, default to no action.
  if (!latestVersionRc.isRemote) return null;
  final requiredVersion = latestVersionRc.value as String;
  if (requiredVersion.isEmpty) return null;

  final forceUpdateRc = firebaseService.getRemoteConfigTyped(
    'isForceUpdate',
    .boolean,
  );

  final updateNoteRc = firebaseService.getRemoteConfigTyped(
    'updateNote',
    .string,
  );

  return (
    isForcedUpdate: (forceUpdateRc.value as bool?) ?? false,
    requiredVersion: requiredVersion,
    detail: (updateNoteRc.value as String?) ?? '',
  );
}

/// Gets the current application version exactly as structured in the About screen.
/// Includes `VERSION_SUFFIX` (e.g., `-pr.666` or `-daily20260830`) so that
/// SemVer pre-release comparisons work correctly.
Future<String> _getCurrentSemVer() async {
  final packageInfo = await PackageInfo.fromPlatform();
  const suffix = String.fromEnvironment('VERSION_SUFFIX');
  if (suffix.isEmpty) return packageInfo.version;

  final normalizedSuffix = suffix.startsWith('-')
      ? suffix.substring(1)
      : suffix;
  return '${packageInfo.version}-$normalizedSuffix';
}

/// Checks whether the running app version is older than the version declared
/// in Remote Config.
///
/// Returns `null` when Firebase is disabled, the config key is absent, or the
/// app is already up to date — regardless of `isForceUpdate`.
/// Returns a [VersionConfig] record (with `isForcedUpdate` set accordingly)
/// when the running version is outdated, covering both forced and optional
/// update scenarios.
Future<VersionConfig?> checkForUpdate() async {
  final config = _parseVersionConfig();
  if (config == null) return null;

  final currentVersion = await _getCurrentSemVer();

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
/// Coordinates the update check at app startup.
class UpdateService {
  UpdateService._();

  /// Runs the initial update check.
  ///
  /// Call once at app start, after Remote Config has been initialized.
  /// We intentionally do not listen to real-time Remote Config updates here to
  /// avoid interrupting the user's workflow mid-session.
  static Future<void> init(ProviderContainer container) async {
    final config = await checkForUpdate();
    container.read(updateConfigProvider.notifier).set(config);
  }
}
