import 'dart:convert';
import 'dart:typed_data';

import 'package:html/parser.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tattoo/utils/http.dart';

/// Represents a logged-in NTUT Portal user.
typedef UserDto = ({
  /// User's display name from NTUT Portal (givenName).
  String? name,

  /// Filename of the user's profile photo (e.g., "111360109_temp1714460935341.jpeg").
  String? avatarFilename,

  /// User's NTUT email address (e.g., "t111360109@ntut.edu.tw").
  String? email,

  /// Number of days until the password expires.
  ///
  /// When non-null, indicates the user should change their password soon.
  /// The value corresponds to the `passwordExpiredRemind` field from the login API.
  /// Null if there is no expiration warning.
  int? passwordExpiresInDays,
});

/// Identification codes for NTUT services used in SSO authentication.
///
/// These codes are passed to [PortalService.sso] to authenticate with
/// different NTUT web services.
enum PortalServiceCode {
  studentQueryService('sa_003_oauth'),
  courseService('aa_0010-oauth'),
  iSchoolPlusService('ischool_plus_oauth');

  final String code;
  const PortalServiceCode(this.code);
}

/// Provides the singleton [PortalService] instance.
final portalServiceProvider = Provider<PortalService>((ref) => PortalService());

/// Service for authenticating with NTUT Portal and performing SSO.
///
/// This service handles:
/// - User authentication (login/logout)
/// - Session management
/// - Single sign-on (SSO) to other NTUT services
/// - User profile and avatar retrieval
///
/// All HTTP clients in the application share a single cookie jar, so logging in
/// through this service provides authentication for all other services after
/// calling [sso] for each required service.
class PortalService {
  late final Dio _portalDio;

  PortalService() {
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

  /// Authenticates a user with NTUT Portal credentials.
  ///
  /// Sets the JSESSIONID cookie in the app.ntut.edu.tw domain for subsequent
  /// authenticated requests. This session cookie is shared across all services.
  ///
  /// Returns user profile information including name, email, and avatar filename.
  ///
  /// Throws an [Exception] if login fails due to invalid credentials.
  Future<UserDto> login(String username, String password) async {
    final response = await _portalDio.post(
      'login.do',
      queryParameters: {'muid': username, 'mpassword': password},
    );

    final body = jsonDecode(response.data);
    if (!body['success']) {
      throw Exception('Login failed. Please check your credentials.');
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

  /// Changes the user's NTUT Portal password.
  ///
  /// Requires an active session (call [login] first).
  ///
  /// Throws an [Exception] if the password change fails (e.g., incorrect
  /// current password or the new password doesn't meet requirements).
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

  /// Downloads a user's avatar from NTUT Portal.
  ///
  /// If [filename] is omitted or empty, the server returns a dynamically
  /// generated placeholder avatar (a colored square with the user's name).
  ///
  /// Returns the avatar image as raw bytes.
  Future<Uint8List> getAvatar([String? filename]) async {
    final response = await _portalDio.get(
      'photoView.do',
      queryParameters: {'realname': filename ?? ''},
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data;
  }

  /// Uploads a new profile photo to NTUT Portal, replacing the current one.
  ///
  /// [oldFilename] should be the current avatar filename
  /// (from [UserDto.avatarFilename], or empty string if none).
  ///
  /// Returns the new avatar filename assigned by the server.
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

  /// Performs single sign-on (SSO) to authenticate with a target NTUT service.
  ///
  /// This method must be called after [login] to obtain session cookies for
  /// other NTUT services (Course Service, Score Service, or I-School Plus).
  ///
  /// The SSO process:
  /// 1. Fetches an SSO form from Portal with the service code
  /// 2. Submits the form to the target service
  /// 3. Sets the necessary authentication cookies for that service
  ///
  /// All services share the same cookie jar, so SSO only needs to be called once
  /// per service during a session.
  ///
  /// Throws an [Exception] if the SSO form is not found (user may not be logged in).
  Future<void> sso(PortalServiceCode serviceCode) async {
    // Fetch a self-submitting SSO form
    final response = await _portalDio.get(
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
}
