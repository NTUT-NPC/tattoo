import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/components/notices.dart';
import 'package:tattoo/components/section_header.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/campus_wifi_repository.dart';
import 'package:tattoo/screens/main/profile/ntut_wifi_providers.dart';

class NtutWifiScreen extends ConsumerStatefulWidget {
  const NtutWifiScreen({super.key});

  @override
  ConsumerState<NtutWifiScreen> createState() => _NtutWifiScreenState();
}

class _NtutWifiScreenState extends ConsumerState<NtutWifiScreen> {
  bool _isProvisioning = false;
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

  Future<void> _provisionNtut8021x() async {
    setState(() => _isProvisioning = true);

    final result = await ref
        .read(campusWifiRepositoryProvider)
        .provisionNtut8021x();
    if (!mounted) return;

    setState(() {
      _isProvisioning = false;
      _lastProvisioningResult = result;
    });

    _showMessage(_provisioningSnackBarMessage(result));
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
        context,
      )
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
            onProvision: value.canProvisionAutomatically
                ? _provisionNtut8021x
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
    this.provisioningResult,
    this.onProvision,
    this.onCopyIdentity,
    this.onCopyPassword,
    this.onOpenWifiSettings,
    this.onOpenWifiPanel,
  });

  final Ntut8021xAssistantData data;
  final Ntut8021xProvisioningResult? provisioningResult;
  final bool isProvisioning;
  final VoidCallback? onProvision;
  final VoidCallback? onCopyIdentity;
  final VoidCallback? onCopyPassword;
  final VoidCallback? onOpenWifiSettings;
  final VoidCallback? onOpenWifiPanel;

  @override
  Widget build(BuildContext context) {
    final androidSdkInt = data.capabilities.androidSdkInt;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            BackgroundNotice(
              text: _statusMessage(data),
              noticeType: _statusNoticeType(data.status),
            ),
            if (provisioningResult case final provisioningResult?)
              BackgroundNotice(
                text: _provisioningMessage(provisioningResult),
                noticeType: _provisioningNoticeType(provisioningResult.status),
              ),
            if (androidSdkInt case final sdkInt?)
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
            if (data.status == Ntut8021xAssistantStatus.ready)
              BackgroundNotice(
                text: t.ntutWifi.systemCertificatesHint,
                noticeType: NoticeType.info,
              ),
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
              )
            else if (data.status == Ntut8021xAssistantStatus.ready)
              BackgroundNotice(
                text: t.ntutWifi.automaticProvisionUnavailable,
                noticeType: NoticeType.warning,
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
    };
  }

  NoticeType _provisioningNoticeType(Ntut8021xProvisioningStatus status) {
    return switch (status) {
      Ntut8021xProvisioningStatus.success ||
      Ntut8021xProvisioningStatus.successPendingWifi => NoticeType.info,
      Ntut8021xProvisioningStatus.approvalPending ||
      Ntut8021xProvisioningStatus.approvalRejected ||
      Ntut8021xProvisioningStatus.validationUnavailable => NoticeType.warning,
      Ntut8021xProvisioningStatus.unsupportedPlatform ||
      Ntut8021xProvisioningStatus.failed => NoticeType.error,
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
