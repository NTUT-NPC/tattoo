// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the singleton [PortalService] instance.
///
/// Handles authentication and SSO for all NTUT services.

@ProviderFor(portalService)
final portalServiceProvider = PortalServiceProvider._();

/// Provides the singleton [PortalService] instance.
///
/// Handles authentication and SSO for all NTUT services.

final class PortalServiceProvider
    extends $FunctionalProvider<PortalService, PortalService, PortalService>
    with $Provider<PortalService> {
  /// Provides the singleton [PortalService] instance.
  ///
  /// Handles authentication and SSO for all NTUT services.
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

String _$portalServiceHash() => r'879cb8bb0a55dd7d13d7d838631e3b1c732a589c';

/// Provides the singleton [CourseService] instance.
///
/// Accesses NTUT's course selection and catalog system.

@ProviderFor(courseService)
final courseServiceProvider = CourseServiceProvider._();

/// Provides the singleton [CourseService] instance.
///
/// Accesses NTUT's course selection and catalog system.

final class CourseServiceProvider
    extends $FunctionalProvider<CourseService, CourseService, CourseService>
    with $Provider<CourseService> {
  /// Provides the singleton [CourseService] instance.
  ///
  /// Accesses NTUT's course selection and catalog system.
  CourseServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'courseServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$courseServiceHash();

  @$internal
  @override
  $ProviderElement<CourseService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CourseService create(Ref ref) {
    return courseService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CourseService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CourseService>(value),
    );
  }
}

String _$courseServiceHash() => r'928d49fa20e0b457cb27ee73598458a2123391b7';

/// Provides the singleton [ISchoolPlusService] instance.
///
/// Accesses NTUT's I-School Plus learning management system.

@ProviderFor(iSchoolPlusService)
final iSchoolPlusServiceProvider = ISchoolPlusServiceProvider._();

/// Provides the singleton [ISchoolPlusService] instance.
///
/// Accesses NTUT's I-School Plus learning management system.

final class ISchoolPlusServiceProvider
    extends
        $FunctionalProvider<
          ISchoolPlusService,
          ISchoolPlusService,
          ISchoolPlusService
        >
    with $Provider<ISchoolPlusService> {
  /// Provides the singleton [ISchoolPlusService] instance.
  ///
  /// Accesses NTUT's I-School Plus learning management system.
  ISchoolPlusServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'iSchoolPlusServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$iSchoolPlusServiceHash();

  @$internal
  @override
  $ProviderElement<ISchoolPlusService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ISchoolPlusService create(Ref ref) {
    return iSchoolPlusService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ISchoolPlusService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ISchoolPlusService>(value),
    );
  }
}

String _$iSchoolPlusServiceHash() =>
    r'537e4a3b4734775b7a222a616b70f94360030ff7';
