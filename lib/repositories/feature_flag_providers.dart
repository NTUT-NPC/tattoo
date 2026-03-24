import 'package:riverpod/riverpod.dart';
import 'package:tattoo/repositories/feature_flag_repository.dart';

/// State notifier provider for feature flags, which is the main UI entry point mapping.
final featureFlagsProvider =
    AsyncNotifierProvider<FeatureFlagsNotifier, List<FeatureFlag>>(
      FeatureFlagsNotifier.new,
    );

class FeatureFlagsNotifier extends AsyncNotifier<List<FeatureFlag>> {
  @override
  Future<List<FeatureFlag>> build() async {
    return ref.watch(featureFlagRepositoryProvider).getAllFlags();
  }

  Future<void> setFlag(String key, dynamic value) async {
    await ref.read(featureFlagRepositoryProvider).setFlag(key, value);
    ref.invalidateSelf();
  }

  Future<void> resetFlag(String key) async {
    await ref.read(featureFlagRepositoryProvider).resetFlag(key);
    ref.invalidateSelf();
  }
}

/// Syntactic sugar to get a specific flag's value easily in the UI.
final featureFlagValueProvider = FutureProvider.family<dynamic, String>((
  ref,
  key,
) async {
  final flags = await ref.watch(featureFlagsProvider.future);
  final flag = flags.firstWhere(
    (f) => f.key == key,
    orElse: () => throw ArgumentError('Flag $key not found'),
  );
  return flag.value;
});
