import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_redirect_interceptor/dio_redirect_interceptor.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';

// Interceptor to convert HTTP requests to HTTPS
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

/// Interceptor to filter out invalid Set-Cookie headers from responses.
///
/// The i-School Plus service sets cookies with invalid names, causing parsing errors.
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
        debugPrint('Filtered invalid Set-Cookie header: $header');
      }
    }
    response.headers.set(HttpHeaders.setCookieHeader, validCookies);

    handler.next(response);
  }
}

// Shared CookieJar instance for maintaining session across clients
CookieJar? _cookieJar;
CookieJar get cookieJar => _cookieJar ??= CookieJar();

// Creates a new Dio instance with configured interceptors
// Cookies are shared via the global CookieJar
Dio createDio() {
  final dio = Dio()
    ..options = BaseOptions(
      validateStatus: (status) => status != null && status < 400,
      followRedirects: false,
    );

  dio.interceptors.addAll([
    InvalidCookieFilter(), // Filter invalid Set-Cookie headers
    CookieManager(cookieJar), // Store cookies
    HttpsInterceptor(), // Enforce HTTPS
    RedirectInterceptor(() => dio), // Handle redirects within this Dio instance
    LogInterceptor(
      logPrint: (o) => debugPrint(o.toString()),
    ), // Log requests and responses
  ]);

  return dio;
}
