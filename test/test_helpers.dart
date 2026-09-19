import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/services/i_school_plus/ntut_i_school_plus_service.dart';

/// Test credentials loaded from environment variables.
///
/// Create a file `test/test_config.json` (gitignored):
/// ```json
/// {
///   "NTUT_TEST_USERNAME": "111360109",
///   "NTUT_TEST_PASSWORD": "your_password"
/// }
/// ```
///
/// Run tests with:
/// ```bash
/// flutter test --dart-define-from-file=test/test_config.json
/// ```
class TestCredentials {
  static const String username = .fromEnvironment('NTUT_TEST_USERNAME');
  static const String password = .fromEnvironment('NTUT_TEST_PASSWORD');

  static void validate() {
    if (username.isEmpty || password.isEmpty) {
      throw Exception(
        'Test credentials not provided.\n\n'
        '1. Create test/test_config.json with your credentials:\n'
        '   {\n'
        '     "NTUT_TEST_USERNAME": "111360109",\n'
        '     "NTUT_TEST_PASSWORD": "your_password"\n'
        '   }\n\n'
        '2. Run tests with:\n'
        '   flutter test --dart-define-from-file=test/test_config.json',
      );
    }
  }
}

/// Runs the public I-School Plus availability probe and reports why its
/// integration tests cannot run, or `null` when the service answered.
///
/// I-School Plus only serves campus IP addresses, so CI — and any run from
/// outside the campus network — cannot reach it. An unreachable host is an
/// expected environment rather than a failure, and the probe's own five-second
/// deadline bounds the wait. Errors that are not network-shaped still
/// propagate: those mean the probe itself is broken.
Future<String?> iSchoolPlusSkipReason() async {
  try {
    await NtutISchoolPlusService().checkAvailability();
    return null;
  } on TimeoutException {
    return _iSchoolPlusUnavailable;
  } on DioException {
    return _iSchoolPlusUnavailable;
  }
}

const _iSchoolPlusUnavailable =
    'I-School Plus is unreachable from this network; '
    'skipping its integration tests.';

/// Skips [body] when [iSchoolPlusSkipReason] reported the service unreachable.
///
/// [skipReason] is read when the test runs, so a `setUpAll` that probes once
/// can gate every test in its group.
void testWithISchoolPlus(
  String description,
  Future<void> Function() body, {
  required String? Function() skipReason,
}) {
  test(description, () async {
    if (skipReason() case final reason?) {
      markTestSkipped(reason);
      return;
    }
    await body();
  });
}

/// Adds a delay between tests to avoid hammering NTUT servers.
Future<void> respectfulDelay() async {
  await Future.delayed(const Duration(seconds: 1));
}

final _random = Random();

/// Extension to randomly pick an element from a list.
///
/// Provides variety in test data across test runs without increasing server load.
extension RandomPick<T> on List<T> {
  T pickRandom() {
    if (length == 0) {
      throw StateError('Cannot pick random element from empty list');
    }
    return this[_random.nextInt(length)];
  }
}
