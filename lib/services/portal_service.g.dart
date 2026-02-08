// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'portal_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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
/// Provides the singleton [PortalService] instance.

@ProviderFor(portalService)
final portalServiceProvider = PortalServiceProvider._();

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
/// Provides the singleton [PortalService] instance.

final class PortalServiceProvider
    extends $FunctionalProvider<PortalService, PortalService, PortalService>
    with $Provider<PortalService> {
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
  /// Provides the singleton [PortalService] instance.
  PortalServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'portalServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$portalServiceHash();

  @$internal
  @override
  $ProviderElement<PortalService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PortalService create(Ref ref) {
    return portalService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PortalService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PortalService>(value),
    );
  }
}

String _$portalServiceHash() => r'994879bb91e5ead78014ea6a3624096df8606bb9';
