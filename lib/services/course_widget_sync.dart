import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tattoo/repositories/course_repository.dart';
import 'package:tattoo/screens/main/course_table/course_table_colors.dart';
import 'package:tattoo/services/course_widget_platform.dart';

/// Locale and both system-theme palettes used by launcher bitmap exports.
typedef CourseWidgetPresentation = ({
  String locale,
  ColorScheme lightColors,
  ColorScheme darkColors,
});

/// Complete input for rendering one system-theme variant.
typedef CourseWidgetRenderInput = ({
  LatestCachedCourseTable cache,
  String locale,
  Brightness brightness,
  ColorScheme colors,
});

typedef CourseWidgetRenderer = Future<Uint8List> Function(
  CourseWidgetRenderInput input,
);

typedef _CourseWidgetSource = ({
  LatestCachedCourseTable cache,
  CourseWidgetPresentation presentation,
});

typedef _PendingRender = ({
  int generation,
  String fingerprint,
  _CourseWidgetSource input,
});

/// App-lifetime controller that serializes cache reconciliation, rendering,
/// persistence, and cross-user cleanup for the Android course widget.
class CourseWidgetSyncController {
  CourseWidgetSyncController(
    this._watchChanges,
    this._readLatest,
    this._platform,
  );

  static const debounceDuration = Duration(milliseconds: 250);

  final Stream<void> Function() _watchChanges;
  final Future<LatestCachedCourseTable?> Function() _readLatest;
  final CourseWidgetPlatform _platform;

  StreamSubscription<void>? _subscription;
  Timer? _debounce;
  CourseWidgetRenderer? _renderer;
  CourseWidgetPresentation? _presentation;
  _PendingRender? _pending;
  Future<void>? _commit;
  String? _persistedFingerprint;
  String? _activeFingerprint;
  var _generation = 0;
  var _lifecycleGeneration = 0;
  var _started = false;
  var _draining = false;

  void attachRenderer(CourseWidgetRenderer? renderer) {
    if (identical(_renderer, renderer)) return;
    _renderer = renderer;
    _generation++;
    _pending = null;
  }

