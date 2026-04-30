import 'package:flutter/foundation.dart';

/// Global toggle for demo mode.
///
/// When true, the application uses mock services and data instead of
/// communicating with the real NTUT servers.
///
/// Automatically true when running on the web, or can be overridden
/// via: `--dart-define=demo=true`
const bool isDemo =
    kIsWeb ||
    bool.fromEnvironment(
      'demo',
      defaultValue: false,
    );

const String demoUsername = '111590001';
const String demoPassword = 'demo1234';
