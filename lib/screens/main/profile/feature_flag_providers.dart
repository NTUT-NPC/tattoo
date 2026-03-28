import 'package:riverpod/riverpod.dart';
import 'package:tattoo/repositories/feature_flag_repository.dart';

/// State notifier provider for the list of available feature flags.
///
/// This is the primary entry point for UI components to consume and manage
/// feature flag states.
final featureFlagsProvider =
    AsyncNotifierProvider<FeatureFlagsNotifier, List<FeatureFlag>>(
      FeatureFlagsNotifier.new,
    );

/// Notifier that manages the state of all feature flags.
///
/// It listens for updates from the [FeatureFlagRepository] and provides
/// methods to refresh, set, and reset flag values.
class FeatureFlagsNotifier extends AsyncNotifier<List<FeatureFlag>> {
  @override
  Future<List<FeatureFlag>> build() async {
    final repo = ref.watch(featureFlagRepositoryProvider);

    // Automatically invalidate the provider when the repository reports an update
    // (e.g., from a Remote Config sync).
    final subscription = repo.onUpdated.listen((_) => ref.invalidateSelf());
    ref.onDispose(subscription.cancel);

    return repo.getAllFlags();
  }

  /// Forces a fresh fetch of feature flags from the remote source.
  Future<void> refreshFlags() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      return ref
          .read(featureFlagRepositoryProvider)
          .getAllFlags(forceRefresh: true);
    });
  }

  /// Updates the value of a specific feature flag.
  Future<void> setFlag(String key, dynamic value) async {
    await ref.read(featureFlagRepositoryProvider).setFlag(key, value);
    ref.invalidateSelf();
  }

  /// Resets a specific feature flag to its default or remote value.
  Future<void> resetFlag(String key) async {
    await ref.read(featureFlagRepositoryProvider).resetFlag(key);
    ref.invalidateSelf();
  }
}

/// A convenience provider to retrieve the value of a specific feature flag by its [key].
///
/// Throws an [ArgumentError] if the key is not found in the loaded flags.
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
