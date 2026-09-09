import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/services.dart' show appFlavor;
import 'package:tattoo/firebase_options_production.dart' as production;
import 'package:tattoo/firebase_options_staging.dart' as staging;

/// Selects the generated Firebase options for the active Flutter flavor.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => switch (appFlavor) {
    'staging' => staging.DefaultFirebaseOptions.currentPlatform,
    'production' => production.DefaultFirebaseOptions.currentPlatform,
    final flavor => throw StateError('Unsupported app flavor: $flavor'),
  };
}
