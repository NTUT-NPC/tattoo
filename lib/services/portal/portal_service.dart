import 'dart:typed_data';

import 'package:riverpod/riverpod.dart';
import 'package:tattoo/services/portal/ntut_portal_service.dart';

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

/// Represents a calendar event from the NTUT Portal.
///
/// Weekend markers (isHoliday with empty title) are filtered out by
/// [PortalService.getCalendar].
typedef CalendarEventDto = ({
  /// Event ID.
  int? id,

  /// Event start time.
  DateTime? start,

  /// Event end time.
  DateTime? end,

  /// Whether this is an all-day event.
  bool allDay,

  /// Event title / description.
  String? title,

  /// Event location.
  String? place,

  /// Event content / details.
  String? content,

  /// Owner name (e.g., "學校行事曆").
  String? ownerName,

  /// Creator name (e.g., "教務處").
  String? creatorName,
});

// dart format off
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

  // TODO: Let downstream SSO APIs accept raw service-code strings directly.
  // TODO: Delete this helper after that migration is complete.
  static PortalServiceCode? fromCode(String code) {
    for (final serviceCode in values) {
      if (serviceCode.code == code) return serviceCode;
    }
    return null;
  }
}
// dart format on

/// Provides the singleton [PortalService] instance.
final portalServiceProvider = Provider<PortalService>((ref) {
  return NtutPortalService();
});

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
abstract interface class PortalService {
  /// Authenticates a user with NTUT Portal credentials.
  ///
  /// Sets the JSESSIONID cookie in the app.ntut.edu.tw domain for subsequent
  /// authenticated requests. This session cookie is shared across all services.
  ///
  /// Returns user profile information including name, email, and avatar filename.
  ///
  /// Throws a [LoginException] subtype on failure — see [WrongCredentialsException],
  /// [AccountLockedException], [PasswordExpiredException],
  /// [MobileVerificationRequiredException], [UnknownLoginException].
  Future<UserDto> login(String username, String password);

  /// Changes the user's NTUT Portal password.
  ///
  /// Requires an active session (call [login] first).
  ///
  /// Throws an [Exception] if the password change fails (e.g., incorrect
  /// current password or the new password doesn't meet requirements).
  Future<void> changePassword(String currentPassword, String newPassword);

  /// Downloads a user's avatar from NTUT Portal.
  ///
  /// If [filename] is omitted or empty, the server returns a dynamically
  /// generated placeholder avatar (a colored square with the user's name).
  ///
  /// Returns the avatar image as raw bytes.
  Future<Uint8List> getAvatar([String? filename]);

  /// Uploads a new profile photo to NTUT Portal, replacing the current one.
  ///
  /// [oldFilename] should be the current avatar filename
  /// (from [UserDto.avatarFilename], or empty string if none).
  ///
  /// Returns the new avatar filename assigned by the server.
  Future<String> uploadAvatar(Uint8List imageBytes, String? oldFilename);

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
  Future<void> sso(String serviceCode);

  /// Returns a URL that authenticates the user with a target NTUT service
  /// via OAuth2 authorization code.
  ///
  /// The returned URL contains an authorization code. Opening it
  /// in any HTTP client (including a system browser) will establish a session
  /// for that service — no cookies from this app are needed.
  ///
  /// This enables "open in browser" functionality: the app performs login and
  /// SSO negotiation, then hands off the resulting URL to the system browser.
  ///
  /// Requires an active portal session (call [login] first).
  ///
  /// Throws an [Exception] if the SSO form is not found (user may not be logged in).
  Future<Uri> getSsoUrl(String serviceCode);

  /// Fetches academic calendar events within a date range.
  ///
  /// Returns a list of calendar events (e.g., holidays, exam periods,
  /// registration deadlines) between [startDate] and [endDate] inclusive.
  ///
  /// Requires an active portal session (call [login] first).
  Future<List<CalendarEventDto>> getCalendar(
    DateTime startDate,
    DateTime endDate,
  );
}
