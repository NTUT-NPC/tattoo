import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio/src/transformers/util/consolidate_bytes.dart'; // ignore: implementation_imports
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:dio_redirect_interceptor/dio_redirect_interceptor.dart';
import 'package:intl/intl.dart';
import 'package:native_dio_adapter/native_dio_adapter.dart';
import 'package:tattoo/services/firebase_service.dart';

export 'package:dio/dio.dart';

/// Thrown when an NTUT service returns a success response but the content
/// indicates the session has expired (e.g., a redirect page instead of data).
///
/// This is a non-[DioException] so that [AuthRepository.withAuth] catches it
/// and retries with re-authentication.
class SessionExpiredException implements Exception {
  final String message;
  const SessionExpiredException(this.message);

  @override
  String toString() => 'SessionExpiredException: $message';
}

/// [Interceptor] to convert HTTP requests to HTTPS.
class HttpsInterceptor extends Interceptor {
  HttpsInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.uri.scheme == 'http') {
      final httpsUri = options.uri.replace(scheme: 'https');
      options.path = httpsUri.toString();
    }
    handler.next(options);
  }
}

/// [Interceptor] to filter out invalid Set-Cookie headers from responses.
///
/// [ISchoolPlusService] sets cookies with invalid names, causing parsing errors.
class InvalidCookieFilter extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final setCookieHeaders = response.headers[HttpHeaders.setCookieHeader];
    if (setCookieHeaders == null || setCookieHeaders.isEmpty) {
      handler.next(response);
      return;
    }

    final validCookies = <String>[];
    for (final header in setCookieHeaders) {
      try {
        Cookie.fromSetCookieValue(header);
        validCookies.add(header);
      } on FormatException {
        // Ignore invalid cookie
        log('Filtered invalid Set-Cookie header: $header', name: 'HTTP');
      }
    }
    response.headers.set(HttpHeaders.setCookieHeader, validCookies);

    handler.next(response);
  }
}

/// Minimal [Transformer] that skips JSON parsing and Content-Type validation.
///
/// [ISchoolPlusService] return HTML/XML and send malformed Content-Type headers
/// like "text/html;;charset=UTF-8" which cause MediaType.parse() to fail.
/// This transformer bypasses all JSON/MIME type handling and returns raw strings.
class PlainTextTransformer extends BackgroundTransformer {
  @override
  Future transformResponse(
    RequestOptions options,
    ResponseBody responseBody,
  ) async {
    // Return streams and bytes as-is
    if (options.responseType == .stream) {
      return responseBody;
    }

    final responseBytes = await consolidateBytes(responseBody.stream);

    if (options.responseType == .bytes) {
      return responseBytes;
    }

    // Always decode as string, no JSON parsing
    return utf8.decode(responseBytes, allowMalformed: true);
  }
}

/// One-line log [Interceptor] for requests and responses.
///
/// Logs to both `dart:developer` and Firebase Crashlytics for breadcrumb
/// context in crash reports.
class LogInterceptor extends Interceptor {
  static final _compactFormat = NumberFormat.compact().format;

  static String _requestLog(RequestOptions options) {
    final parameters = options.queryParameters.length;
    final requestBodyLength = switch (options.data) {
      String s => s.length,
      List l => l.length,
      FormData f => f.length,
      Map m => m.length,
      _ => null,
    };
    return [
      options.method,
      '${options.uri.origin}${options.uri.path}',
      if (parameters > 0) "$parameters param${parameters != 1 ? 's' : ''}",
      if (requestBodyLength case final l?) '${_compactFormat(l)}B',
    ].join(' ');
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final requestLog = _requestLog(response.requestOptions);

    final statusCode = response.statusCode;
    final contentType = response.headers
        .value(HttpHeaders.contentTypeHeader)
        ?.split(';')
        .first;
    final contentLengthHeader = response.headers.value(
      HttpHeaders.contentLengthHeader,
    );
    final responseBodyLength =
        int.tryParse(contentLengthHeader ?? '') ??
        switch (response.data) {
          String s => s.length,
          List l => l.length,
          Map m => m.length,
          _ => null,
        };
    final cookies = response.headers[HttpHeaders.setCookieHeader]?.length;

    final responseLog = [
      statusCode,
      if (contentType case final t) t,
      if (responseBodyLength case final l?) '${_compactFormat(l)}B',
      if (cookies case final c? when c > 0) "$c cookie${c != 1 ? 's' : ''}",
    ].join(' ');

    final message = '$requestLog => $responseLog';
    log(message, name: 'HTTP');
    firebaseService.log(message);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final requestLog = _requestLog(err.requestOptions);
    final errorLog = [
      err.type.name,
      ?err.response?.statusCode,
    ].join(' ');

    final message = '$requestLog => $errorLog';
    log(message, name: 'HTTP');
    firebaseService.log(message);
    handler.next(err);
  }
}

CookieJar? _cookieJar;

/// Shared CookieJar instance for maintaining session across clients.
CookieJar get cookieJar => _cookieJar ??= CookieJar();

/// Strips null-valued headers that [CookieManager] injects.
///
/// `dio_cookie_manager` explicitly sets `Cookie: null` when no cookies exist
/// for a URL. Native HTTP adapters forward this as the literal header
/// `Cookie: null`, which NTUT's BigIP ASM flags as bot behavior (HTTP 403).
class NullHeaderInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.removeWhere(
      (_, value) => value == null || value.toString() == 'null',
    );
    handler.next(options);
  }
}

/// Creates a new Dio instance with configured interceptors.
///
/// On Android and iOS, HTTPS requests ride on the platform's native TLS stack
/// via [NativeAdapter] (Cronet on Android, URLSession on iOS). Campus Wi-Fi
/// has a TLS DPI that RSTs connections whose ClientHello fingerprint isn't on
/// its allowlist; dart:io's BoringSSL fails, but Cronet and URLSession pass.
///
/// Cookies are shared across all clients via the global [cookieJar].
Dio createDio() {
  final dio = Dio()
    ..options = BaseOptions(
      validateStatus: (status) => status != null && status < 400,
      followRedirects: false,
    );

  if (Platform.isAndroid || Platform.isIOS) {
    dio.httpClientAdapter = NativeAdapter(
      createCupertinoConfiguration: () =>
          URLSessionConfiguration.defaultSessionConfiguration()
            ..httpShouldSetCookies = false,
    );
  }

  dio.interceptors.addAll([
    CookieManager(cookieJar), // Store cookies
    NullHeaderInterceptor(), // Strip Cookie: null from dio_cookie_manager
    HttpsInterceptor(), // Enforce HTTPS
    RedirectInterceptor(() => dio), // Handle redirects within this Dio instance
    LogInterceptor(), // Log requests and responses
  ]);

  return dio;
}
