import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Emits immediately and then once per minute so the focused course advances.
final homeClockProvider = StreamProvider.autoDispose<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream<DateTime>.periodic(
    const Duration(minutes: 1),
    (_) => DateTime.now(),
  );
});
