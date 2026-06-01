import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/repositories/preferences_repository.dart';

/// The resolved state of every preference, for the overrides debug screen.
///
/// Single-value consumers should use [PreferenceReader.pref] instead.
final preferencesProvider =
    AsyncNotifierProvider<PreferencesNotifier, List<ResolvedPreference>>(
      PreferencesNotifier.new,
    );

/// Resolves all preferences and re-resolves when the repository reports an
/// update (a Remote Config sync or a local override change).
class PreferencesNotifier extends AsyncNotifier<List<ResolvedPreference>> {
  @override
  Future<List<ResolvedPreference>> build() async {
    final repo = ref.watch(preferencesRepositoryProvider);

    final subscription = repo.onUpdated.listen((_) => ref.invalidateSelf());
    ref.onDispose(subscription.cancel);

    return repo.resolveAll();
  }
}

/// The effective value of a single preference, falling back to the key's
/// default while preferences are loading or absent.
final preferenceValueProvider = Provider.family<Object?, PrefKey>((ref, key) {
  return ref.watch(
    preferencesProvider.select(
      (async) => async.maybeWhen(
        data: (prefs) =>
            prefs.where((p) => p.key == key).map((p) => p.value).firstOrNull,
        orElse: () => null,
      ),
    ),
  );
});

/// Ergonomic, typed access to a single preference from the widget tree.
extension PreferenceReader on WidgetRef {
  /// Watches [key] and returns its effective value, typed via the key.
  ///
  /// Returns the key's default while preferences are loading or unavailable.
  T pref<T>(PrefKey<T> key) =>
      watch(preferenceValueProvider(key)) as T? ?? key.defaultValue;
}
