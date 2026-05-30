import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Global toggle for Firebase features.
///
/// Defaults to `false` to avoid package name mismatch issues in debug mode
/// (`club.ntut.tattoo.debug`). Override via: `--dart-define=USE_FIREBASE=true`
const bool useFirebase = .fromEnvironment(
  'USE_FIREBASE',
  defaultValue: false,
);

/// Global [FirebaseService] instance.
var firebaseService = const FirebaseService();

/// Unified service for Firebase Analytics, Crashlytics, and Remote Config.
///
/// Exposes nullable getters that return real instances when [useFirebase] is
/// true, or `null` when disabled. Callers use null-aware access:
///
/// ```dart
/// firebase.analytics?.logAppOpen();
/// firebase.crashlytics?.recordError(e, stack);
/// ```
class FirebaseService {
  static final _updateController = StreamController<void>.broadcast();
  static bool _isInitialized = false;

  const FirebaseService();

  /// A stream that emits whenever the Remote Config is updated and activated.
  Stream<void> get onConfigUpdated => _updateController.stream;

  /// The [FirebaseAnalytics] instance, or `null` if Firebase is disabled.
  FirebaseAnalytics? get analytics => useFirebase ? .instance : null;

  /// Returns a [FirebaseAnalyticsObserver] for use with navigation observers, or
  /// `null` if Firebase is disabled.
  FirebaseAnalyticsObserver? get analyticsObserver =>
      useFirebase ? FirebaseAnalyticsObserver(analytics: analytics!) : null;

  /// The [FirebaseCrashlytics] instance, or `null` if Firebase is disabled.
  FirebaseCrashlytics? get crashlytics => useFirebase ? .instance : null;

  /// The [FirebaseRemoteConfig] instance, or `null` if Firebase is disabled.
  FirebaseRemoteConfig? get remoteConfig => useFirebase ? .instance : null;

  /// Logs a custom message to Firebase Crashlytics if enabled.
  ///
  /// These logs appear in the "Logs" tab of a crash report and help provide
  /// context for what happened leading up to a crash.
  void log(String message) {
    crashlytics?.log(message);
  }

  /// Records a non-fatal error to Firebase Crashlytics if enabled.
  void recordNonFatal(String message) {
    crashlytics?.recordError(
      Exception(message),
      .current,
      fatal: false,
    );
  }

  /// Initializes Firebase Remote Config.
  ///
  /// Call this at app start to fetch and activate the latest configuration.
  /// Optionally provide [defaults] for in-app default values.
  Future<void> init({Map<String, dynamic>? defaults}) async {
    final rc = remoteConfig;
    if (rc == null) return;

    if (_isInitialized) {
      if (defaults != null) await setDefaults(defaults);
      return;
    }

    if (defaults != null) {
      await rc.setDefaults(defaults);
    }

    _setupUpdateListener(rc);

    await _fetchAndActivate(
      rc,
      context: 'initialized',
      setupSettings: true,
    );
    _isInitialized = true;
  }

  /// Updates the in-app default values for Remote Config.
  Future<void> setDefaults(Map<String, dynamic> defaults) async {
    await remoteConfig?.setDefaults(defaults);
  }

  void _setupUpdateListener(FirebaseRemoteConfig rc) {
    rc.onConfigUpdated.listen((event) async {
      dev.log(
        'Remote Config updated: ${event.updatedKeys}',
        name: 'FirebaseService',
      );
      await rc.activate();
      _updateController.add(null);
    });
  }

  /// Forces a fresh fetch and activation of Remote Config.
  Future<void> fetch() async {
    final rc = remoteConfig;
    if (rc == null) return;

    await _fetchAndActivate(
      rc,
      context: 'forced fetch',
      recordNonFatalOnFailure: true,
    );
  }

