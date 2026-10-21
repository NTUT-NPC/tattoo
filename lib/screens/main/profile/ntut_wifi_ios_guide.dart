import 'package:material_ui/material_ui.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/screens/main/profile/ntut_wifi_manual_guide.dart';

class NtutWifiIosGuide extends StatelessWidget {
  const NtutWifiIosGuide({
    super.key,
    this.onCopyIdentity,
    this.onCopyPassword,
  });

  final VoidCallback? onCopyIdentity;
  final VoidCallback? onCopyPassword;

  @override
  Widget build(BuildContext context) {
    final guide = t.ntutWifi.manualGuide;
    return NtutWifiManualGuide(
      openSettingsDescription: guide.openIos,
      connectDescription: guide.trustIos,
      onCopyIdentity: onCopyIdentity,
      onCopyPassword: onCopyPassword,
    );
  }
}
