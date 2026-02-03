import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

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
  static const String username = String.fromEnvironment('NTUT_TEST_USERNAME');
  static const String password = String.fromEnvironment('NTUT_TEST_PASSWORD');

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
