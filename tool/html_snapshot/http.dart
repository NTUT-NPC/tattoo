part of '../html_snapshot.dart';

CookieJar? _snapshotCookieJar;

CookieJar get _cookieJar => _snapshotCookieJar ??= CookieJar();

Dio _createDio(SnapshotService service, {required bool verbose}) {
  final dio = Dio()
    ..options = BaseOptions(
      baseUrl: service.baseUrl,
      validateStatus: (status) => status != null && status < 400,
      followRedirects: false,
    );

  if (service == .portal) {
    dio.options.headers = {
      'User-Agent': 'Direk ios App',
      'Connection': 'close',
    };
  }

  dio.interceptors.addAll([
    CookieManager(_cookieJar),
    _NullHeaderInterceptor(),
    _ClientIdentifierInterceptor(),
    _HttpsInterceptor(),
    RedirectInterceptor(() => dio),
    if (verbose) _SnapshotLogInterceptor(),
  ]);

  if (service == .ischool) {
    dio.interceptors.insert(0, _InvalidCookieFilter());
    dio.transformer = _PlainTextTransformer();
  }

  if (service == .course) {
    dio.interceptors.add(CourseSessionCheckInterceptor());
  } else if (service == .studentQuery) {
    dio.interceptors.add(StudentQuerySessionCheckInterceptor());
  } else if (service == .ischool) {
    dio.interceptors.add(ISchoolSessionCheckInterceptor());
  }

  return dio;
}

class _HttpsInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.uri.scheme == 'http') {
      options.path = options.uri.replace(scheme: 'https').toString();
    }
    handler.next(options);
  }
}

class _InvalidCookieFilter extends Interceptor {
  static final _setCookieReg = RegExp(r',(?=[^;,]+?=)');

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final setCookieHeaders = response.headers[HttpHeaders.setCookieHeader];
    if (setCookieHeaders == null || setCookieHeaders.isEmpty) {
      handler.next(response);
      return;
    }

    final validCookies = <String>[];
    for (final cookie in setCookieHeaders.expand(
      (header) => header.split(_setCookieReg),
    )) {
      if (cookie.isEmpty) continue;
      final trimmed = cookie.trimLeft();
      try {
        Cookie.fromSetCookieValue(trimmed);
        validCookies.add(trimmed);
      } on FormatException {
        log('Filtered invalid Set-Cookie header: $trimmed', name: 'HTTP');
      }
    }
    response.headers.set(HttpHeaders.setCookieHeader, validCookies);

    handler.next(response);
  }
}

class _PlainTextTransformer extends BackgroundTransformer {
  @override
  Future transformResponse(
    RequestOptions options,
    ResponseBody responseBody,
  ) async {
    if (options.responseType == .stream) {
      return responseBody;
    }

    final responseBytes = await consolidateBytes(responseBody.stream);
    if (options.responseType == .bytes) {
      return responseBytes;
    }

    return utf8.decode(responseBytes, allowMalformed: true);
  }
}

class _ClientIdentifierInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['X-Client'] =
        'f39e5855ffb05dd0030e6cdd6b7b27f45303aa96dd5439f5021171b714afd755';
    handler.next(options);
  }
}

class _NullHeaderInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.removeWhere(
      (_, value) => value == null || value.toString() == 'null',
    );
    handler.next(options);
  }
}

class _SnapshotLogInterceptor extends Interceptor {
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
      if (requestBodyLength case final length?) '${_compactFormat(length)}B',
    ].join(' ');
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
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
      ?response.statusCode,
      ?contentType,
      if (responseBodyLength case final length?) '${_compactFormat(length)}B',
      if (cookies case final count? when count > 0)
        "$count cookie${count != 1 ? 's' : ''}",
    ].join(' ');

    stderr.writeln(
      '[HTTP] ${_requestLog(response.requestOptions)} => $responseLog',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final errorLog = [
      err.type.name,
      ?err.response?.statusCode,
    ].join(' ');
    stderr.writeln('[HTTP] ${_requestLog(err.requestOptions)} => $errorLog');
    handler.next(err);
  }
}
