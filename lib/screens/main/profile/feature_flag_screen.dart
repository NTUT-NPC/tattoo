import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/feature_flag_repository.dart';
import 'package:tattoo/screens/main/profile/feature_flag_providers.dart';

/// A screen that displays all available feature flags, allowing users (typically
/// developers or testers) to view and override flag values.
class FeatureFlagScreen extends ConsumerWidget {
  const FeatureFlagScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flagsAsync = ref.watch(featureFlagsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.featureFlags.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_download),
            tooltip: t.featureFlags.reset,
            onPressed: () {
              ref.read(featureFlagsProvider.notifier).refreshFlags();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t.featureFlags.refreshed)),
              );
            },
          ),
        ],
      ),
      body: flagsAsync.when(
        data: (flags) => flags.isEmpty
            ? Center(child: Text(t.featureFlags.noFlag))
            : _FlagList(flags: flags),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(t.errors.occurred)),
      ),
    );
  }
}

/// A scrollable list of feature flag tiles.
class _FlagList extends StatelessWidget {
  final List<FeatureFlag> flags;

  const _FlagList({required this.flags});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: flags.length,
      itemBuilder: (context, index) => _FlagTile(flag: flags[index]),
    );
  }
}

/// A single row representing a feature flag, its current value, and its source.
class _FlagTile extends ConsumerWidget {
  final FeatureFlag flag;

  const _FlagTile({required this.flag});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isForced = flag.source == FeatureFlagSource.forced;

    return ListTile(
      title: Text(flag.key),
      subtitle: _FlagSubtitle(flag: flag),
      trailing: isForced
          ? const Icon(Icons.lock_outline)
          : _FlagTrailingAction(flag: flag),
      onTap: isForced ? null : () => _onTap(context, ref),
    );
  }

  /// Toggles boolean flags or opens an editor for other types.
  void _onTap(BuildContext context, WidgetRef ref) {
    if (flag.type == bool) {
      ref
          .read(featureFlagsProvider.notifier)
          .setFlag(flag.key, !(flag.value as bool));
    } else {
      _editValue(context, ref, flag);
    }
  }

  /// Displays an appropriate editor (dialog or option list) for the flag's value.
  void _editValue(BuildContext context, WidgetRef ref, FeatureFlag flag) {
    if (flag.options != null) {
      _showOptionsDialog(
        context,
        ref,
        flag,
        flag.options!.map((e) => e.toString()).toList(),
      );
      return;
    }

    final controller = TextEditingController(text: flag.value.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${flag.key} (${flag.type})'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: (flag.type == int || flag.type == double)
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
              final newValue = switch (flag.type) {
                const (int) => int.tryParse(controller.text),
                const (double) => double.tryParse(controller.text),
                const (String) => controller.text,
                _ => null,
              };

              if (newValue != null) {
                ref
                    .read(featureFlagsProvider.notifier)
                    .setFlag(flag.key, newValue);
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

  /// Shows a selection dialog when a list of permitted values is available.
  void _showOptionsDialog(
    BuildContext context,
    WidgetRef ref,
    FeatureFlag flag,
    List<String> options,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(flag.key),
          content: RadioGroup<String>(
            groupValue: flag.value as String,
            onChanged: (newValue) {
              if (newValue != null) {
                ref
                    .read(featureFlagsProvider.notifier)
                    .setFlag(flag.key, newValue);
              }
              Navigator.of(context).pop();
            },
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: options.map((option) {
                  return RadioListTile<String>(
                    title: Text(option),
                    value: option,
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t.general.cancel),
            ),
          ],
        );
      },
    );
  }

  /// Shows a generic error message for invalid inputs.
  void _showError(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.errors.occurred),
        content: Text(t.errors.invalidInput),
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

/// Displays the current source (local, remote, override) and effective value of a flag.
class _FlagSubtitle extends StatelessWidget {
  final FeatureFlag flag;

  const _FlagSubtitle({required this.flag});

  @override
  Widget build(BuildContext context) {
    final status = _getStatusMetadata();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: status.bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status.text,
              style: TextStyle(
                fontSize: 12,
                color: status.textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              flag.value.toString(),
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Returns visual styling and localized text based on the flag's source.
  ({String text, Color bgColor, Color textColor}) _getStatusMetadata() {
    return switch (flag.source) {
      FeatureFlagSource.override => (
        text: t.featureFlags.status.localOverride,
        bgColor: Colors.blue.withValues(alpha: 0.15),
        textColor: Colors.blue.shade800,
      ),
      FeatureFlagSource.remote => (
        text: t.featureFlags.status.remote,
        bgColor: Colors.purple.withValues(alpha: 0.15),
        textColor: Colors.purple.shade800,
      ),
      FeatureFlagSource.local => (
        text: t.featureFlags.status.local,
        bgColor: Colors.grey.withValues(alpha: 0.2),
        textColor: Colors.grey.shade800,
      ),
      FeatureFlagSource.forced => (
        text: t.featureFlags.status.remoteOverride,
        bgColor: Colors.red.withValues(alpha: 0.15),
        textColor: Colors.red.shade800,
      ),
    };
  }
}

/// Provides interaction elements like switches (for booleans) or reset buttons.
class _FlagTrailingAction extends ConsumerWidget {
  final FeatureFlag flag;

  const _FlagTrailingAction({required this.flag});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOverridden = flag.source == FeatureFlagSource.override;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isOverridden)
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: t.featureFlags.reset,
            onPressed: () =>
                ref.read(featureFlagsProvider.notifier).resetFlag(flag.key),
          ),
        if (flag.type == bool)
          Switch(
            value: flag.value as bool,
            onChanged: (val) {
              ref.read(featureFlagsProvider.notifier).setFlag(flag.key, val);
            },
          )
        else
          const Icon(Icons.edit),
      ],
    );
  }
}
