import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tattoo/components/option_entry_tile.dart';
import 'package:tattoo/components/section_header.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/repositories/preferences_repository.dart';
import 'package:tattoo/router/app_router.dart';
import 'package:tattoo/screens/main/course_table/course_table_providers.dart';
import 'package:tattoo/screens/main/profile/profile_providers.dart';
import 'package:tattoo/screens/main/user_providers.dart';
import 'package:tattoo/utils/http.dart';
import 'package:tattoo/utils/shared_preferences.dart';

class ProfileDangerZone extends ConsumerWidget {
  const ProfileDangerZone({super.key});

  static const Color dangerColor = Colors.red;

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
      rethrow;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.profile.dangerZone.cleared(item: item))),
      );
    }
  }

  void _goAction(String action) {
    if (action == t.profile.dangerZone.actions.last) {
      SystemNavigator.pop();
    } else {
      throw Exception(t.profile.dangerZone.fireMessage);
    }
  }

  void _triggerNonFlutterCrash() {
    Future.delayed(Duration.zero, () {
      throw Exception(t.profile.dangerZone.nonFlutterCrashException);
    });
  }

  Future<void> _clearCache(BuildContext context, WidgetRef ref) => _clear(
    context,
    t.profile.dangerZone.items.cache,
    () async {
      final cacheDir = await getApplicationCacheDirectory();
      if (await cacheDir.exists()) {
        await for (final entity in cacheDir.list()) {
          await entity.delete(recursive: true);
        }
      }
      await ref.read(databaseProvider).deleteCachedData();
      ref.invalidate(userProfileProvider);
      ref.invalidate(userAvatarProvider);
      ref.invalidate(activeRegistrationProvider);
      ref.invalidate(courseTableSemestersProvider);
      ref.invalidate(courseTableProvider);
    },
  );

  Future<void> _clearCookies(BuildContext context) => _clear(
    context,
    t.profile.dangerZone.items.cookies,
    () async {
      await cookieJar.deleteAll();
    },
  );

  Future<void> _clearPreferences(BuildContext context, WidgetRef ref) => _clear(
    context,
    t.profile.dangerZone.items.preferences,
    () async {
      await ref.read(sharedPreferencesProvider).clear();
    },
  );

  Future<void> _clearCredentials(BuildContext context) => _clear(
    context,
    t.profile.dangerZone.items.credentials,
    () => const FlutterSecureStorage().deleteAll(),
  );

  Future<void> _clearUserData(BuildContext context, WidgetRef ref) => _clear(
    context,
    t.profile.dangerZone.items.userData,
    () async {
      await ref.read(databaseProvider).deleteEverything();
      await cookieJar.deleteAll();
      await const FlutterSecureStorage().deleteAll();
      ref.read(sessionProvider.notifier).destroy();
    },
  );

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
              icon: Icons.flag_outlined,
              title: t.profile.dangerZone.featureFlags,
              color: dangerColor,
              borderColor: dangerColor,
              onTap: () => context.push(AppRoutes.featureFlags),
            ),
            OptionEntryTile.icon(
              icon: Icons.sports_bar_outlined,
              title: t.profile.dangerZone.goAction(action: action),
              color: dangerColor,
              borderColor: dangerColor,
              onTap: () => _goAction(action),
            ),
            OptionEntryTile.icon(
              icon: Icons.bug_report_outlined,
              title: t.profile.dangerZone.nonFlutterCrash,
              color: dangerColor,
              borderColor: dangerColor,
              onTap: _triggerNonFlutterCrash,
            ),
            OptionEntryTile.icon(
              icon: Icons.cached_outlined,
              title: t.profile.dangerZone.clearCache,
              color: dangerColor,
              borderColor: dangerColor,
              onTap: () => _clearCache(context, ref),
            ),
            OptionEntryTile.icon(
              icon: Icons.cookie_outlined,
              title: t.profile.dangerZone.clearCookies,
              color: dangerColor,
              borderColor: dangerColor,
              onTap: () => _clearCookies(context),
            ),
            OptionEntryTile.icon(
              icon: Icons.settings_backup_restore_outlined,
              title: t.profile.dangerZone.clearPreferences,
              color: dangerColor,
              borderColor: dangerColor,
              onTap: () => _clearPreferences(context, ref),
            ),
            OptionEntryTile.icon(
              icon: Icons.key_off_outlined,
              title: t.profile.dangerZone.clearCredentials,
              color: dangerColor,
              borderColor: dangerColor,
              onTap: () => _clearCredentials(context),
            ),
            OptionEntryTile.icon(
              icon: Icons.delete_forever_outlined,
              title: t.profile.dangerZone.clearUserData,
              color: dangerColor,
              borderColor: dangerColor,
              onTap: () => _clearUserData(context, ref),
            ),
          ],
        );
      },
    );
  }
}
