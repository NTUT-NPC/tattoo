/// Why a login attempt failed.
enum LoginFailure {
  /// Wrong student ID or password (`密碼錯誤`).
  wrongCredentials,

  /// Account locked after too many failed attempts (`已被鎖住`).
  accountLocked,

  /// Password has expired and must be changed (`密碼已過期` + `resetPwd: true`).
  passwordExpired,

  /// Mobile phone verification is required (`驗證手機`).
  mobileVerificationRequired,

  /// Stored credentials were cleared or lost while the user still has local data.
  credentialsMissing,

  /// Login failed with an unrecognized error message.
  unknown,
}

/// Thrown when NTUT Portal login fails, or passed as data through
/// [loginExceptionProvider] when the session is destroyed due to auth failure.
class LoginException implements Exception {
  final LoginFailure failure;
  final String? message;
  const LoginException(this.failure, {this.message});

  @override
  String toString() =>
      'LoginException($failure${message != null ? ': $message' : ''})';
}
