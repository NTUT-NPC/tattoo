import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/preferences_repository.dart';
import 'package:tattoo/screens/main/profile/preference_providers.dart';

/// A screen that displays all preferences and their resolved source, allowing
/// users (typically developers or testers) to view and override values.
class FeatureFlagScreen extends ConsumerWidget {
  const FeatureFlagScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(preferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.featureFlags.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_download),
            tooltip: t.featureFlags.fetchFlags,
            onPressed: () async {
              await ref.read(preferencesRepositoryProvider).refresh();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t.featureFlags.refreshed)),
                );
              }
            },
          ),
        ],
      ),
      body: prefsAsync.when(
        data: (prefs) => prefs.isEmpty
            ? Center(child: Text(t.featureFlags.noFlag))
            : _PrefList(prefs: prefs),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(t.errors.occurred)),
      ),
    );
  }
}

/// A scrollable list of preference tiles.
class _PrefList extends StatelessWidget {
  final List<ResolvedPreference> prefs;

  const _PrefList({required this.prefs});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: prefs.length,
      itemBuilder: (context, index) => _PrefTile(pref: prefs[index]),
    );
  }
}

/// A single row representing a preference, its current value, and its source.
class _PrefTile extends ConsumerWidget {
  final ResolvedPreference pref;

  const _PrefTile({required this.pref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Text(pref.name),
      subtitle: _PrefSubtitle(pref: pref),
      trailing: pref.isForced
          ? const Icon(Icons.lock_outline)
          : _PrefTrailingAction(pref: pref),
      onTap: pref.isForced ? null : () => _onTap(context, ref),
    );
  }

  /// Toggles boolean preferences or opens an editor for other types.
  void _onTap(BuildContext context, WidgetRef ref) {
    if (pref.type == .boolean) {
      ref
          .read(preferencesRepositoryProvider)
          .set(pref.key, !(pref.value as bool));
    } else {
      _editValue(context, ref, pref);
    }
  }

  /// Displays a text editor dialog for the value.
  void _editValue(
    BuildContext context,
    WidgetRef ref,
    ResolvedPreference pref,
  ) {
    final controller = TextEditingController(text: pref.value.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${pref.name} (${pref.type.name})'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: (pref.type == .integer || pref.type == .double)
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.general.cancel),
          ),
          TextButton(
            onPressed: () {
              final newValue = switch (pref.type) {
                .integer => int.tryParse(controller.text),
                .double => double.tryParse(controller.text),
                .string => controller.text,
                .boolean || .stringList => null,
              };

              if (newValue != null) {
                ref.read(preferencesRepositoryProvider).set(pref.key, newValue);
                Navigator.of(context).pop();
              } else {
                _showError(context);
              }
            },
            child: Text(t.general.ok),
          ),
        ],
      ),
    );
  }

  /// Shows a generic error message for invalid inputs.
  void _showError(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.errors.occurred),
        content: Text(t.featureFlags.invalidInput),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.general.ok),
          ),
        ],
      ),
    );
  }
}

/// Displays the current source (local, remote, override, forced) and effective
/// value of a preference.
class _PrefSubtitle extends StatelessWidget {
  final ResolvedPreference pref;

  const _PrefSubtitle({required this.pref});

  @override
  Widget build(BuildContext context) {
    final status = _getStatusMetadata();

    return Padding(
      padding: const .only(top: 4),
      child: Row(
        mainAxisSize: .min,
        children: [
          Container(
            padding: const .symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: status.bgColor,
              borderRadius: .circular(12),
            ),
            child: Text(
              status.text,
              style: TextStyle(
                fontSize: 12,
                color: status.textColor,
                fontWeight: .w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              pref.value.toString(),
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              overflow: .ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Returns visual styling and localized text based on the source.
  ({String text, Color bgColor, Color textColor}) _getStatusMetadata() {
    return switch (pref.source) {
      .override => (
        text: t.featureFlags.status.localOverride,
        bgColor: Colors.blue.withValues(alpha: 0.15),
        textColor: Colors.blue.shade800,
      ),
      .remote => (
        text: t.featureFlags.status.remote,
        bgColor: Colors.purple.withValues(alpha: 0.15),
        textColor: Colors.purple.shade800,
      ),
      .local => (
        text: t.featureFlags.status.local,
        bgColor: Colors.grey.withValues(alpha: 0.2),
        textColor: Colors.grey.shade800,
      ),
      .forced => (
        text: t.featureFlags.status.remoteOverride,
        bgColor: Colors.red.withValues(alpha: 0.15),
        textColor: Colors.red.shade800,
      ),
    };
  }
}

/// Provides interaction elements like switches (for booleans) or reset buttons.
class _PrefTrailingAction extends ConsumerWidget {
  final ResolvedPreference pref;

  const _PrefTrailingAction({required this.pref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOverridden = pref.source == .override;

    return Row(
      mainAxisSize: .min,
      children: [
        if (isOverridden)
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: t.featureFlags.reset,
            onPressed: () =>
                ref.read(preferencesRepositoryProvider).reset(pref.key),
          ),
        if (pref.type == .boolean)
          Switch(
            value: pref.value as bool,
            onChanged: (val) {
              ref.read(preferencesRepositoryProvider).set(pref.key, val);
            },
          )
        else
          const Icon(Icons.edit),
      ],
    );
  }
}
