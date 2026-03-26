import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/feature_flag_repository.dart';
import 'package:tattoo/repositories/feature_flag_providers.dart';

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
              //show snackbar to indicate that the flags have been refreshed
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(t.featureFlags.refreshed),
                ),
              );
            },
          ),
        ],
      ),
      body: flagsAsync.when(
        data: (flags) {
          if (flags.isEmpty) {
            return const Center(child: Text("No feature flags"));
          }
          return ListView.builder(
            itemCount: flags.length,
            itemBuilder: (context, index) {
              final flag = flags[index];
              final isOverridden = flag.source == FeatureFlagSource.override;

              String statusText;
              Color chipBgColor;
              Color chipTextColor;

              switch (flag.source) {
                case FeatureFlagSource.override:
                  statusText = t.featureFlags.status.overrideStatus;
                  chipBgColor = Colors.blue.withValues(alpha: 0.15);
                  chipTextColor = Colors.blue.shade800;
                case FeatureFlagSource.remote:
                  statusText = t.featureFlags.status.remote;
                  chipBgColor = Colors.purple.withValues(alpha: 0.15);
                  chipTextColor = Colors.purple.shade800;
                case FeatureFlagSource.local:
                  statusText = t.featureFlags.status.defaultStatus;
                  chipBgColor = Colors.grey.withValues(alpha: 0.2);
                  chipTextColor = Colors.grey.shade800;
                case FeatureFlagSource.forced:
                  statusText = t.featureFlags.status.forced;
                  chipBgColor = Colors.red.withValues(alpha: 0.15);
                  chipTextColor = Colors.red.shade800;
              }

              final subtitleWidget = Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: chipBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          color: chipTextColor,
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

              if (flag.source == FeatureFlagSource.forced) {
                return ListTile(
                  title: Text(flag.key),
                  subtitle: subtitleWidget,
                  trailing: const Icon(Icons.lock_outline),
                );
              }

              if (flag.type == bool) {
                return ListTile(
                  title: Text(flag.key),
                  subtitle: subtitleWidget,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isOverridden)
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          tooltip: t.featureFlags.reset,
                          onPressed: () => ref
                              .read(featureFlagsProvider.notifier)
                              .resetFlag(flag.key),
                        ),
                      Switch(
                        value: flag.value as bool,
                        onChanged: (val) {
                          ref
                              .read(featureFlagsProvider.notifier)
                              .setFlag(flag.key, val);
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    ref
                        .read(featureFlagsProvider.notifier)
                        .setFlag(flag.key, !(flag.value as bool));
                  },
                );
              }

              return ListTile(
                title: Text(flag.key),
                subtitle: subtitleWidget,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isOverridden)
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: t.featureFlags.reset,
                        onPressed: () => ref
                            .read(featureFlagsProvider.notifier)
                            .resetFlag(flag.key),
                      ),
                    const Icon(Icons.edit),
                  ],
                ),
                onTap: () => _editValue(context, ref, flag),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(t.errors.occurred)),
      ),
    );
  }

  void _editValue(BuildContext context, WidgetRef ref, FeatureFlag flag) {
    if (flag.options != null) {
      _showDropdownDialog(
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
      builder: (context) {
        return AlertDialog(
          title: Text('${flag.key} (${flag.type})'),
          content: TextField(
            controller: controller,
            keyboardType: (flag.type == int || flag.type == double)
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                dynamic newValue;
                switch (flag.type) {
                  case const (int):
                    newValue = int.tryParse(controller.text);
                  case const (double):
                    newValue = double.tryParse(controller.text);
                  case const (String):
                    newValue = controller.text;
                }
                if (newValue != null) {
                  ref
                      .read(featureFlagsProvider.notifier)
                      .setFlag(flag.key, newValue);
                  Navigator.of(context).pop();
                } else {
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
              },
              child: Text(t.general.ok),
            ),
          ],
        );
      },
    );
  }

  void _showDropdownDialog(
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
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
