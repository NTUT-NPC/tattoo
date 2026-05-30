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
/// It listens for updates from the [FeatureFlagRepository].
class FeatureFlagsNotifier extends AsyncNotifier<List<FeatureFlag>> {
  @override
  Future<List<FeatureFlag>> build() async {
    final repo = ref.watch(featureFlagRepositoryProvider);

    // Automatically invalidate the provider when the repository reports an update
    // (e.g., from a Remote Config sync or local override change).
    final subscription = repo.onUpdated.listen((_) => ref.invalidateSelf());
    ref.onDispose(subscription.cancel);

    return repo.getAllFlags();
  }
}
