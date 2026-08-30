import 'package:flutter_riverpod/flutter_riverpod.dart';

const _taipeiOffset = Duration(hours: 8);

/// Returns the current instant represented as Taipei wall-clock fields.
///
/// The returned value is intentionally local-like: schedule times use the same
/// wall-clock representation regardless of the device's timezone.
DateTime taipeiNow() => _taipeiWallClock(DateTime.now());

DateTime _taipeiWallClock(DateTime instant) {
  final taipei = instant.toUtc().add(_taipeiOffset);
  return DateTime(
    taipei.year,
    taipei.month,
    taipei.day,
    taipei.hour,
    taipei.minute,
    taipei.second,
    taipei.millisecond,
    taipei.microsecond,
  );
}

/// Emits immediately and then once per minute so the focused course advances.
final homeClockProvider = StreamProvider.autoDispose<DateTime>((ref) async* {
  yield taipeiNow();
  yield* Stream<DateTime>.periodic(
    const Duration(minutes: 1),
    (_) => taipeiNow(),
  );
});
