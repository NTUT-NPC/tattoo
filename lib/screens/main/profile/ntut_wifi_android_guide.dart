import 'package:material_ui/material_ui.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/screens/main/profile/ntut_wifi_manual_guide.dart';

class NtutWifiAndroidGuide extends StatelessWidget {
  const NtutWifiAndroidGuide({
    super.key,
    required this.androidSdkInt,
    this.onCopyIdentity,
    this.onCopyPassword,
  });

  final int? androidSdkInt;
  final VoidCallback? onCopyIdentity;
  final VoidCallback? onCopyPassword;

  @override
  Widget build(BuildContext context) {
    final guide = t.ntutWifi.manualGuide;
    return NtutWifiManualGuide(
      openSettingsDescription: guide.openAndroid,
      connectDescription: switch (androidSdkInt) {
        final sdk? when sdk < 31 => guide.configureOlderAndroid,
        _ => guide.configureAndroid,
      },
      onCopyIdentity: onCopyIdentity,
      onCopyPassword: onCopyPassword,
    );
  }
}
