import 'package:flutter/material.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/utils/auto_spacing.dart';
import 'package:tattoo/utils/launch_url.dart';

typedef ISchoolPlusNetworkGuideBackAction = ({
  String label,
  VoidCallback onPressed,
});

/// Explains the campus-network requirement shared by I-School Plus features.
class ISchoolPlusNetworkGuide extends StatelessWidget {
  const ISchoolPlusNetworkGuide({
    super.key,
    required this.guideUrl,
    this.onRetry,
    this.retryEnabled = true,
    this.retryInProgress = false,
    this.onBack,
  });

  final Uri guideUrl;
  final VoidCallback? onRetry;
  final bool retryEnabled;
  final bool retryInProgress;
  final ISchoolPlusNetworkGuideBackAction? onBack;

  Future<void> _openGuide(BuildContext context) async {
    try {
      await launchUrl(guideUrl);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(t.iSchoolPlus.network.openGuideFailed.spaced),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = Translations.of(context).iSchoolPlus.network;
    return Padding(
      padding: const .fromLTRB(16, 32, 16, 8),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        children: [
          Icon(
            Icons.vpn_lock_outlined,
            size: 64,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            strings.title.spaced,
            style: theme.textTheme.headlineSmall,
            textAlign: .center,
          ),
          const SizedBox(height: 12),
          Text(
            strings.description.spaced,
            style: theme.textTheme.bodyLarge,
            textAlign: .justify,
          ),
          if (retryInProgress) ...[
            const SizedBox(height: 12),
            Text(
              strings.stillTrying.spaced,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: .center,
            ),
          ],
          if (onBack case final onBack?) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onBack.onPressed,
              child: Text(onBack.label.spaced),
            ),
          ],
          const SizedBox(height: 24),
          if (onRetry case final onRetry?) ...[
            FilledButton.icon(
              onPressed: retryEnabled ? onRetry : null,
              icon: const Icon(Icons.refresh),
              label: Text(t.general.retry.spaced),
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton.icon(
            onPressed: () => _openGuide(context),
            icon: const Icon(Icons.open_in_new),
            label: Text(strings.openGuide.spaced),
          ),
        ],
      ),
    );
  }
}
