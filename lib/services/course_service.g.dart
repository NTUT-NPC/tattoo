// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Service for accessing NTUT's course selection and catalog system.
///
/// This service provides access to:
/// - Student course schedules and enrollment
/// - Course catalog information
/// - Teacher, classroom, and syllabus data
///
/// Authentication is required through [PortalService.sso] with
/// [PortalServiceCode.courseService] before using this service.
///
/// Data is parsed from HTML pages as NTUT does not provide a REST API.
/// Provides the singleton [CourseService] instance.

@ProviderFor(courseService)
final courseServiceProvider = CourseServiceProvider._();

/// Service for accessing NTUT's course selection and catalog system.
///
/// This service provides access to:
/// - Student course schedules and enrollment
/// - Course catalog information
/// - Teacher, classroom, and syllabus data
///
/// Authentication is required through [PortalService.sso] with
/// [PortalServiceCode.courseService] before using this service.
///
/// Data is parsed from HTML pages as NTUT does not provide a REST API.
/// Provides the singleton [CourseService] instance.

final class CourseServiceProvider
    extends $FunctionalProvider<CourseService, CourseService, CourseService>
    with $Provider<CourseService> {
  /// Service for accessing NTUT's course selection and catalog system.
  ///
  /// This service provides access to:
  /// - Student course schedules and enrollment
  /// - Course catalog information
  /// - Teacher, classroom, and syllabus data
  ///
  /// Authentication is required through [PortalService.sso] with
  /// [PortalServiceCode.courseService] before using this service.
  ///
  /// Data is parsed from HTML pages as NTUT does not provide a REST API.
  /// Provides the singleton [CourseService] instance.
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

String _$courseServiceHash() => r'dff3cf3cdc43349407a83ae0ce8ead89f573cba4';
