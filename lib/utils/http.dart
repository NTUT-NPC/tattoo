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

export 'package:dio/dio.dart';

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
class LogInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final method = response.requestOptions.method;
    final uri = response.requestOptions.uri;
    final parameters = response.requestOptions.queryParameters.length;
    final bodyLength = response.requestOptions.data?.length;

    final requestLog = [
      method,
      "${uri.origin}${uri.path}",
      if (parameters > 0) "$parameters param${parameters != 1 ? 's' : ''}",
      if (bodyLength is int)
        "${NumberFormat.compact().format(bodyLength)}B body",
    ].join(' ');

    final statusCode = response.statusCode;
    final contentType = response.headers
        .value(HttpHeaders.contentTypeHeader)
        ?.split(';')
        .first;
    final contentLength =
        int.tryParse(
          response.headers.value(HttpHeaders.contentLengthHeader) ?? '',
        ) ??
        response.data.length ??
        0;
    final cookies = response.headers[HttpHeaders.setCookieHeader]?.length ?? 0;

    final responseLog = [
      statusCode,
      if (contentType != null) contentType,
      if (contentLength > 0) '${NumberFormat.compact().format(contentLength)}B',
      if (cookies > 0) "$cookies cookie${cookies != 1 ? 's' : ''}",
    ].join(' ');

    log("$requestLog => $responseLog", name: 'HTTP');
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
