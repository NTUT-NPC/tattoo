import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/repositories/course_repository.dart';

/// Checks whether I-School Plus can be reached from the current network.
///
/// The availability probe is independent from any authenticated I-School Plus
/// request, so it can be shared by all I-School Plus features without making
/// their data providers depend on one another.
///
/// Riverpod's automatic retry is disabled because it would keep the state
/// loading while it re-probes a host that campus policy blocks, hiding the
/// failure the five-second deadline exists to report. Re-probing is
/// [ISchoolPlusAvailabilityNotifier.retry]'s explicit decision.
final iSchoolPlusAvailabilityProvider =
    AsyncNotifierProvider.autoDispose<ISchoolPlusAvailabilityNotifier, void>(
      ISchoolPlusAvailabilityNotifier.new,
      retry: (_, _) => null,
    );

class ISchoolPlusAvailabilityNotifier extends AsyncNotifier<void> {
  var _requestVersion = 0;

  @override
  Future<void> build() async {
    final version = ++_requestVersion;
    try {
      await ref.watch(courseRepositoryProvider).checkISchoolPlusAvailability();
    } catch (error, stackTrace) {
      // A retry or a successful authenticated request may have superseded
      // this probe while it was in flight. In that case, do not let its error
      // become the current availability state.
      if (version == _requestVersion) {
        Error.throwWithStackTrace(error, stackTrace);
      }
    }
  }

  /// Starts a fresh availability probe.
  void retry() {
    ++_requestVersion;
    // Clear the previous error before invalidation so the new loading state
    // does not retain it and make the UI show the guide during the retry.
    state = const AsyncData(null);
    ref.invalidateSelf();
  }

  /// Marks I-School Plus as reachable after a successful authenticated call.
  ///
  /// Incrementing the request version makes any in-flight probe stale, so a
  /// late failure cannot replace this successful state.
  void markAvailable() {
    ++_requestVersion;
    state = const AsyncData(null);
  }
}
