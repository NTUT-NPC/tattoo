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
              final isOverridden = flag.overrideValue != null;

              if (flag.type == bool) {
                return ListTile(
                  title: Text(flag.key),
                  subtitle: isOverridden ? Text('Override: ${flag.value}') : Text('Default: ${flag.value}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isOverridden)
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          tooltip: t.featureFlags.reset,
                          onPressed: () => ref.read(featureFlagsProvider.notifier).resetFlag(flag.key),
                        ),
                      Switch(
                        value: flag.value as bool,
                        onChanged: (val) {
                          ref.read(featureFlagsProvider.notifier).setFlag(flag.key, val);
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    ref.read(featureFlagsProvider.notifier).setFlag(flag.key, !(flag.value as bool));
                  },
                );
              }

              return ListTile(
                title: Text(flag.key),
                subtitle: isOverridden ? Text('Override: ${flag.value}') : Text('Default: ${flag.value}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isOverridden)
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: t.featureFlags.reset,
                        onPressed: () => ref.read(featureFlagsProvider.notifier).resetFlag(flag.key),
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
    final controller = TextEditingController(text: flag.value.toString());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(flag.key),
          content: TextField(
            controller: controller,
            keyboardType: flag.type == int || flag.type == double ? TextInputType.number : TextInputType.text,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                dynamic newValue;
                if (flag.type == int) {
                  newValue = int.tryParse(controller.text);
                } else if (flag.type == double) {
                  newValue = double.tryParse(controller.text);
                } else {
                  newValue = controller.text;
                }
                if (newValue != null) {
                  ref.read(featureFlagsProvider.notifier).setFlag(flag.key, newValue);
                }
                Navigator.of(context).pop();
              },
              child: Text(t.general.ok),
            ),
          ],
        );
      },
    );
  }
}