  Future<void> _fetchAndActivate(
    FirebaseRemoteConfig rc, {
    required String context,
    bool setupSettings = false,
    bool recordNonFatalOnFailure = false,
  }) async {
    try {
      if (setupSettings) {
        await rc.setConfigSettings(
          RemoteConfigSettings(
            fetchTimeout: const Duration(minutes: 1),
            minimumFetchInterval: const Duration(minutes: 1),
          ),
        );
      }

      await rc.fetchAndActivate();

      final keys = rc.getAll().keys.toList()..sort();
      final status = rc.lastFetchStatus;

      if (status == .success) {
        final message =
            'Remote Config $context successful: count=${keys.length}, keys=$keys';
        dev.log(message, name: 'FirebaseService');
        firebaseService.log(message);
      } else {
        final message =
            'Remote Config $context failed (status: $status): count=${keys.length}, keys=$keys';
        dev.log(message, name: 'FirebaseService');
        firebaseService.log(message);
      }
    } catch (e) {
      final keys = rc.getAll().keys.toList()..sort();
      final message =
          'Remote Config $context error: $e. Cache: count=${keys.length}, keys=$keys';
      dev.log(message, name: 'FirebaseService');

      if (recordNonFatalOnFailure) {
        firebaseService.recordNonFatal(message);
      } else {
        firebaseService.log(message);
      }
    }
  }

  /// Retrieves a summary of a Remote Config string value.
  ///
  /// Returns a record containing the string value and whether it came from
  /// a remote source.
  ({String value, bool isRemote}) getRemoteConfigString(String key) {
    final rc = remoteConfig;
    if (rc == null) {
      return (value: '', isRemote: false);
    }
    final val = rc.getValue(key);
    return (
      value: val.asString(),
      isRemote: val.source == .valueRemote,
    );
  }

  /// Retrieves a Remote Config value with type-aware casting based on [defaultValue].
  ({dynamic value, bool isRemote}) getRemoteConfigValue(
    String key,
    dynamic defaultValue,
  ) {
    final rc = remoteConfig;
    if (rc == null) {
      return (value: defaultValue, isRemote: false);
    }

    final val = rc.getValue(key);
    final isRemote = val.source == .valueRemote;

    dev.log(
      'Resolving Remote Config key: $key (source: ${val.source}, isRemote: $isRemote)',
      name: 'FirebaseService',
    );

    if (!isRemote) {
      return (value: defaultValue, isRemote: false);
    }

    dynamic value;
    if (defaultValue is bool) {
      value = val.asBool();
    } else if (defaultValue is int) {
      value = val.asInt();
    } else if (defaultValue is double) {
      value = val.asDouble();
    } else if (defaultValue is String) {
      value = val.asString();

      // Try to parse as JSON if it looks like a Map or List
      if (value.startsWith('{') || value.startsWith('[')) {
        try {
          value = jsonDecode(value);
        } catch (_) {
          // Keep as string if not valid JSON
        }
      }
    } else if (defaultValue is Map || defaultValue is List) {
      try {
        value = jsonDecode(val.asString());
      } catch (_) {
        // If it's not valid JSON, but the Remote Config source is remote,
        // it might be a plain string (e.g. comma-separated list).
        value = isRemote ? val.asString() : defaultValue;
      }
    } else {
      value = val.asString();
    }

    return (value: value, isRemote: isRemote);
  }

  /// Returns all Remote Config values as a map.
  Map<String, ({dynamic value, bool isRemote})> getAllRemoteConfigValues() {
    final rc = remoteConfig;
    if (rc == null) return {};

    return rc.getAll().map((key, val) {
      final isRemote = val.source == .valueRemote;
      dynamic value = val.asString();

      // Try to parse as JSON if it looks like a Map or List
      if (value.startsWith('{') || value.startsWith('[')) {
        try {
          value = jsonDecode(value);
        } catch (_) {
          // Keep as string if not valid JSON
        }
      } else if (value == 'true') {
        value = true;
      } else if (value == 'false') {
        value = false;
      } else {
        // Try parsing as number
        final numValue = num.tryParse(value);
        if (numValue != null) {
          value = numValue;
        }
      }

      return MapEntry(key, (value: value, isRemote: isRemote));
    });
  }
}
