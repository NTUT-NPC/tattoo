import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tattoo/components/notices.dart';
import 'package:tattoo/components/section_header.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/models/campus_wifi.dart';
import 'package:tattoo/repositories/campus_wifi_repository.dart';
import 'package:tattoo/utils/auto_spacing.dart';

final ntutWifiAssistantProvider =
    FutureProvider.autoDispose<Ntut8021xAssistantData>((ref) async {
      return ref
          .watch(campusWifiRepositoryProvider)
          .getNtut8021xAssistantData();
    });

class NtutWifiScreen extends ConsumerStatefulWidget {
  const NtutWifiScreen({super.key});

  @override
  ConsumerState<NtutWifiScreen> createState() => _NtutWifiScreenState();
}

class _NtutWifiScreenState extends ConsumerState<NtutWifiScreen> {
  bool _isProvisioning = false;
  bool _isSavingCompat = false;
  bool _isRemoving = false;
  Ntut8021xRemovalStatus? _lastRemovalStatus;

  bool get _isBusy => _isProvisioning || _isSavingCompat || _isRemoving;
  Ntut8021xProvisioningResult? _lastProvisioningResult;
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        setState(() => _lastProvisioningResult = null);
        ref.invalidate(ntutWifiAssistantProvider);
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  Future<void> _copyText(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) return;
      _showMessage(t.general.copied);
    } catch (_) {
      if (!mounted) return;
      _showMessage(t.ntutWifi.copyFailed);
    }
  }

  Future<void> _openWifiSettings() async {
    final opened = await ref
        .read(campusWifiRepositoryProvider)
        .openWifiSettings();
    if (!mounted || opened) return;
    _showMessage(t.ntutWifi.openSettingsFailed);
  }

  Future<void> _openWifiPanel() async {
    final opened = await ref.read(campusWifiRepositoryProvider).openWifiPanel();
    if (!mounted || opened) return;
    _showMessage(t.ntutWifi.openPanelFailed);
  }

  Future<void> _openWifiPermissionSettings() async {
    final opened = await ref
        .read(campusWifiRepositoryProvider)
        .openWifiPermissionSettings();
    if (!mounted || opened) return;
    _showMessage(t.ntutWifi.openSettingsFailed);
  }

  Future<void> _runProvisioning() async {
    if (_isBusy) return;
    setState(() {
      _isProvisioning = true;
      _lastRemovalStatus = null;
    });
    Ntut8021xProvisioningResult? result;
    try {
      result = await ref
          .read(campusWifiRepositoryProvider)
          .provisionNtut8021x();
    } catch (_) {
      result = null;
    } finally {
      if (mounted) {
        setState(() {
          _isProvisioning = false;
          _lastProvisioningResult = result;
        });
      }
    }
    if (!mounted) return;
    ref.invalidate(ntutWifiAssistantProvider);
    _showMessage(switch (result) {
      final result? => _provisioningSnackBarMessage(result),
      null => t.ntutWifi.provisioning.failed,
    });
  }

  Future<void> _saveNtut8021xToSystem() async {
    if (_isBusy) return;
    setState(() {
      _isSavingCompat = true;
      _lastRemovalStatus = null;
    });
    Ntut8021xProvisioningResult? result;
    try {
      result = await ref
          .read(campusWifiRepositoryProvider)
          .saveNtut8021xToSystem();
    } catch (_) {
      result = null;
    } finally {
      if (mounted) {
        setState(() {
          _isSavingCompat = false;
          _lastProvisioningResult = result;
        });
      }
    }
    if (!mounted) return;
    ref.invalidate(ntutWifiAssistantProvider);
    _showMessage(switch (result) {
      final result? => _provisioningSnackBarMessage(result),
      null => t.ntutWifi.provisioning.compatFailed,
    });
  }

  Future<void> _removeNtut8021x(CampusWifiCapabilities capabilities) async {
    if (_isBusy) return;
    setState(() => _isRemoving = true);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(t.ntutWifi.removal.title.spaced),
        content: Text(
          switch (capabilities.androidSdkInt) {
            final sdk? when sdk < 30 =>
              t.ntutWifi.removal.confirmation.android10,
            final _? => t.ntutWifi.removal.confirmation.android,
            null => t.ntutWifi.removal.confirmation.ios,
          }.spaced,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.general.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t.ntutWifi.removal.confirm.spaced),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmed != true) {
      setState(() => _isRemoving = false);
      return;
    }

    setState(() {
      _lastProvisioningResult = null;
      _lastRemovalStatus = null;
    });
    Ntut8021xRemovalStatus status;
    try {
      status = await ref.read(campusWifiRepositoryProvider).removeNtut8021x();
    } catch (_) {
      status = .failed;
    }
    if (!mounted) return;
    setState(() {
      _isRemoving = false;
      _lastRemovalStatus = status;
    });
    ref.invalidate(ntutWifiAssistantProvider);
    _showMessage(_removalSnackBarMessage(status));
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message.spaced)));
  }

  String _provisioningSnackBarMessage(Ntut8021xProvisioningResult result) {
    return switch (result.status) {
      .success => t.ntutWifi.provisioning.success,
      .configured => t.ntutWifi.ios.configured,
      .cancelled => t.ntutWifi.ios.cancelled,
      .alreadyAssociated => t.ntutWifi.ios.alreadyAssociated,
      .successPendingWifi => t.ntutWifi.provisioning.successPendingWifi,
      .approvalPending => t.ntutWifi.provisioning.approvalPending,
      .approvalRejected => t.ntutWifi.provisioning.approvalRejected,
      .validationUnavailable => t.ntutWifi.provisioning.validationUnavailable,
      .unsupportedPlatform => t.ntutWifi.provisioning.unsupportedPlatform,
      .failed => t.ntutWifi.provisioning.failed,
      .compatSuccess => t.ntutWifi.provisioning.compatSuccess,
      .compatAlreadyExists => t.ntutWifi.provisioning.compatAlreadyExists,
      .compatCancelled => t.ntutWifi.provisioning.compatCancelled,
      .compatFailed => t.ntutWifi.provisioning.compatFailed,
    };
  }

  @override
  Widget build(BuildContext context) {
    final assistantAsync = ref.watch(ntutWifiAssistantProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.ntutWifi.title)),
      body: SafeArea(
        child: switch (assistantAsync) {
          AsyncData(:final value) => _AssistantBody(
            data: value,
            isProvisioning: _isProvisioning,
            isSavingCompat: _isSavingCompat,
            isRemoving: _isRemoving,
            removalStatus: _lastRemovalStatus,
            onRemove: value.capabilities.canRemoveNtut8021x
                ? () => _removeNtut8021x(value.capabilities)
                : null,
            onProvision: value.canProvisionAutomatically
                ? _runProvisioning
                : null,
            onRetryCompat: value.canUseCompatMode
                ? _saveNtut8021xToSystem
                : null,
            onCopyIdentity: value.canCopyIdentity
                ? () => _copyText(value.identity!)
                : null,
            onCopyPassword: value.canCopyPassword
                ? () => _copyText(value.password!)
                : null,
            onOpenWifiSettings: value.capabilities.canOpenWifiSettings
                ? _openWifiSettings
                : null,
            onOpenWifiPanel: value.capabilities.canOpenWifiPanel
                ? _openWifiPanel
                : null,
            onOpenWifiPermissionSettings:
                value.capabilities.androidSdkInt != null &&
                    (value.capabilities.isSuggestionPermissionDisallowed ||
                        _lastProvisioningResult?.status == .approvalRejected)
                ? _openWifiPermissionSettings
                : null,
          ),
          AsyncError() => Center(
            child: Padding(
              padding: const .all(16),
              child: BackgroundNotice(
                text: t.errors.occurred,
                noticeType: .error,
              ),
            ),
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

String _removalMessage(Ntut8021xRemovalStatus status) {
  return switch (status) {
    .removed => t.ntutWifi.removal.removed,
    .removalRequested => t.ntutWifi.removal.requested,
    .manualRemovalRequired => t.ntutWifi.removal.manualRequired,
    .unsupportedPlatform => t.ntutWifi.removal.unsupported,
    .failed => t.ntutWifi.removal.failed,
  };
}

String _removalSnackBarMessage(Ntut8021xRemovalStatus status) {
  return switch (status) {
    .removed => t.ntutWifi.removal.snackbar.removed,
    .removalRequested => t.ntutWifi.removal.snackbar.requested,
    .manualRemovalRequired => t.ntutWifi.removal.snackbar.manualRequired,
    .unsupportedPlatform => t.ntutWifi.removal.snackbar.unsupported,
    .failed => t.ntutWifi.removal.snackbar.failed,
  };
}

class _AssistantBody extends StatelessWidget {
  const _AssistantBody({
    required this.data,
    required this.isProvisioning,
    required this.isSavingCompat,
    required this.isRemoving,
    this.removalStatus,
    this.onRemove,
    this.onProvision,
    this.onRetryCompat,
    this.onCopyIdentity,
    this.onCopyPassword,
    this.onOpenWifiSettings,
    this.onOpenWifiPanel,
    this.onOpenWifiPermissionSettings,
  });

  final Ntut8021xAssistantData data;
  final bool isProvisioning;
  final bool isSavingCompat;
  final bool isRemoving;
  final Ntut8021xRemovalStatus? removalStatus;
  final VoidCallback? onRemove;
  final VoidCallback? onProvision;
  final VoidCallback? onRetryCompat;
  final VoidCallback? onCopyIdentity;
  final VoidCallback? onCopyPassword;
  final VoidCallback? onOpenWifiSettings;
  final VoidCallback? onOpenWifiPanel;
  final VoidCallback? onOpenWifiPermissionSettings;

  @override
  Widget build(BuildContext context) {
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;
    final isBusy = isProvisioning || isSavingCompat || isRemoving;
    final notices = <Widget>[
      BackgroundNotice(
        text: _statusMessage(data, isIos: isIos).spaced,
        noticeType: _statusNoticeType(data.status),
      ),
      if (_modeNoticeMessage(data, isIos: isIos) case final message?)
        BackgroundNotice(
          text: message.spaced,
          noticeType: _modeNoticeType(data),
        ),
      if (removalStatus case final status?)
        BackgroundNotice(
          text: _removalMessage(status).spaced,
          noticeType: switch (status) {
            .failed || .unsupportedPlatform => .error,
            .manualRemovalRequired || .removalRequested => .warning,
            .removed => .info,
          },
        ),
      if (data.capabilities.androidSdkInt case final sdkInt?)
        Text(
          t.ntutWifi.androidVersion(sdkInt: sdkInt),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      if (data.capabilities.androidSdkInt case final sdk?
          when sdk >= 29 && sdk < 31)
        BackgroundNotice(
          text: t.ntutWifi.olderAndroidWarning.spaced,
          noticeType: .warning,
        ),
      if (data.status == .ready && data.screenMode != .manualOnly)
        BackgroundNotice(
          text:
              (isIos
                      ? t.ntutWifi.ios.certificatesHint
                      : t.ntutWifi.systemCertificatesHint)
                  .spaced,
          noticeType: .info,
        ),
      if (isIos && !data.capabilities.canProvisionAutomatically)
        BackgroundNotice(
          text: t.ntutWifi.ios.deviceRequired.spaced,
          noticeType: .warning,
        ),
    ];

    return ListView(
      padding: const .all(16),
      children: [
        Column(
          crossAxisAlignment: .start,
          spacing: 16,
          children: [
            ...notices,
            if (onOpenWifiPermissionSettings
                case final onOpenWifiPermissionSettings?)
              FilledButton.tonalIcon(
                onPressed: isBusy ? null : onOpenWifiPermissionSettings,
                icon: const Icon(Icons.settings),
                label: Text(
                  t.ntutWifi.actions.openWifiPermissionSettings.spaced,
                ),
              ),
            if (onProvision case final onProvision?)
              FilledButton.icon(
                onPressed: isBusy ? null : onProvision,
                icon: isProvisioning
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi),
                label: Text(
                  isProvisioning
                      ? t.ntutWifi.actions.autoProvisioning
                      : isIos
                      ? t.ntutWifi.ios.connect
                      : t.ntutWifi.actions.autoProvision,
                ),
              ),
            if (onRetryCompat case final onRetryCompat?)
              OutlinedButton.icon(
                onPressed: isBusy ? null : onRetryCompat,
                icon: isSavingCompat
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.system_update_alt),
                label: Text(
                  isSavingCompat
                      ? t.ntutWifi.actions.autoProvisioning
                      : data.pendingCompatPromptReason == .credentialChanged
                      ? t.ntutWifi.actions.updateCompatProvision
                      : t.ntutWifi.actions.retryCompatProvision,
                ),
              ),
            if (onRemove case final onRemove?)
              OutlinedButton.icon(
                onPressed: isBusy ? null : onRemove,
                icon: isRemoving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_off),
                label: Text(
                  (isRemoving
                          ? t.ntutWifi.removal.removing
                          : t.ntutWifi.removal.button)
                      .spaced,
                ),
              ),
            if (onOpenWifiSettings != null || onOpenWifiPanel != null) ...[
              SectionHeader(title: t.ntutWifi.sections.quickActions),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (onOpenWifiSettings case final onOpenWifiSettings?)
                    FilledButton.tonalIcon(
                      onPressed: onOpenWifiSettings,
                      icon: const Icon(Icons.wifi),
                      label: Text(t.ntutWifi.actions.openWifiSettings),
                    ),
                  if (onOpenWifiPanel case final onOpenWifiPanel?)
                    OutlinedButton.icon(
                      onPressed: onOpenWifiPanel,
                      icon: const Icon(Icons.tune),
                      label: Text(t.ntutWifi.actions.openWifiPanel),
                    ),
                ],
              ),
            ],
            SectionHeader(title: t.ntutWifi.sections.recommendedSettings),
            _SettingFieldTile(
              label: t.ntutWifi.fields.ssid,
              value: Ntut8021xAssistantData.ssid,
            ),
            _SettingFieldTile(
              label: t.ntutWifi.fields.eapMethod,
              value: Ntut8021xAssistantData.eapMethod,
            ),
            if (!isIos)
              _SettingFieldTile(
                label: t.ntutWifi.fields.phase2Auth,
                value: Ntut8021xAssistantData.phase2Authentication,
              ),
            _SettingFieldTile(
              label: t.ntutWifi.fields.identity,
              value: data.identity ?? t.general.notLoggedIn,
              onCopy: onCopyIdentity,
            ),
            _SettingFieldTile(
              label: t.ntutWifi.fields.password,
              value: data.canCopyPassword
                  ? t.ntutWifi.fieldValues.passwordSaved
                  : t.ntutWifi.fieldValues.passwordUnavailable,
              onCopy: onCopyPassword,
            ),
            _SettingFieldTile(
              label: t.ntutWifi.fields.caCertificate,
              value: t.ntutWifi.fieldValues.systemCertificates,
            ),
            _SettingFieldTile(
              label: t.ntutWifi.fields.domain,
              value: Ntut8021xAssistantData.domainSuffix,
            ),
            SectionHeader(title: t.ntutWifi.sections.fallback),
            Text(
              (isIos
                      ? t.ntutWifi.ios.openSettings
                      : t.ntutWifi.fallbackSteps.openSettings)
                  .spaced,
            ),
            Text(t.ntutWifi.fallbackSteps.selectNetwork),
            Text(
              (isIos
                      ? t.ntutWifi.ios.enterCredentials
                      : t.ntutWifi.fallbackSteps.useDisplayedValues)
                  .spaced,
            ),
          ],
        ),
      ],
    );
  }

  String _statusMessage(Ntut8021xAssistantData data, {required bool isIos}) {
    return switch (data.status) {
      .ready =>
        '${isIos ? t.ntutWifi.ios.intro : t.ntutWifi.intro}\n${t.ntutWifi.accountHint}',
      .notLoggedIn => t.ntutWifi.notLoggedIn,
      .credentialsMissing =>
        '${t.ntutWifi.credentialsMissing}\n${t.ntutWifi.accountHint}',
      .unsupportedPlatform => t.ntutWifi.unsupportedPlatform,
    };
  }

  NoticeType _statusNoticeType(Ntut8021xAssistantStatus status) {
    return switch (status) {
      .ready => .info,
      .notLoggedIn || .credentialsMissing => .warning,
      .unsupportedPlatform => .error,
    };
  }

  String? _modeNoticeMessage(
    Ntut8021xAssistantData data, {
    required bool isIos,
  }) {
    if (data.status != .ready) return null;

    if (data.capabilities.isLegacyAndroidManualOnly) {
      return t.ntutWifi.legacyManualOnly;
    }

    if (data.pendingCompatPromptReason == .credentialChanged) {
      return isIos
          ? t.ntutWifi.ios.updateRequired
          : t.ntutWifi.compatUpdateRequired;
    }

    if (data.screenMode == .permissionRequired) {
      return t.ntutWifi.provisioning.approvalRejected;
    }

    if (data.pendingCompatPromptReason == .suggestionFallbackRequired) {
      return t.ntutWifi.suggestionFallbackRequired;
    }

    if (data.lastProvisioningMode == .compat) {
      return t.ntutWifi.compatModeSavedHint;
    }

    return null;
  }

  NoticeType _modeNoticeType(Ntut8021xAssistantData data) {
    if (data.capabilities.isLegacyAndroidManualOnly ||
        data.screenMode == .permissionRequired) {
      return .warning;
    }

    if (data.pendingCompatPromptReason != null) {
      return .warning;
    }

    return .info;
  }
}

class _SettingFieldTile extends StatelessWidget {
  const _SettingFieldTile({
    required this.label,
    required this.value,
    this.onCopy,
  });

  final String label;
  final String value;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderRadius = BorderRadius.circular(14);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const .symmetric(horizontal: 12, vertical: 12),
        child: Row(
          crossAxisAlignment: .start,
          spacing: 12,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                spacing: 4,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(value, style: theme.textTheme.titleMedium),
                ],
              ),
            ),
            if (onCopy case final onCopy?)
              TextButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.content_copy),
                label: Text(t.general.copy),
              ),
          ],
        ),
      ),
    );
  }
}
