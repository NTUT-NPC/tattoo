import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:html/parser.dart';
import 'package:tattoo/models/user.dart';
import 'package:tattoo/utils/http.dart';

// Identification codes for NTUT services used in SSO
enum PortalServiceCode {
  scoreService('aa_003_LB_oauth'),
  courseService('aa_0010-oauth'),
  iSchoolPlusService('ischool_plus_oauth');

  final String code;
  const PortalServiceCode(this.code);
}

class PortalClient {
  late final Dio _ntutAppDio;

  PortalClient() {
    // Emulate the NTUT iOS app's HTTP client
    _ntutAppDio = createDio()
      ..options.baseUrl = 'https://app.ntut.edu.tw/'
      ..options.headers = {'User-Agent': 'Direk ios App'};
  }

  // Sets the JSESSIONID cookie in app.ntut.edu.tw domain
  Future<User> login(String username, String password) async {
    final response = await _ntutAppDio.post(
      'login.do',
      queryParameters: {'muid': username, 'mpassword': password},
    );

    if (!await isLoggedIn()) {
      throw Exception('Login failed. Please check your credentials.');
    }

    final body = jsonDecode(response.data);
    return User(
      name: body['givenName'],
      avatarFilename: body['userPhoto'],
      email: body['userMail'],
      isPasswordExpired: body['passwordExpiredRemind'] != null,
    );
  }

  Future<bool> isLoggedIn() async {
    final response = await _ntutAppDio.get('sessionCheckApp.do');
    final body = jsonDecode(response.data);
    return body["success"] == true;
  }

  Future<Uint8List> getAvatar(String filename) async {
    final response = await _ntutAppDio.get(
      'photoView.do',
      queryParameters: {'realname': filename},
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data;
  }

  // Perform SSO and set cookies for the target service
  Future<void> sso(PortalServiceCode serviceCode) async {
    // Fetch a self-submitting SSO form
    final response = await _ntutAppDio.get(
      'ssoIndex.do',
      queryParameters: {'apOu': serviceCode.code},
    );

    // Parse the HTML to extract the form
    final document = parse(response.data);
    final form = document.querySelector('form[name="ssoForm"]');
    if (form == null) {
      throw Exception('SSO form not found. Are you logged in?');
    }

    // Extract form action and inputs
    final actionUrl = form.attributes['action']!;
    final inputs = form.querySelectorAll('input');
    final formData = <String, dynamic>{
      for (final input in inputs)
        if (input.attributes['name'] != null)
          input.attributes['name']!: input.attributes['value'] ?? '',
    };

    // Prepend the invalid cookie filter interceptor for i-School Plus SSO
    if (serviceCode == PortalServiceCode.iSchoolPlusService) {
      _ntutAppDio.interceptors.insert(0, InvalidCookieFilter());
    }

    // Submit the SSO form and follow redirects
    // Sets the necessary cookies for the target service
    await _ntutAppDio.post(
      actionUrl,
      data: formData,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }
}
