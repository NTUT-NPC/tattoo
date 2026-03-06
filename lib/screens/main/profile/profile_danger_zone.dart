import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tattoo/components/option_entry_tile.dart';
import 'package:tattoo/components/section_header.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/preferences_repository.dart';
import 'package:tattoo/screens/main/profile/profile_providers.dart';
import 'package:tattoo/utils/http.dart';
import 'package:tattoo/utils/shared_preferences.dart';

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
            OptionEntryTile.icon(
              icon: Icons.cached_outlined,
              title: t.profile.dangerZone.clearCache,
              color: dangerColor,
              borderColor: dangerColor,
              onTap: () =>
                  _clear(context, t.profile.dangerZone.items.cache, () async {
                    final cacheDir = await getApplicationCacheDirectory();
                    if (await cacheDir.exists()) {
                      await cacheDir.delete(recursive: true);
                    }
                  }),
            ),
            OptionEntryTile.icon(
              icon: Icons.cookie_outlined,
              title: t.profile.dangerZone.clearCookies,
              color: dangerColor,
              borderColor: dangerColor,
              onTap: () =>
                  _clear(context, t.profile.dangerZone.items.cookies, () async {
                    await cookieJar.deleteAll();
                  }),
            ),
            OptionEntryTile.icon(
              icon: Icons.settings_backup_restore_outlined,
              title: t.profile.dangerZone.clearPreferences,
              color: dangerColor,
              borderColor: dangerColor,
              onTap: () => _clear(
                context,
                t.profile.dangerZone.items.preferences,
                () async {
                  await ref.read(sharedPreferencesProvider).clear();
                },
              ),
            ),
            OptionEntryTile.icon(
              icon: Icons.delete_forever_outlined,
              title: t.profile.dangerZone.clearUserData,
              color: dangerColor,
              borderColor: dangerColor,
              onTap: () => _clear(
                context,
                t.profile.dangerZone.items.userData,
                () async {
                  await ref.read(databaseProvider).deleteEverything();
                  await cookieJar.deleteAll();
                  await const FlutterSecureStorage().deleteAll();
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clear(
    BuildContext context,
    String item,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.profile.dangerZone.clearFailed(item: item))),
        );
      }
      return;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.profile.dangerZone.cleared(item: item))),
      );
    }
  }
}
