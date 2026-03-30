import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tattoo/components/option_entry_tile.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/router/app_router.dart';

class NtutWifiEntryTile extends StatelessWidget {
  const NtutWifiEntryTile({super.key});

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).platform != TargetPlatform.android) {
      return const SizedBox.shrink();
    }

    return OptionEntryTile.icon(
      icon: Icons.wifi,
      title: t.profile.options.ntutWifi,
      description: t.ntutWifi.entryDescription,
      onTap: () => context.push(AppRoutes.ntutWifi),
    );
  }
}
