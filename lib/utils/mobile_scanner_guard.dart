import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

Future<T?> guardMobileScannerCall<T>(Future<T> Function() action) {
  final completer = Completer<T?>();

  runZonedGuarded(
    () async {
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        if (_isNoActiveStreamCancelError(error)) {
          completer.complete(null);
          return;
        }
        completer.completeError(error, stackTrace);
      }
    },
    (error, stackTrace) {
      if (_isNoActiveStreamCancelError(error)) return;

      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'mobile_scanner',
        ),
      );
    },
  );

  return completer.future;
}

bool _isNoActiveStreamCancelError(Object error) {
  return error is PlatformException &&
      error.message == 'No active stream to cancel';
}
