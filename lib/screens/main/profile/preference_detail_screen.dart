import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/components/option_entry_tile.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/screens/main/profile/preference_definitions.dart';
import 'package:tattoo/screens/main/profile/preference_providers.dart';
import 'package:tattoo/utils/auto_spacing.dart';

class PreferenceDetailScreen extends ConsumerWidget {
  const PreferenceDetailScreen({super.key, required this.id});

  final PreferenceDetailId id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = Translations.of(context);
    final definition = preferenceDetailDefinition(id, strings);
    final provider = preferenceDetailProvider(id);
    final notifier = ref.read(provider.notifier);

    ref.listen<AsyncValue<PreferenceDetailState>>(provider, (_, next) {
      final error = next.value?.error;
      if (error == null) return;

      final message = switch (error) {
        PreferenceDetailError.save => definition.saveError,
        PreferenceDetailError.action =>
          definition.actionError ?? definition.saveError,
      };
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message.spaced)));
      notifier.clearError();
    });

    return Scaffold(
      appBar: AppBar(title: Text(definition.title.spaced)),
      body: SafeArea(
        child: ref
            .watch(provider)
            .when(
              loading: () => const _LoadingContent(),
              error: (_, _) => _ErrorContent(
                message: definition.loadError,
                onRetry: notifier.retry,
              ),
              data: (state) => switch (state.mode) {
                PreferenceDetailMode.selection => _SelectionContent(
                  options: definition.options,
                  selectedValue: state.value,
                  enabled: state.enabled && !state.isSaving,
                  onSelected: notifier.select,
                ),
                PreferenceDetailMode.guide => _GuideContent(
                  guide: definition.guide!,
                  enabled: state.enabled && !state.isSaving,
                  onPressed: notifier.openSystemSettings,
                ),
                PreferenceDetailMode.unsupported => _UnsupportedContent(
                  message: definition.loadError,
                ),
              },
            ),
      ),
    );
  }
}

class _LoadingContent extends StatelessWidget {
  const _LoadingContent();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ErrorContent extends StatelessWidget {
  const _ErrorContent({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: .min,
        spacing: 8,
        children: [
          Text(message.spaced),
          TextButton(
            onPressed: onRetry,
            child: Text(t.general.retry.spaced),
          ),
        ],
      ),
    );
  }
}

class _UnsupportedContent extends StatelessWidget {
  const _UnsupportedContent({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message.spaced));
  }
}

class _SelectionContent extends StatelessWidget {
  const _SelectionContent({
    required this.options,
    required this.selectedValue,
    required this.enabled,
    required this.onSelected,
  });

  final List<PreferenceDetailOption> options;
  final String selectedValue;
  final bool enabled;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const .all(16),
      children: [
        Column(
          spacing: 8,
          crossAxisAlignment: .stretch,
          children: [
            for (final option in options)
              OptionEntryTile.icon(
                icon: option.icon,
                title: option.title.spaced,
                onTap: enabled && option.value != selectedValue
                    ? () => onSelected(option.value)
                    : null,
                customActionIcon: option.value == selectedValue
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : const SizedBox.shrink(),
              ),
          ],
        ),
      ],
    );
  }
}

class _GuideContent extends StatelessWidget {
  const _GuideContent({
    required this.guide,
    required this.enabled,
    required this.onPressed,
  });

  final PreferenceDetailGuide guide;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const .all(16),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: .min,
                  children: [
                    Icon(
                      guide.icon,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      guide.title.spaced,
                      style: theme.textTheme.headlineSmall,
                      textAlign: .center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      guide.description.spaced,
                      style: theme.textTheme.bodyLarge,
                      textAlign: .center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: enabled ? onPressed : null,
            icon: const Icon(Icons.open_in_new),
            label: Text(guide.buttonLabel.spaced),
          ),
        ],
      ),
    );
  }
}
