import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tattoo/components/option_entry_tile.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/preferences_repository.dart';
import 'package:tattoo/router/app_router.dart';
import 'package:tattoo/screens/main/profile/preference_providers.dart';
import 'package:tattoo/utils/auto_spacing.dart';

class PreferencesScreen extends ConsumerStatefulWidget {
  const PreferencesScreen({super.key});

  @override
  ConsumerState<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends ConsumerState<PreferencesScreen> {
  final _saving = <PrefKey<bool>>{};

  Future<void> _setPreference(PrefKey<bool> key, bool value) async {
    if (!_saving.add(key)) return;
    setState(() {});

    try {
      await ref.read(preferencesRepositoryProvider).set(key, value);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(t.preferences.saveFailed.spaced)),
        );
    } finally {
      if (mounted) setState(() => _saving.remove(key));
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(preferencesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.profile.options.preferences.spaced)),
      body: SafeArea(
        child: prefsAsync.when(
          skipLoadingOnReload: true,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisSize: .min,
              spacing: 8,
              children: [
                Text(t.preferences.loadFailed.spaced),
                TextButton(
                  onPressed: () => ref.invalidate(preferencesProvider),
                  child: Text(t.general.retry),
                ),
              ],
            ),
          ),
          data: (prefs) {
            final preferences = {for (final pref in prefs) pref.key: pref};

            Widget toggle(
              PrefKey<bool> key, {
              required IconData icon,
              required String title,
              String? description,
            }) {
              final pref = preferences[key];
              final value = pref?.value as bool? ?? key.defaultValue;
              final enabled =
                  pref != null && !pref.isForced && !_saving.contains(key);

              return OptionEntryTile.toggle(
                icon: icon,
                title: title.spaced,
                description:
                    (pref?.isForced == true
                            ? t.preferences.managed
                            : description)
                        ?.spaced,
                value: value,
                onChanged: enabled
                    ? (value) => _setPreference(key, value)
                    : null,
              );
            }

            final preferenceItems = <Widget>[
              toggle(
                PrefKey.startWithCourseTable,
                icon: Icons.dashboard_outlined,
                title: t.preferences.startWithCourseTable.title,
              ),
              toggle(
                PrefKey.darkMode,
                icon: Icons.dark_mode_outlined,
                title: t.preferences.darkMode,
              ),
              OptionEntryTile.icon(
                icon: Icons.language_outlined,
                title: t.preferences.language.title,
                onTap: () => context.push(AppRoutes.language),
              ),
            ];

            return ListView(
              padding: const .all(16),
              children: [
                Column(
                  spacing: 8,
                  crossAxisAlignment: .stretch,
                  children: preferenceItems,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
