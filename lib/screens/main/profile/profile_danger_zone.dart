import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/components/option_entry_tile.dart';
import 'package:tattoo/components/section_header.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/preferences_repository.dart';
import 'package:tattoo/screens/main/profile/profile_providers.dart';

class ProfileDangerZone extends ConsumerWidget {
  const ProfileDangerZone({super.key});

  static const Color dangerColor = Colors.red;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesRepositoryProvider);

    return FutureBuilder<bool>(
      future: prefs.get(PrefKey.showDangerZone),
      builder: (context, snapshot) {
        if (!(snapshot.data ?? false)) return const SizedBox.shrink();

        final action = ref.watch(dangerZoneActionProvider);

        return Column(
          spacing: 8,
          children: [
            SectionHeader(
              title: t.profile.sections.dangerZone,
              color: dangerColor,
            ),
            OptionEntryTile.icon(
              icon: Icons.sports_bar_outlined,
              title: t.profile.dangerZone.goAction(action: action),
              color: dangerColor,
              borderColor: dangerColor,
              onTap: () {
                if (action == t.profile.dangerZone.actions.last) {
                  SystemNavigator.pop();
                } else {
                  throw Exception(t.profile.dangerZone.fireMessage);
                }
              },
            ),
            OptionEntryTile.icon(
              icon: Icons.bug_report_outlined,
              title: t.profile.dangerZone.nonFlutterCrash,
              color: dangerColor,
              borderColor: dangerColor,
              onTap: () {
                Future.delayed(Duration.zero, () {
                  throw Exception(
                    t.profile.dangerZone.nonFlutterCrashException,
                  );
                });
              },
            ),
          ],
        );
      },
    );
  }
}
