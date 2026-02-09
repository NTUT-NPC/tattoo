// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the current user's profile.
///
/// Returns `null` if not logged in.

@ProviderFor(userProfile)
final userProfileProvider = UserProfileProvider._();

/// Provides the current user's profile.
///
/// Returns `null` if not logged in.

final class UserProfileProvider
    extends
        $FunctionalProvider<
          AsyncValue<UserWithStudent?>,
          UserWithStudent?,
          FutureOr<UserWithStudent?>
        >
    with $FutureModifier<UserWithStudent?>, $FutureProvider<UserWithStudent?> {
  /// Provides the current user's profile.
  ///
  /// Returns `null` if not logged in.
  UserProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userProfileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userProfileHash();

  @$internal
  @override
  $FutureProviderElement<UserWithStudent?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<UserWithStudent?> create(Ref ref) {
    return userProfile(ref);
  }
}

String _$userProfileHash() => r'2dad51deea19beb77f1a898f4a7e7618c6e3651e';

/// Provides the current user's avatar file.
///
/// Returns `null` if user has no avatar or not logged in.

@ProviderFor(userAvatar)
final userAvatarProvider = UserAvatarProvider._();

/// Provides the current user's avatar file.
///
/// Returns `null` if user has no avatar or not logged in.

final class UserAvatarProvider
    extends $FunctionalProvider<AsyncValue<File?>, File?, FutureOr<File?>>
    with $FutureModifier<File?>, $FutureProvider<File?> {
  /// Provides the current user's avatar file.
  ///
  /// Returns `null` if user has no avatar or not logged in.
  UserAvatarProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userAvatarProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userAvatarHash();

  @$internal
  @override
  $FutureProviderElement<File?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<File?> create(Ref ref) {
    return userAvatar(ref);
  }
}

String _$userAvatarHash() => r'eb2c6d7819f63254fbbe9cf8cb8d8a61572ea925';
