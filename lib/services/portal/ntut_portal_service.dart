import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';

import 'package:dio_redirect_interceptor/dio_redirect_interceptor.dart';
import 'package:html/parser.dart';
import 'package:http_parser/http_parser.dart';
import 'package:tattoo/models/login_exception.dart';
import 'package:tattoo/services/portal/portal_service.dart';
import 'package:tattoo/utils/http.dart';

class NtutPortalService implements PortalService {
  late final Dio _portalDio;

  NtutPortalService() {
    // Emulate the NTUT iOS app's HTTP client
    _portalDio = createDio()
      ..options.baseUrl = 'https://app.ntut.edu.tw/'
      ..options.headers = {
        'User-Agent': 'Direk ios App',
        // Prevent keep-alive connection reuse — NTUT servers close their end
        // after multipart uploads, causing stale connection errors.
        'Connection': 'close',
      };
  }

  @override
  Future<UserDto> login(String username, String password) async {
    final response = await _portalDio.post(
      'login.do',
      queryParameters: {'muid': username, 'mpassword': password},
    );

    final body = jsonDecode(response.data);
    if (!body['success']) {
      final String? errorMsg = body['errorMsg'];
      final bool resetPwd = body['resetPwd'] ?? false;
      throw LoginException(
        switch (errorMsg) {
          final msg? when msg.contains('密碼錯誤') => .wrongCredentials,
          final msg? when msg.contains('已被鎖住') => .accountLocked,
          final msg? when msg.contains('密碼已過期') && resetPwd => .passwordExpired,
          final msg? when msg.contains('驗證手機') => .mobileVerificationRequired,
          _ => .unknown,
        },
        message: errorMsg?.isNotEmpty == true ? errorMsg : null,
      );
    }

    final String? passwordExpiredRemind = body['passwordExpiredRemind'];

    // Normalize empty strings to null for consistency
    String? normalizeEmpty(String? value) =>
        value?.isNotEmpty == true ? value : null;

    return (
      name: normalizeEmpty(body['givenName']),
      avatarFilename: normalizeEmpty(body['userPhoto']),
      email: normalizeEmpty(body['userMail']),
      passwordExpiresInDays: passwordExpiredRemind != null
          ? int.tryParse(passwordExpiredRemind)
          : null,
    );
  }

  @override
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final response = await _portalDio.post(
      'passwordMdy.do',
      queryParameters: {
        "oldPassword": currentPassword,
        "userPassword": newPassword,
        "pwdForceMdy": "profile",
      },
    );

    final body = jsonDecode(response.data);

    // API returns "success": "false" on failure (note the string "false")
    if (body['success'] != true) {
      throw Exception(
        body['returnMsg'] ?? 'Password change failed. Please try again.',
      );
    }
  }

  @override
  Future<Uint8List> getAvatar([String? filename]) async {
    final response = await _portalDio.get(
      'photoView.do',
      queryParameters: {'realname': filename ?? ''},
      options: Options(responseType: ResponseType.bytes),
    );

    final contentType = response.headers.value('content-type') ?? '';
    final mediaType = MediaType.parse(contentType);
    if (mediaType.type != 'image') {
      throw FormatException(
        'Expected image response, got Content-Type: $contentType',
      );
    }

    return response.data;
  }

  @override
  Future<String> uploadAvatar(Uint8List imageBytes, String? oldFilename) async {
    final response = await _portalDio.post(
      'photoUpload.do',
      queryParameters: {
        'uploadQuota': '20', // max file size in MB
        // current avatar filename for server-side cleanup
        'ldapPhoto': oldFilename ?? '',
      },
      data: FormData.fromMap({
        'file[]': MultipartFile.fromBytes(
          imageBytes,
          filename: 'avatar.jpg', // required by server
          contentType: DioMediaType('application', 'octet-stream'),
        ),
      }),
    );

    final body = jsonDecode(response.data);
    return body['ldapPhoto'];
  }

  @override
  Future<void> sso(String serviceCode) async {
    final (actionUrl, formData) = await _fetchSsoForm(serviceCode);

    // Prepend the invalid cookie filter interceptor for i-School Plus SSO
    if (serviceCode == PortalServiceCode.iSchoolPlusService.code) {
      _portalDio.interceptors.insert(0, InvalidCookieFilter());
      _portalDio.transformer = PlainTextTransformer();
    }

    // Submit the SSO form and follow redirects
    // Sets the necessary cookies for the target service
    await _portalDio.post(
      actionUrl,
      data: formData,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }

  @override
  Future<Uri> getSsoUrl(String serviceCode) async {
    final (actionUrl, formData) = await _fetchSsoForm(serviceCode);

    // Clone and strip RedirectInterceptor so we can capture the 302 Location
    // instead of following it.
    final dioWithoutRedirects = _portalDio.clone()
      ..interceptors.removeWhere(
        (interceptor) => interceptor is RedirectInterceptor,
      );

    final response = await dioWithoutRedirects.post(
      actionUrl,
      data: formData,
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        followRedirects: false,
        validateStatus: (status) => status != null && status < 400,
      ),
    );

    final location = response.headers.value('location');
    if (location == null) {
      throw Exception('SSO redirect not received. Are you logged in?');
    }

    // The portal may return http:// URLs; upgrade to https://
    var uri = Uri.parse(location);
    if (uri.scheme == 'http') {
      uri = uri.replace(scheme: 'https');
    }
    return uri;
  }

  /// Fetches and parses the SSO form for a given apOu code.
  ///
  /// Returns (actionUrl, formData) for submitting the form.
  Future<(String, Map<String, dynamic>)> _fetchSsoForm(String apOu) async {
    final response = await _portalDio.get(
      'ssoIndex.do',
      queryParameters: {'apOu': apOu},
    );

    final document = parse(response.data);
    final form = document.querySelector('form[name="ssoForm"]');
    if (form == null) {
      throw Exception('SSO form not found. Are you logged in?');
    }

    final actionUrl = form.attributes['action']!;
    final inputs = form.querySelectorAll('input');
    final formData = <String, dynamic>{
      for (final input in inputs)
        if (input.attributes['name'] != null)
          input.attributes['name']!: input.attributes['value'] ?? '',
    };

    return (actionUrl, formData);
  }

  @override
  Future<List<CalendarEventDto>> getCalendar(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final formatter = DateFormat('yyyy/MM/dd');
    final response = await _portalDio.get(
      'calModeApp.do',
      queryParameters: {
        'startDate': formatter.format(startDate),
        'endDate': formatter.format(endDate),
      },
    );

    final List<dynamic> events = jsonDecode(response.data);
    String? normalizeEmpty(String? value) =>
        value?.isNotEmpty == true ? value : null;
    DateTime? fromEpoch(int? ms) =>
        ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;

    return events
        .where(
          // Filter out weekend markers
          (e) => e['isHoliday'] != '1',
        )
        .map<CalendarEventDto>(
          (e) => (
            id: switch (e['id']) {
              final int i => i,
              final String s => int.tryParse(s),
              _ => null,
            },
            start: fromEpoch(e['calStart']),
            end: fromEpoch(e['calEnd']),
            allDay: e['allDay'] == '1',
            title: normalizeEmpty(e['calTitle']),
            place: normalizeEmpty(e['calPlace']),
            content: normalizeEmpty(e['calContent']),
            ownerName: normalizeEmpty(e['ownerName']),
            creatorName: normalizeEmpty(e['creatorName']),
          ),
        )
        .toList();
  }
}
