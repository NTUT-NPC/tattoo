import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tattoo/services/course_service.dart';
import 'package:tattoo/services/i_school_plus_service.dart';
import 'package:tattoo/services/portal_service.dart';

part 'service_providers.g.dart';

/// Provides the singleton [PortalService] instance.
///
/// Handles authentication and SSO for all NTUT services.
@Riverpod(keepAlive: true)
PortalService portalService(Ref ref) {
  return PortalService();
}

/// Provides the singleton [CourseService] instance.
///
/// Accesses NTUT's course selection and catalog system.
@Riverpod(keepAlive: true)
CourseService courseService(Ref ref) {
  return CourseService();
}

/// Provides the singleton [ISchoolPlusService] instance.
///
/// Accesses NTUT's I-School Plus learning management system.
@Riverpod(keepAlive: true)
ISchoolPlusService iSchoolPlusService(Ref ref) {
  return ISchoolPlusService();
}
