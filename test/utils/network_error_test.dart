import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/services/i_school_plus/i_school_plus_service.dart';
import 'package:tattoo/utils/network_error.dart';
import 'package:tattoo/utils/network_error_stub.dart' as stub;

void main() {
  group('isNetworkError', () {
    test('identifies DioException as network error', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: 'https://example.com'),
      );
      expect(isNetworkError(dioError), isTrue);
    });

    test('identifies SocketException as network error', () {
      expect(
        isNetworkError(const SocketException('Failed host lookup')),
        isTrue,
      );
    });

    test('identifies HttpException as network error', () {
      expect(isNetworkError(const HttpException('Connection closed')), isTrue);
    });

    test('identifies HandshakeException as network error', () {
      expect(
        isNetworkError(const HandshakeException('Handshake error')),
        isTrue,
      );
    });

    test('identifies TlsException as network error', () {
      expect(isNetworkError(const TlsException('TLS error')), isTrue);
    });

    test('returns false for generic and unexpected errors', () {
      expect(isNetworkError(Exception('something failed')), isFalse);
      expect(isNetworkError(StateError('invalid state')), isFalse);
      expect(isNetworkError(FormatException('invalid format')), isFalse);
      expect(isNetworkError('error string'), isFalse);
    });
  });

  group('isISchoolPlusConnectionError', () {
    test('identifies ISchoolPlusVpnRequiredException', () {
      expect(
        isISchoolPlusConnectionError(const ISchoolPlusVpnRequiredException()),
        isTrue,
      );
    });

    test(
      'identifies DioException wrapping ISchoolPlusVpnRequiredException',
      () {
        final dioError = DioException(
          requestOptions: RequestOptions(path: 'https://example.com'),
          error: const ISchoolPlusVpnRequiredException(),
        );
        expect(isISchoolPlusConnectionError(dioError), isTrue);
      },
    );

    test('identifies DioException targeting istudy.ntut.edu.tw', () {
      final dioError = DioException(
        requestOptions: RequestOptions(
          path: 'https://istudy.ntut.edu.tw/learn/mooc_sysbar.php',
        ),
        type: DioExceptionType.connectionTimeout,
      );
      expect(isISchoolPlusConnectionError(dioError), isTrue);
    });

    test('returns false for DioException targeting other hosts', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: 'https://example.com/test'),
        type: DioExceptionType.connectionTimeout,
      );
      expect(isISchoolPlusConnectionError(dioError), isFalse);
    });

    test('returns false for generic errors', () {
      expect(
        isISchoolPlusConnectionError(Exception('something failed')),
        isFalse,
      );
      expect(
        isISchoolPlusConnectionError(const SocketException('err')),
        isFalse,
      );
    });
  });

  group('network_error_stub', () {
    test('isNativeNetworkError returns false on stub platform', () {
      expect(stub.isNativeNetworkError(Exception('something failed')), isFalse);
    });
  });
}
