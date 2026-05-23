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

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    // Collect request body stream into bytes
    Uint8List? bodyBytes;
    if (requestStream != null) {
      final chunks = <List<int>>[];
      var totalLength = 0;
      await for (final chunk in requestStream) {
        chunks.add(chunk);
        totalLength += chunk.length;
      }
      if (totalLength > 0) {
        final builder = BytesBuilder(copy: false);
        for (final chunk in chunks) {
          builder.add(chunk);
        }
        bodyBytes = builder.takeBytes();
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

    try {
      final result = await _channel.invokeMethod<Map>('fetch', {
        'url': options.uri.toString(),
        'method': options.method,
        'headers': headers,
        'body': bodyBytes,
        'followRedirects': options.followRedirects,
        'connectTimeout': options.connectTimeout?.inMilliseconds,
        'readTimeout': options.receiveTimeout?.inMilliseconds,
      });

      final response = Map<String, dynamic>.from(result!);
      final statusCode = response['statusCode'] as int;
      final statusMessage = response['statusMessage'] as String?;

      final responseHeaders = <String, List<String>>{};
      final rawHeaders = response['headers'] as Map?;
      if (rawHeaders != null) {
        rawHeaders.forEach((key, value) {
          if (value is List) {
            responseHeaders[key.toString()] = value
                .map((e) => e.toString())
                .toList();
          }
        });
      }

      final body = response['body'] as Uint8List? ?? Uint8List(0);
      final isRedirect = response['isRedirect'] as bool? ?? false;

      return ResponseBody.fromBytes(
        body,
        statusCode,
        headers: responseHeaders,
        statusMessage: statusMessage,
        isRedirect: isRedirect,
      );
    } on PlatformException catch (e) {
      throw DioException(
        requestOptions: options,
        type: .connectionError,
        message: e.message,
      );
    }
  }

  @override
  void close({bool force = false}) {
    // HttpURLConnection has no persistent connections to close
  }
}
