import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:tattoo/utils/http.dart';

/// Adapts Dio for libraries that require an [http.Client].
class DioHttpClient extends http.BaseClient {
  /// Creates a client that closes [dio] when [close] is called.
  DioHttpClient(Dio dio) : _dio = dio;

  final Dio _dio;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final cancelToken = CancelToken();
    if (request case http.Abortable(:final abortTrigger?)) {
      unawaited(abortTrigger.then((_) => cancelToken.cancel()));
    }
    final body = request.finalize();
    try {
      final response = await _dio.requestUri<List<int>>(
        request.url,
        data: request.contentLength == 0 ? null : body,
        options: Options(
          method: request.method,
          headers: request.headers,
          responseType: .bytes,
        ),
        cancelToken: cancelToken,
      );
      return http.StreamedResponse(
        Stream.value(response.data ?? const []),
        response.statusCode!,
        request: request,
        headers: {
          for (final entry in response.headers.map.entries)
            entry.key: entry.value.join(','),
        },
        contentLength: response.data?.length,
        reasonPhrase: response.statusMessage,
        isRedirect: response.isRedirect,
      );
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) {
        throw http.RequestAbortedException(request.url);
      }
      throw http.ClientException(
        error.message ?? error.toString(),
        request.url,
      );
    }
  }

  @override
  void close() => _dio.close(force: true);
}
