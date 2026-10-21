import 'package:material_ui/material_ui.dart';
import 'package:tattoo/components/feature_card.dart';
import 'package:tattoo/components/section_header.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/utils/auto_spacing.dart';

class NtutWifiManualGuide extends StatelessWidget {
  const NtutWifiManualGuide({
    super.key,
    required this.openSettingsDescription,
    required this.connectDescription,
    this.onCopyIdentity,
    this.onCopyPassword,
  });

  final String openSettingsDescription;
  final String connectDescription;
  final VoidCallback? onCopyIdentity;
  final VoidCallback? onCopyPassword;

  @override
  Widget build(BuildContext context) {
    final guide = t.ntutWifi.manualGuide;
    return Column(
      crossAxisAlignment: .stretch,
      spacing: 8,
      children: [
        Padding(
          padding: const .symmetric(horizontal: 24),
          child: SectionHeader(title: guide.title.spaced),
        ),
        FeatureCard(
          icon: Icons.wifi_find,
          title: guide.selectNetwork.spaced,
          description: openSettingsDescription.spaced,
        ),
        FeatureCard(
          icon: Icons.person_outline,
          title: guide.enterAccount.spaced,
          description: t.ntutWifi.accountHint.spaced,
        ),
        Wrap(
          alignment: .center,
          spacing: 8,
          runSpacing: 8,
          children: [
            if (onCopyIdentity case final onCopy?)
              TextButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.content_copy),
                label: Text(guide.copyIdentity.spaced),
              ),
            if (onCopyPassword case final onCopy?)
              TextButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.content_copy),
                label: Text(guide.copyPassword.spaced),
              ),
          ],
        ),
        FeatureCard(
          icon: Icons.verified_user_outlined,
          title: guide.connect.spaced,
          description: connectDescription.spaced,
        ),
      ],
    );
  }
}
