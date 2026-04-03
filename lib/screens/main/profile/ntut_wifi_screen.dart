import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/components/notices.dart';
import 'package:tattoo/components/section_header.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/campus_wifi_repository.dart';

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
  Ntut8021xProvisioningResult? _lastProvisioningResult;

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

  Future<void> _runProvisioning() async {
    setState(() => _isProvisioning = true);
    final result = await ref
        .read(campusWifiRepositoryProvider)
        .provisionNtut8021x();
    if (!mounted) return;

    setState(() {
      _isProvisioning = false;
      _lastProvisioningResult = result;
    });
    ref.invalidate(ntutWifiAssistantProvider);
    _showMessage(_provisioningSnackBarMessage(result));
  }

  Future<void> _saveNtut8021xToSystem() async {
    setState(() => _isSavingCompat = true);
    final result = await ref
        .read(campusWifiRepositoryProvider)
        .saveNtut8021xToSystem();
    if (!mounted) return;

    setState(() {
      _isSavingCompat = false;
      _lastProvisioningResult = result;
    });
    ref.invalidate(ntutWifiAssistantProvider);
    _showMessage(_provisioningSnackBarMessage(result));
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _provisioningSnackBarMessage(Ntut8021xProvisioningResult result) {
    return switch (result.status) {
      Ntut8021xProvisioningStatus.success => t.ntutWifi.provisioning.success,
      Ntut8021xProvisioningStatus.successPendingWifi =>
        t.ntutWifi.provisioning.successPendingWifi,
      Ntut8021xProvisioningStatus.approvalPending =>
        t.ntutWifi.provisioning.approvalPending,
      Ntut8021xProvisioningStatus.approvalRejected =>
        t.ntutWifi.provisioning.approvalRejected,
      Ntut8021xProvisioningStatus.validationUnavailable =>
        t.ntutWifi.provisioning.validationUnavailable,
      Ntut8021xProvisioningStatus.unsupportedPlatform =>
        t.ntutWifi.provisioning.unsupportedPlatform,
      Ntut8021xProvisioningStatus.failed => t.ntutWifi.provisioning.failed,
      Ntut8021xProvisioningStatus.compatSuccess =>
        result.usedCompatFallback
            ? t.ntutWifi.provisioning.compatFallbackSuccess
            : t.ntutWifi.provisioning.compatSuccess,
      Ntut8021xProvisioningStatus.compatAlreadyExists =>
        t.ntutWifi.provisioning.compatAlreadyExists,
      Ntut8021xProvisioningStatus.compatCancelled =>
        t.ntutWifi.provisioning.compatCancelled,
      Ntut8021xProvisioningStatus.compatFailed =>
        t.ntutWifi.provisioning.compatFailed,
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
            provisioningResult: _lastProvisioningResult,
            isProvisioning: _isProvisioning,
            isSavingCompat: _isSavingCompat,
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
          ),
          AsyncError() => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: BackgroundNotice(
                text: t.errors.occurred,
                noticeType: NoticeType.error,
              ),
            ),
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _AssistantBody extends StatelessWidget {
  const _AssistantBody({
    required this.data,
    required this.isProvisioning,
    required this.isSavingCompat,
    this.provisioningResult,
    this.onProvision,
    this.onRetryCompat,
    this.onCopyIdentity,
    this.onCopyPassword,
    this.onOpenWifiSettings,
    this.onOpenWifiPanel,
  });

  final Ntut8021xAssistantData data;
  final Ntut8021xProvisioningResult? provisioningResult;
  final bool isProvisioning;
  final bool isSavingCompat;
  final VoidCallback? onProvision;
  final VoidCallback? onRetryCompat;
  final VoidCallback? onCopyIdentity;
  final VoidCallback? onCopyPassword;
  final VoidCallback? onOpenWifiSettings;
  final VoidCallback? onOpenWifiPanel;

  @override
  Widget build(BuildContext context) {
    final notices = <Widget>[
      BackgroundNotice(
        text: _statusMessage(data),
        noticeType: _statusNoticeType(data.status),
      ),
      if (_modeNoticeMessage(data) case final message?)
        BackgroundNotice(
          text: message,
          noticeType: _modeNoticeType(data),
        ),
      if (provisioningResult case final provisioningResult?)
        BackgroundNotice(
          text: _provisioningMessage(provisioningResult),
          noticeType: _provisioningNoticeType(provisioningResult.status),
        ),
      if (data.capabilities.androidSdkInt case final sdkInt?)
        Text(
          t.ntutWifi.androidVersion(sdkInt: sdkInt),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      if (data.capabilities.isSupported &&
          !data.capabilities.isAndroid12OrNewer)
        BackgroundNotice(
          text: t.ntutWifi.olderAndroidWarning,
          noticeType: NoticeType.warning,
        ),
      if (data.status == Ntut8021xAssistantStatus.ready &&
          data.screenMode != Ntut8021xScreenMode.manualOnly)
        BackgroundNotice(
          text: t.ntutWifi.systemCertificatesHint,
          noticeType: NoticeType.info,
        ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            ...notices,
            if (onProvision case final onProvision?)
              FilledButton.icon(
                onPressed: isProvisioning ? null : onProvision,
                icon: isProvisioning
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_protected_setup),
                label: Text(
                  isProvisioning
                      ? t.ntutWifi.actions.autoProvisioning
                      : t.ntutWifi.actions.autoProvision,
                ),
              ),
            if (onRetryCompat case final onRetryCompat?)
              OutlinedButton.icon(
                onPressed: isSavingCompat ? null : onRetryCompat,
                icon: isSavingCompat
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.system_update_alt),
                label: Text(
                  isSavingCompat
                      ? t.ntutWifi.actions.autoProvisioning
                      : data.pendingCompatPromptReason ==
                            Ntut8021xPendingPromptReason.credentialChanged
                      ? t.ntutWifi.actions.updateCompatProvision
                      : t.ntutWifi.actions.retryCompatProvision,
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
            Text(t.ntutWifi.fallbackSteps.openSettings),
            Text(t.ntutWifi.fallbackSteps.selectNetwork),
            Text(t.ntutWifi.fallbackSteps.useDisplayedValues),
          ],
        ),
      ],
    );
  }

  String _statusMessage(Ntut8021xAssistantData data) {
    return switch (data.status) {
      Ntut8021xAssistantStatus.ready =>
        '${t.ntutWifi.intro}\n${t.ntutWifi.accountHint}',
      Ntut8021xAssistantStatus.notLoggedIn => t.ntutWifi.notLoggedIn,
      Ntut8021xAssistantStatus.credentialsMissing =>
        '${t.ntutWifi.credentialsMissing}\n${t.ntutWifi.accountHint}',
      Ntut8021xAssistantStatus.unsupportedPlatform =>
        t.ntutWifi.unsupportedPlatform,
    };
  }

  NoticeType _statusNoticeType(Ntut8021xAssistantStatus status) {
    return switch (status) {
      Ntut8021xAssistantStatus.ready => NoticeType.info,
      Ntut8021xAssistantStatus.notLoggedIn ||
      Ntut8021xAssistantStatus.credentialsMissing => NoticeType.warning,
      Ntut8021xAssistantStatus.unsupportedPlatform => NoticeType.error,
    };
  }

  String? _modeNoticeMessage(Ntut8021xAssistantData data) {
    if (data.status != Ntut8021xAssistantStatus.ready) return null;

    if (data.capabilities.isLegacyAndroidManualOnly) {
      return t.ntutWifi.legacyManualOnly;
    }

    if (data.capabilities.isAndroid10 &&
        data.capabilities.isSuggestionPermissionDisallowed) {
      return t.ntutWifi.android10PermissionRejected;
    }

    if (data.pendingCompatPromptReason ==
        Ntut8021xPendingPromptReason.credentialChanged) {
      return t.ntutWifi.compatUpdateRequired;
    }

    if (data.pendingCompatPromptReason ==
        Ntut8021xPendingPromptReason.suggestionFallbackRequired) {
      return t.ntutWifi.suggestionFallbackRequired;
    }

    if (data.lastProvisioningMode == Ntut8021xProvisioningMode.compat) {
      return t.ntutWifi.compatModeSavedHint;
    }

    return null;
  }

  NoticeType _modeNoticeType(Ntut8021xAssistantData data) {
    if (data.capabilities.isLegacyAndroidManualOnly ||
        (data.capabilities.isAndroid10 &&
            data.capabilities.isSuggestionPermissionDisallowed)) {
      return NoticeType.warning;
    }

    if (data.pendingCompatPromptReason != null) {
      return NoticeType.warning;
    }

    return NoticeType.info;
  }

  String _provisioningMessage(Ntut8021xProvisioningResult result) {
    return switch (result.status) {
      Ntut8021xProvisioningStatus.success => t.ntutWifi.provisioning.success,
      Ntut8021xProvisioningStatus.successPendingWifi =>
        t.ntutWifi.provisioning.successPendingWifi,
      Ntut8021xProvisioningStatus.approvalPending =>
        t.ntutWifi.provisioning.approvalPending,
      Ntut8021xProvisioningStatus.approvalRejected =>
        t.ntutWifi.provisioning.approvalRejected,
      Ntut8021xProvisioningStatus.validationUnavailable =>
        t.ntutWifi.provisioning.validationUnavailable,
      Ntut8021xProvisioningStatus.unsupportedPlatform =>
        t.ntutWifi.provisioning.unsupportedPlatform,
      Ntut8021xProvisioningStatus.failed => t.ntutWifi.provisioning.failed,
      Ntut8021xProvisioningStatus.compatSuccess =>
        result.usedCompatFallback
            ? t.ntutWifi.provisioning.compatFallbackSuccess
            : t.ntutWifi.provisioning.compatSuccess,
      Ntut8021xProvisioningStatus.compatAlreadyExists =>
        t.ntutWifi.provisioning.compatAlreadyExists,
      Ntut8021xProvisioningStatus.compatCancelled =>
        t.ntutWifi.provisioning.compatCancelled,
      Ntut8021xProvisioningStatus.compatFailed =>
        t.ntutWifi.provisioning.compatFailed,
    };
  }

  NoticeType _provisioningNoticeType(Ntut8021xProvisioningStatus status) {
    return switch (status) {
      Ntut8021xProvisioningStatus.success ||
      Ntut8021xProvisioningStatus.successPendingWifi ||
      Ntut8021xProvisioningStatus.compatSuccess => NoticeType.info,
      Ntut8021xProvisioningStatus.approvalPending ||
      Ntut8021xProvisioningStatus.approvalRejected ||
      Ntut8021xProvisioningStatus.validationUnavailable ||
      Ntut8021xProvisioningStatus.compatAlreadyExists ||
      Ntut8021xProvisioningStatus.compatCancelled => NoticeType.warning,
      Ntut8021xProvisioningStatus.unsupportedPlatform ||
      Ntut8021xProvisioningStatus.failed ||
      Ntut8021xProvisioningStatus.compatFailed => NoticeType.error,
    };
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
