import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/services/portal/ntut_portal_service.dart';
import 'package:tattoo/services/portal/portal_service.dart';

void main() {
  test(
    'iSchool SSO cancels stalled HTTP and allows the next attempt',
    () async {
      final requested = Completer<CancelToken>();
      var stall = true;
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              if (stall) {
                requested.complete(options.cancelToken!);
                final error = await options.cancelToken!.whenCancel;
                handler.reject(error);
                return;
              }
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: options.path == 'ssoIndex.do'
                      ? '<form name="ssoForm" action="oauth2Server.do"></form>'
                      : '',
                ),
              );
            },
          ),
        );
      final service = NtutPortalService(dio: dio);
      final failure = expectLater(
        service.sso(PortalServiceCode.iSchoolPlusService.code),
        throwsA(
          isA<DioException>().having(
            (e) => e.type == .cancel,
            'is cancelled',
            isTrue,
          ),
        ),
      );
      final token = await requested.future;
      await failure;
      expect(token.isCancelled, isTrue);

      stall = false;
      await service.sso(PortalServiceCode.iSchoolPlusService.code);
    },
  );
}
