const kioskLoginServiceCode = 'per_001_oauth';
const kioskLoginHost = 'ntut.app';
const kioskLoginPath = '/login';

Uri buildKioskLoginUri(Uri ssoUrl) {
  final authCode =
      ssoUrl.queryParameters['code'] ?? ssoUrl.queryParameters['amp;code'];
  if (authCode == null || authCode.isEmpty) {
    throw const FormatException('SSO URL does not contain an auth code');
  }

  return Uri.https(kioskLoginHost, kioskLoginPath, {'code': authCode});
}
