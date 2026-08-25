import 'package:dio/dio.dart';
import 'package:tattoo/utils/network_error_stub.dart'
    if (dart.library.io) 'package:tattoo/utils/network_error_io.dart';

/// Determines whether an error is a network-related failure.
bool isNetworkError(Object error) {
  if (error is DioException) return true;
  return isNativeNetworkError(error);
}
