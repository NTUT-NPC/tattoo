import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/services/i_school_plus/i_school_plus_service.dart';
import 'package:tattoo/services/portal/ntut_portal_service.dart';
import 'package:tattoo/services/portal/portal_service.dart';

void main() {
  group('NtutPortalService SSO ISchoolPlus VPN Handling', () {
    test(
      'sso throws ISchoolPlusVpnRequiredException when iStudy connection fails',
      () async {
        final dio = Dio()
          ..httpClientAdapter = _SsoFailingAdapter(
            serviceCode: PortalServiceCode.iSchoolPlusService.code,
          );

        final portalService = NtutPortalService(dio: dio);

        expect(
          () => portalService.sso(PortalServiceCode.iSchoolPlusService.code),
          throwsA(isA<ISchoolPlusVpnRequiredException>()),
        );
      },
    );

    test(
      'getSsoUrl throws ISchoolPlusVpnRequiredException when iStudy connection fails',
      () async {
        final dio = Dio()
          ..httpClientAdapter = _SsoFailingAdapter(
            serviceCode: PortalServiceCode.iSchoolPlusService.code,
          );

        final portalService = NtutPortalService(dio: dio);

        expect(
          () => portalService.getSsoUrl(
            PortalServiceCode.iSchoolPlusService.code,
          ),
          throwsA(isA<ISchoolPlusVpnRequiredException>()),
        );
      },
    );
  });
}

class _SsoFailingAdapter implements HttpClientAdapter {
  final String serviceCode;

  _SsoFailingAdapter({required this.serviceCode});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    // 1. Return valid SSO form for ssoIndex.do
    if (options.path.contains('ssoIndex.do')) {
      const html = '''
<html>
  <body>
    <form name="ssoForm" action="https://istudy.ntut.edu.tw/oauth/login" method="POST">
      <input type="hidden" name="token" value="abc123xyz" />
    </form>
  </body>
</html>
''';
      return ResponseBody.fromString(
        html,
        200,
        headers: {
          Headers.contentTypeHeader: ['text/html'],
        },
      );
    }

    // 2. Post to istudy.ntut.edu.tw fails with connection error (VPN required)
    if (options.uri.host.contains('istudy.ntut.edu.tw')) {
      throw DioException(
        requestOptions: options,
        error: const SocketException('Connection refused / VPN required'),
        type: DioExceptionType.connectionError,
      );
    }

    throw DioException(
      requestOptions: options,
      error: 'Unexpected request: ${options.uri}',
      type: DioExceptionType.unknown,
    );
  }

  @override
  void close({bool force = false}) {}
}
