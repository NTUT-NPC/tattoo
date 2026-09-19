import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod/riverpod.dart';

const _courseWidgetChannel = MethodChannel(
  'club.ntut.tattoo/course_widget',
);

/// Provides the platform bridge used by course-widget synchronization.
final courseWidgetPlatformProvider = Provider<CourseWidgetPlatform>((_) {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return MethodChannelCourseWidgetPlatform(_courseWidgetChannel);
  }
  return const NoopCourseWidgetPlatform();
});

/// Native/platform-facing bridge for the Android launcher course widget.
abstract interface class CourseWidgetPlatform {
  Future<String?> readFingerprint();

  Future<void> commitBitmaps({
    required Uint8List lightPng,
    required Uint8List darkPng,
    required String fingerprint,
  });

  Future<void> clear();

  Future<String?> takePendingRoute();

  void setRouteHandler(ValueChanged<String>? handler);
}

/// MethodChannel-backed Android implementation of [CourseWidgetPlatform].
class MethodChannelCourseWidgetPlatform implements CourseWidgetPlatform {
  MethodChannelCourseWidgetPlatform(this._channel) {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  final MethodChannel _channel;
  ValueChanged<String>? _routeHandler;

  @override
  Future<String?> readFingerprint() {
    return _channel.invokeMethod<String>('readFingerprint');
  }

  @override
  Future<void> commitBitmaps({
    required Uint8List lightPng,
    required Uint8List darkPng,
    required String fingerprint,
  }) {
    return _channel.invokeMethod<void>('commitBitmaps', {
      'lightPng': lightPng,
      'darkPng': darkPng,
      'fingerprint': fingerprint,
    });
  }

  @override
  Future<void> clear() => _channel.invokeMethod<void>('clear');

  @override
  Future<String?> takePendingRoute() {
    return _channel.invokeMethod<String>('takePendingRoute');
  }

  @override
  void setRouteHandler(ValueChanged<String>? handler) {
    _routeHandler = handler;
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method != 'openRoute') return;
    final arguments = call.arguments;
    if (arguments is! Map) return;
    final route = arguments['route'];
    if (route is String) _routeHandler?.call(route);
  }
}

/// No-op implementation used on platforms without Android launcher widgets.
class NoopCourseWidgetPlatform implements CourseWidgetPlatform {
  const NoopCourseWidgetPlatform();

  @override
  Future<String?> readFingerprint() async => null;

  @override
  Future<void> commitBitmaps({
    required Uint8List lightPng,
    required Uint8List darkPng,
    required String fingerprint,
  }) async {}

  @override
  Future<void> clear() async {}

  @override
  Future<String?> takePendingRoute() async => null;

  @override
  void setRouteHandler(ValueChanged<String>? handler) {}
}
