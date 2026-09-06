import 'package:dio/dio.dart';
import 'package:tattoo/services/i_school_plus/i_school_plus_service.dart';
import 'package:tattoo/utils/network_error_stub.dart'
    if (dart.library.io) 'package:tattoo/utils/network_error_io.dart';

/// Determines whether an error is a network-related failure.
bool isNetworkError(Object error) {
  if (error is DioException) return true;
  return isNativeNetworkError(error);
}

/// Determines whether an error is caused by iSchool+ / iStudy connection
/// failure (e.g. unreachable due to campus VPN requirement).
bool isISchoolPlusConnectionError(Object error) {
  if (error is ISchoolPlusVpnRequiredException) return true;
  if (error is DioException) {
    if (error.error is ISchoolPlusVpnRequiredException) return true;
    final uri = error.requestOptions.uri;
    if (uri.host.contains('istudy.ntut.edu.tw') && isNetworkError(error)) {
      return true;
    }
  }
  return false;
}
