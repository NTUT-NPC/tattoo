import 'package:freezed_annotation/freezed_annotation.dart';

part 'portal.freezed.dart';
part 'portal.g.dart';

/// Represents a logged-in NTUT Portal user.
@freezed
abstract class User with _$User {
  const factory User({
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
  }) = _User;

  factory User.fromJson(Map<String, Object?> json) => _$UserFromJson(json);
}
