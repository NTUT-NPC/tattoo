/// Thrown when NTUT Portal login fails.
///
/// The specific subtype indicates the failure reason, parsed from the API's
/// `errorMsg` field.
sealed class LoginException implements Exception {
  const LoginException();
}

/// Wrong student ID or password (`密碼錯誤`).
class WrongCredentialsException extends LoginException {
  const WrongCredentialsException();
}

/// Account locked after too many failed attempts (`已被鎖住`).
/// Typically a 15-minute cooldown.
class AccountLockedException extends LoginException {
  const AccountLockedException();
}

/// Password has expired and must be changed (`密碼已過期` + `resetPwd: true`).
class PasswordExpiredException extends LoginException {
  const PasswordExpiredException();
}

/// Mobile phone verification is required (`驗證手機`).
class MobileVerificationRequiredException extends LoginException {
  const MobileVerificationRequiredException();
}

/// Login failed with an unrecognized error message.
class UnknownLoginException extends LoginException {
  final String? message;
  const UnknownLoginException(this.message);
}