  /// Starts one cache subscription and loads the native persisted fingerprint.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    final lifecycleGeneration = ++_lifecycleGeneration;
    _persistedFingerprint = await _platform.readFingerprint();
    if (!_started || lifecycleGeneration != _lifecycleGeneration) return;
    _subscription = _watchChanges().listen((_) => _scheduleReconcile());
  }

  /// Updates render-affecting presentation state and debounces reconciliation.
  void setPresentation(CourseWidgetPresentation presentation) {
    if (_presentation == presentation) return;
    _presentation = presentation;
    if (_started) _scheduleReconcile();
  }

  /// Reads one coherent latest cache snapshot and queues only changed output.
  Future<void> reconcile() async {
    final presentation = _presentation;
    if (!_started || presentation == null || _renderer == null) return;
    final observedGeneration = _generation;
    final cache = await _readLatest();
    if (!_started || observedGeneration != _generation) return;
    if (cache == null) {
      await _clearWhileRunning();
      return;
    }

    final input = (cache: cache, presentation: presentation);
    final fingerprint = _courseWidgetFingerprint(input);
    if (fingerprint == _persistedFingerprint ||
        fingerprint == _activeFingerprint ||
        fingerprint == _pending?.fingerprint) {
      return;
    }

    final generation = ++_generation;
    _pending = (
      generation: generation,
      fingerprint: fingerprint,
      input: input,
    );
    unawaited(_drain());
  }

  /// Invalidates in-flight work, clears native state, and allows a later start.
  Future<void> invalidateAndClear() => _stopAndClear();

  /// Stops synchronization until the next authenticated session and clears the
  /// native bitmap only after any already-entered commit has completed.
  Future<void> stopAndClear() => _stopAndClear();

  Future<void> _stopAndClear() async {
    _started = false;
    _lifecycleGeneration++;
    _generation++;
    _debounce?.cancel();
    _debounce = null;
    await _subscription?.cancel();
    _subscription = null;
    _pending = null;
    await _awaitCommit();
    await _platform.clear();
    _persistedFingerprint = null;
    _activeFingerprint = null;
  }

  Future<void> _clearWhileRunning() async {
    _generation++;
    _pending = null;
    await _awaitCommit();
    await _platform.clear();
    _persistedFingerprint = null;
    _activeFingerprint = null;
  }

  Future<void> _awaitCommit() async {
    try {
      await _commit;
    } catch (_) {
      // Cleanup must still run when the write being superseded failed.
    }
  }

  void _scheduleReconcile() {
    if (!_started) return;
    _generation++;
    _pending = null;
    _debounce?.cancel();
    _debounce = Timer(debounceDuration, () => unawaited(reconcile()));
  }

  Future<void> _drain() async {
    if (_draining) return;
    _draining = true;
    try {
      while (_started) {
        final pending = _pending;
        if (pending == null) break;
        _pending = null;
        final renderer = _renderer;
        if (renderer == null) break;
        _activeFingerprint = pending.fingerprint;
        final source = pending.input;
        try {
          final lightPng = await renderer((
            cache: source.cache,
            locale: source.presentation.locale,
            brightness: Brightness.light,
            colors: source.presentation.lightColors,
          ));
          if (!_isLatest(pending)) continue;

          final darkPng = await renderer((
            cache: source.cache,
            locale: source.presentation.locale,
            brightness: Brightness.dark,
            colors: source.presentation.darkColors,
          ));
          if (!_isLatest(pending)) continue;

          final commit = _platform.commitBitmaps(
            lightPng: lightPng,
            darkPng: darkPng,
            fingerprint: pending.fingerprint,
          );
          _commit = commit;
          try {
            await commit;
            if (pending.generation == _generation) {
              _persistedFingerprint = pending.fingerprint;
            }
          } finally {
            _commit = null;
          }
        } catch (error, stackTrace) {
          debugPrint('Course widget sync failed: $error\n$stackTrace');
        } finally {
          _activeFingerprint = null;
        }
      }
    } finally {
      _activeFingerprint = null;
      _draining = false;
      if (_started && _pending != null) unawaited(_drain());
    }
  }

  bool _isLatest(_PendingRender pending) {
    return _started && pending.generation == _generation && _pending == null;
  }
}

/// Canonical fingerprint for every value that can affect exported pixels.
String _courseWidgetFingerprint(_CourseWidgetSource input) {
  final cache = input.cache;
  final presentation = input.presentation;
  final colorByCourseId = buildCourseTableColorMap(cache.courseTable);
  final scheduled = cache.courseTable.scheduled.entries.toList()
    ..sort((a, b) {
      final day = a.key.day.index.compareTo(b.key.day.index);
      if (day != 0) return day;
      final period = a.key.period.index.compareTo(b.key.period.index);
      if (period != 0) return period;
      return a.value.id.compareTo(b.value.id);
    });
  Map<String, int> colorValues(ColorScheme colors) => {
    'surface': colors.surface.toARGB32(),
    'onSurface': colors.onSurface.toARGB32(),
  };
  final canonical = <String, Object>{
    'version': 1,
    'locale': presentation.locale,
    'colors': <String, Map<String, int>>{
      'light': colorValues(presentation.lightColors),
      'dark': colorValues(presentation.darkColors),
    },
    'scheduled': [
      for (final entry in scheduled)
        [
          entry.key.day.index,
          entry.key.period.index,
          entry.value.id,
          entry.value.span,
          entry.value.crossesNoon,
          entry.value.courseName,
          entry.value.number,
          entry.value.classroomName,
          colorByCourseId[entry.value.id]!.toARGB32(),
        ],
    ],
  };
  return sha256.convert(utf8.encode(jsonEncode(canonical))).toString();
}

/// Provides the app-level widget synchronization controller.
final courseWidgetSyncControllerProvider = Provider<CourseWidgetSyncController>(
  (
    ref,
  ) {
    final repository = ref.read(courseRepositoryProvider);
    return CourseWidgetSyncController(
      repository.watchCourseTableCacheChanges,
      repository.readLatestCachedCourseTable,
      ref.read(courseWidgetPlatformProvider),
    );
  },
);
