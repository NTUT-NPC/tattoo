// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'i_school_plus_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Service for accessing NTUT's I-School Plus learning management system.
///
/// This service provides access to:
/// - Course materials and files
/// - Student rosters and rankings
/// - Course announcements (not yet implemented)
/// - Assignment subscriptions (not yet implemented)
///
/// Authentication is required through [PortalService.sso] with
/// [PortalServiceCode.iSchoolPlusService] before using this service.
///
/// All operations require selecting a course first, which is handled internally
/// by caching the last selected course.
///
/// Data is parsed from HTML/XML pages as NTUT does not provide a REST API.
/// Provides the singleton [ISchoolPlusService] instance.

@ProviderFor(iSchoolPlusService)
final iSchoolPlusServiceProvider = ISchoolPlusServiceProvider._();

/// Service for accessing NTUT's I-School Plus learning management system.
///
/// This service provides access to:
/// - Course materials and files
/// - Student rosters and rankings
/// - Course announcements (not yet implemented)
/// - Assignment subscriptions (not yet implemented)
///
/// Authentication is required through [PortalService.sso] with
/// [PortalServiceCode.iSchoolPlusService] before using this service.
///
/// All operations require selecting a course first, which is handled internally
/// by caching the last selected course.
///
/// Data is parsed from HTML/XML pages as NTUT does not provide a REST API.
/// Provides the singleton [ISchoolPlusService] instance.

final class ISchoolPlusServiceProvider
    extends
        $FunctionalProvider<
          ISchoolPlusService,
          ISchoolPlusService,
          ISchoolPlusService
        >
    with $Provider<ISchoolPlusService> {
  /// Service for accessing NTUT's I-School Plus learning management system.
  ///
  /// This service provides access to:
  /// - Course materials and files
  /// - Student rosters and rankings
  /// - Course announcements (not yet implemented)
  /// - Assignment subscriptions (not yet implemented)
  ///
  /// Authentication is required through [PortalService.sso] with
  /// [PortalServiceCode.iSchoolPlusService] before using this service.
  ///
  /// All operations require selecting a course first, which is handled internally
  /// by caching the last selected course.
  ///
  /// Data is parsed from HTML/XML pages as NTUT does not provide a REST API.
  /// Provides the singleton [ISchoolPlusService] instance.
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
    r'7077a1b39d77751d21266b570e49bdfe922f1a1c';
