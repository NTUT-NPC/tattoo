import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_redirect_interceptor/dio_redirect_interceptor.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:intl/intl.dart';
// ignore: implementation_imports
import 'package:dio/src/transformers/util/consolidate_bytes.dart';
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
    if (options.responseType == ResponseType.stream) {
      return responseBody;
    }

    final responseBytes = await consolidateBytes(responseBody.stream);

    if (options.responseType == ResponseType.bytes) {
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
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final compactFormat = NumberFormat.compact().format;

    final method = response.requestOptions.method;
    final uri = response.requestOptions.uri;
    final parameters = response.requestOptions.queryParameters.length;
    final requestBodyLength = switch (response.requestOptions.data) {
      String s => s.length,
      List l => l.length,
      FormData f => f.length,
      Map m => m.length,
      _ => null,
    };

    final requestLog = [
      method,
      "${uri.origin}${uri.path}",
      if (parameters > 0) "$parameters param${parameters != 1 ? 's' : ''}",
      if (requestBodyLength case final l?) "${compactFormat(l)}B",
    ].join(' ');

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
      if (responseBodyLength case final l?) '${compactFormat(l)}B',
      if (cookies case final c? when c > 0) "$c cookie${c != 1 ? 's' : ''}",
    ].join(' ');

    final message = "$requestLog => $responseLog";
    log(message, name: 'HTTP');
    firebaseService.log(message);
    handler.next(response);
  }
}

CookieJar? _cookieJar;

/// Shared CookieJar instance for maintaining session across clients.
CookieJar get cookieJar => _cookieJar ??= CookieJar();

/// Creates a new Dio instance with configured interceptors.
///
/// To debug with a self-signed certificate, pass
/// --dart-define=ALLOW_BAD_CERTIFICATES=true to flutter run.
///
/// Cookies are shared across all clients via the global [cookieJar].
Dio createDio() {
  final dio = Dio()
    ..options = BaseOptions(
      validateStatus: (status) => status != null && status < 400,
      followRedirects: false,
    );

  const allowBadCertificates = bool.fromEnvironment('ALLOW_BAD_CERTIFICATES');
  if (allowBadCertificates) {
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () => HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true,
    );
  }

  dio.interceptors.addAll([
    CookieManager(cookieJar), // Store cookies
    HttpsInterceptor(), // Enforce HTTPS
    RedirectInterceptor(() => dio), // Handle redirects within this Dio instance
    LogInterceptor(), // Log requests and responses
  ]);

  return dio;
}
