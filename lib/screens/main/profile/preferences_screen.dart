import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/components/option_entry_tile.dart';
import 'package:tattoo/components/section_header.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/preferences_repository.dart';
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

              return MergeSemantics(
                child: OptionEntryTile.icon(
                  icon: icon,
                  title: title.spaced,
                  description:
                      (pref?.isForced == true
                              ? t.preferences.managed
                              : description)
                          ?.spaced,
                  onTap: enabled ? () => _setPreference(key, !value) : null,
                  customActionIcon: Switch(
                    value: value,
                    onChanged: enabled
                        ? (value) => _setPreference(key, value)
                        : null,
                  ),
                ),
              );
            }

            return ListView(
              padding: const .all(16),
              children: [
                Column(
                  spacing: 8,
                  crossAxisAlignment: .stretch,
                  children: [
                    SectionHeader(title: t.preferences.sections.startup.spaced),
                    toggle(
                      PrefKey.startWithCourseTable,
                      icon: Icons.table_chart_outlined,
                      title: t.preferences.startWithCourseTable.title,
                      description:
                          t.preferences.startWithCourseTable.description,
                    ),
                    SectionHeader(title: t.preferences.sections.home.spaced),
                    toggle(
                      PrefKey.showCourseSchedule,
                      icon: Icons.view_carousel_outlined,
                      title: t.preferences.showCourseSchedule,
                    ),
                    toggle(
                      PrefKey.showScannerButton,
                      icon: Icons.qr_code_scanner,
                      title: t.preferences.showScannerButton,
                    ),
                    toggle(
                      PrefKey.showPortalButton,
                      icon: Icons.apps,
                      title: t.preferences.showPortalButton,
                    ),
                    toggle(
                      PrefKey.showCalendarButton,
                      icon: Icons.calendar_month_outlined,
                      title: t.preferences.showCalendarButton,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
