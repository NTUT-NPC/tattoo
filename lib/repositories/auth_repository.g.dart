// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the [AuthRepository] instance.

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

/// Provides the [AuthRepository] instance.

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  /// Provides the [AuthRepository] instance.
  AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'a4dc16f5f2af4a8bd5204256cb04db09cbe95f07';

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
