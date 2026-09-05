import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tattoo/components/option_entry_tile.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/services/system_settings.dart';
import 'package:tattoo/utils/auto_spacing.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  AppLanguageSettings? _settings;
  Object? _loadError;
  var _saving = false;
  var _openingSettings = false;

  @override
  void initState() {
    super.initState();
    if (defaultTargetPlatform == TargetPlatform.android) {
      _loadAndroidLanguage();
    }
  }

  Future<void> _loadAndroidLanguage() async {
    try {
      final settings = await SystemSettings.getAppLanguage();
      if (mounted) setState(() => _settings = settings);
    } catch (error) {
      if (mounted) setState(() => _loadError = error);
    }
  }

  Future<void> _setAndroidLanguage(String? languageTag) async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final settings = await SystemSettings.setAppLanguage(languageTag);
      if (languageTag == null) {
        await LocaleSettings.useDeviceLocale();
      } else {
        await LocaleSettings.setLocaleRaw(
          languageTag,
          listenToDeviceLocale: settings.isSystemManaged,
        );
      }
      if (mounted) setState(() => _settings = settings);
    } catch (_) {
      if (!mounted) return;
      _showError(t.preferences.language.changeFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openLanguageSettings() async {
    if (_openingSettings) return;
    setState(() => _openingSettings = true);

    try {
      await SystemSettings.openLanguageSettings();
    } catch (_) {
      if (!mounted) return;
      _showError(t.preferences.language.openFailed);
    } finally {
      if (mounted) setState(() => _openingSettings = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message.spaced)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t.preferences.language.title)),
      body: SafeArea(
        child: switch (defaultTargetPlatform) {
          TargetPlatform.android => _buildAndroid(),
          TargetPlatform.iOS => _buildIos(),
          _ => _buildUnsupported(),
        },
      ),
    );
  }

  Widget _buildAndroid() {
    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: .min,
          spacing: 8,
          children: [
            Text(t.preferences.language.changeFailed.spaced),
            TextButton(
              onPressed: () {
                setState(() => _loadError = null);
                _loadAndroidLanguage();
              },
              child: Text(t.general.retry),
            ),
          ],
        ),
      );
    }
    if (_settings == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final selectedTag = _settings!.languageTag;
    return ListView(
      padding: const .all(16),
      children: [
        Column(
          spacing: 8,
          crossAxisAlignment: .stretch,
          children: [
            _languageOption(
              languageTag: null,
              title: t.preferences.language.followSystem,
              selected: selectedTag == null,
            ),
            _languageOption(
              languageTag: 'zh-TW',
              title: t.preferences.language.traditionalChinese,
              selected: selectedTag?.startsWith('zh') == true,
            ),
            _languageOption(
              languageTag: 'en-US',
              title: t.preferences.language.english,
              selected: selectedTag?.startsWith('en') == true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _languageOption({
    required String? languageTag,
    required String title,
    required bool selected,
  }) {
    return OptionEntryTile.icon(
      icon: Icons.translate,
      title: title.spaced,
      onTap: _saving || selected
          ? null
          : () => _setAndroidLanguage(languageTag),
      customActionIcon: selected
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : const SizedBox.shrink(),
    );
  }

  Widget _buildIos() {
    return Padding(
      padding: const .all(16),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: .center,
              children: [
                Icon(
                  Icons.language_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  t.preferences.language.iosGuideTitle.spaced,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: .center,
                ),
                const SizedBox(height: 12),
                Text(
                  t.preferences.language.iosGuideDescription.spaced,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: .center,
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: _openingSettings ? null : _openLanguageSettings,
            icon: const Icon(Icons.open_in_new),
            label: Text(t.preferences.language.openSettings.spaced),
          ),
        ],
      ),
    );
  }

  Widget _buildUnsupported() {
    return Center(child: Text(t.preferences.language.changeFailed.spaced));
  }
}
