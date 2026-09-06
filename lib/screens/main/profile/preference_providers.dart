import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/repositories/language_repository.dart';
import 'package:tattoo/repositories/preferences_repository.dart';
import 'package:tattoo/screens/main/profile/preference_definitions.dart';

/// The resolved state of every preference, for settings and the debug screen.
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
      (async) => async.value
          ?.where((p) => p.key == key)
          .map((p) => p.value)
          .firstOrNull,
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

enum PreferenceDetailMode { selection, guide, unsupported }

enum PreferenceDetailError { save, action }

class PreferenceDetailState {
  const PreferenceDetailState({
    required this.mode,
    required this.value,
    required this.enabled,
    this.isSaving = false,
    this.error,
  });

  final PreferenceDetailMode mode;
  final String value;
  final bool enabled;
  final bool isSaving;
  final PreferenceDetailError? error;

  PreferenceDetailState copyWith({
    String? value,
    bool? enabled,
    bool? isSaving,
    PreferenceDetailError? error,
    bool clearError = false,
  }) {
    return PreferenceDetailState(
      mode: mode,
      value: value ?? this.value,
      enabled: enabled ?? this.enabled,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : error ?? this.error,
    );
  }
}

final preferenceDetailProvider = AsyncNotifierProvider.autoDispose
    .family<
      PreferenceDetailNotifier,
      PreferenceDetailState,
      PreferenceDetailId
    >(PreferenceDetailNotifier.new);

class PreferenceDetailNotifier extends AsyncNotifier<PreferenceDetailState> {
  PreferenceDetailNotifier(this._id);

  final PreferenceDetailId _id;
  var _requestVersion = 0;
  var _saving = false;

  @override
  Future<PreferenceDetailState> build() async {
    switch (_id) {
      case .language:
        final lifecycle = AppLifecycleListener(
          onResume: () {
            if (!_saving) _refresh();
          },
        );
        ref.onDispose(lifecycle.dispose);
      case .themeMode:
        ref.listen(preferencesProvider, (_, _) {
          if (!_saving) _refresh();
        });
    }

    return _readCurrent();
  }

  Future<PreferenceDetailState> _readCurrent() {
    return switch (_id) {
      .language => _readLanguage(),
      .themeMode => _readThemeMode(),
    };
  }

  Future<PreferenceDetailState> _readLanguage() async {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => PreferenceDetailState(
        mode: .selection,
        value: await ref.read(languageRepositoryProvider).readSelection(),
        enabled: true,
      ),
      TargetPlatform.iOS => const PreferenceDetailState(
        mode: .guide,
        value: 'system',
        enabled: true,
      ),
      _ => const PreferenceDetailState(
        mode: .unsupported,
        value: 'system',
        enabled: false,
      ),
    };
  }

  Future<PreferenceDetailState> _readThemeMode() async {
    final prefs = await ref.read(preferencesProvider.future);
    final preferences = {for (final pref in prefs) pref.key: pref};
    final pref = preferences[PrefKey.themeMode];
    final value = switch (pref?.value) {
      'light' => 'light',
      'dark' => 'dark',
      _ => 'system',
    };
    return PreferenceDetailState(
      mode: .selection,
      value: value,
      enabled: pref != null && !pref.isForced,
    );
  }

  Future<void> _refresh({bool showLoading = false}) async {
    final previous = state.value;
    final version = ++_requestVersion;
    if (showLoading) state = const AsyncLoading();

    try {
      final next = await _readCurrent();
      if (ref.mounted && version == _requestVersion) {
        state = AsyncData(next);
      }
    } catch (error, stackTrace) {
      if (!ref.mounted || version != _requestVersion) return;
      state = previous == null
          ? AsyncError(error, stackTrace)
          : AsyncData(previous);
    }
  }

  Future<void> select(String value) async {
    final current = state.value;
    if (current == null ||
        !current.enabled ||
        _saving ||
        current.isSaving ||
        value == current.value) {
      return;
    }
    final version = ++_requestVersion;
    _saving = true;
    state = AsyncData(current.copyWith(isSaving: true, clearError: true));

    try {
      switch (_id) {
        case .language:
          await ref.read(languageRepositoryProvider).select(value);
        case .themeMode:
          await ref
              .read(preferencesRepositoryProvider)
              .set(PrefKey.themeMode, value);
      }
      final next = await _readCurrent();
      if (ref.mounted && version == _requestVersion) {
        state = AsyncData(next);
      }
    } catch (_) {
      if (ref.mounted && version == _requestVersion) {
        state = AsyncData(
          current.copyWith(
            isSaving: false,
            error: PreferenceDetailError.save,
          ),
        );
      }
    } finally {
      _saving = false;
      final latest = state.value;
      if (ref.mounted &&
          version == _requestVersion &&
          latest?.isSaving == true &&
          latest?.error == null) {
        state = AsyncData(latest!.copyWith(isSaving: false));
      }
    }
  }

  Future<void> openSystemSettings() async {
    final current = state.value;
    if (current == null || _saving || current.isSaving) return;
    final version = ++_requestVersion;
    _saving = true;
    state = AsyncData(current.copyWith(isSaving: true, clearError: true));
    try {
      await ref.read(languageRepositoryProvider).openSystemSettings();
      if (ref.mounted && version == _requestVersion) {
        state = AsyncData(current.copyWith(isSaving: false));
      }
    } catch (_) {
      if (ref.mounted && version == _requestVersion) {
        state = AsyncData(
          current.copyWith(
            isSaving: false,
            error: PreferenceDetailError.action,
          ),
        );
      }
    } finally {
      _saving = false;
    }
  }

  void clearError() {
    final current = state.value;
    if (current?.error != null) {
      state = AsyncData(current!.copyWith(clearError: true));
    }
  }

  void retry() => _refresh(showLoading: true);
}
