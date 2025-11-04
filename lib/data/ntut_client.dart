import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:html/parser.dart';
import 'package:tattoo/utils/http.dart';

// Identification codes for NTUT services used in SSO
enum NtutServiceCode {
  scoreService('aa_003_LB_oauth'),
  courseService('aa_0010-oauth'),
  iSchoolPlusService('ischool_plus_oauth');

  final String code;
  const NtutServiceCode(this.code);
}

class NtutClient {
  late final Dio _ntutAppDio;

  NtutClient() {
    // Emulate the NTUT iOS app's HTTP client
    _ntutAppDio = dio.clone()
      ..options.baseUrl = 'https://app.ntut.edu.tw'
      ..options.headers = {'User-Agent': 'Direk ios App'};
  }

  // Sets the JSESSIONID cookie in app.ntut.edu.tw domain
  Future<void> login(String username, String password) async {
    await _ntutAppDio.post(
      '/login.do',
      queryParameters: {'muid': username, 'mpassword': password},
    );

    if (!await isLoggedIn()) {
      throw Exception('Login failed. Please check your credentials.');
    }
  }

  Future<bool> isLoggedIn() async {
    final response = await _ntutAppDio.get('/sessionCheckApp.do');
    final body = jsonDecode(response.data);
    return body["success"] == true;
  }

  // Perform SSO and set cookies for the target service
  Future<void> sso(NtutServiceCode serviceCode) async {
    // Fetch a self-submitting SSO form
    final response = await _ntutAppDio.get(
      '/ssoIndex.do',
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

    // Submit the SSO form and follow redirects
    // Sets the necessary cookies for the target service
    await _ntutAppDio.post(
      '/$actionUrl',
      data: formData,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }
}
