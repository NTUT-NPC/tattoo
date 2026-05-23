import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

/// Dio [HttpClientAdapter] that delegates HTTP requests to Android's native
/// [HttpURLConnection] via a [MethodChannel].
///
/// This uses the system's Conscrypt TLS provider, whose fingerprint matches
/// standard Android apps and avoids firewall detection that targets BoringSSL
/// (used by dart:io and Cronet) or OpenSSL (used by curl).
///
/// Cookie management, redirect handling, and response transformation are all
/// handled by Dio interceptors above this adapter layer — the adapter only
/// needs to pass headers and bytes transparently.
class NativeHttpAdapter implements HttpClientAdapter {
  static const _channel = MethodChannel('club.ntut.tattoo/native_http');
  static int _nextRequestId = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    // Collect request body stream into bytes
    Uint8List? bodyBytes;
    if (requestStream != null) {
      final builder = BytesBuilder(copy: false);
      final completer = Completer<void>();
      StreamSubscription<Uint8List>? subscription;

      if (cancelFuture != null) {
        cancelFuture.then((_) {
          if (!completer.isCompleted) {
            subscription?.cancel();
            completer.completeError(
              DioException(
                requestOptions: options,
                type: .cancel,
                message: 'Request cancelled during upload buffering',
              ),
            );
          }
        });
      }

      try {
        subscription = requestStream.listen(
          (chunk) {
            builder.add(chunk);
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!completer.isCompleted) {
              completer.completeError(error, stackTrace);
            }
          },
          onDone: () {
            if (!completer.isCompleted) {
              completer.complete();
            }
          },
          cancelOnError: true,
        );

        await completer.future;

        if (builder.length > 0) {
          bodyBytes = builder.takeBytes();
        }
      } catch (e) {
        await subscription?.cancel();
        rethrow;
      }
    }

    // Flatten headers to Map<String, List<String>>
    final headers = <String, List<String>>{};
    options.headers.forEach((key, value) {
      if (value == null) return;
      if (value is Iterable) {
        headers[key] = value.map((e) => e.toString()).toList();
      } else {
        headers[key] = [value.toString()];
      }
    });

    final requestId =
        '${DateTime.now().microsecondsSinceEpoch}_${_nextRequestId++}';
    var requestCompleted = false;
    final cancelCompleter = Completer<Map?>();

    if (cancelFuture != null) {
      cancelFuture.then((_) {
        if (requestCompleted) return;
        requestCompleted = true;

        // Notify native side to cancel the connection
        _channel
            .invokeMethod('cancel', {'requestId': requestId})
            .catchError((_) => null);

        if (!cancelCompleter.isCompleted) {
          cancelCompleter.completeError(
            DioException(
              requestOptions: options,
              type: .cancel,
              message: 'Request cancelled',
            ),
          );
        }
      });
    }

    try {
      final fetchFuture = _channel.invokeMethod<Map>('fetch', {
        'requestId': requestId,
        'url': options.uri.toString(),
        'method': options.method,
        'headers': headers,
        'body': bodyBytes,
        'followRedirects': options.followRedirects,
        'connectTimeout': options.connectTimeout?.inMilliseconds,
        'readTimeout': options.receiveTimeout?.inMilliseconds,
      });

      if (cancelFuture != null) {
        // Silence unhandled PlatformExceptions if the request is cancelled and abandoned
        fetchFuture.catchError((_) => <dynamic, dynamic>{});
      }

      final result = cancelFuture != null
          ? await Future.any([fetchFuture, cancelCompleter.future])
          : await fetchFuture;

      requestCompleted = true;

      if (result == null) {
        throw DioException(
          requestOptions: options,
          type: .connectionError,
          message:
              'Invalid or null response received from native HTTP channel.',
        );
      }

      final response = Map<dynamic, dynamic>.from(result);
      final rawStatusCode = response['statusCode'];
      if (rawStatusCode == null || rawStatusCode is! int) {
        throw DioException(
          requestOptions: options,
          type: .connectionError,
          message: 'Invalid or missing HTTP status code from native response.',
        );
      }
      final statusCode = rawStatusCode;
      final statusMessage = response['statusMessage'] as String?;

      final responseHeaders = <String, List<String>>{};
      final rawHeaders = response['headers'];
      if (rawHeaders is Map) {
        rawHeaders.forEach((key, value) {
          if (value is List) {
            responseHeaders[key.toString()] = value
                .map((e) => e.toString())
                .toList();
          }
        });
      }

      final rawBody = response['body'];
      final body = rawBody is Uint8List ? rawBody : Uint8List(0);

      final rawIsRedirect = response['isRedirect'];
      final isRedirect = rawIsRedirect is bool ? rawIsRedirect : false;

      return ResponseBody.fromBytes(
        body,
        statusCode,
        headers: responseHeaders,
        statusMessage: statusMessage,
        isRedirect: isRedirect,
      );
    } on PlatformException catch (e) {
      requestCompleted = true;
      throw DioException(
        requestOptions: options,
        type: .connectionError,
        message: e.message,
      );
    } catch (e) {
      requestCompleted = true;
      rethrow;
    }
  }

  @override
  void close({bool force = false}) {
    // HttpURLConnection has no persistent connections to close
  }
}
