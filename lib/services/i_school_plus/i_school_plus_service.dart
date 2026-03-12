import 'package:riverpod/riverpod.dart';
import 'package:tattoo/services/i_school_plus/ntut_i_school_plus_service.dart';

/// Course reference from the iSchool+ course selection sidebar.
///
/// Obtained from [ISchoolPlusService.getCourseList] and required by all
/// other iSchool+ operations. Contains the internal ID needed to select
/// the course server-side.
typedef ISchoolCourseDto = ({
  /// Course offering number from the course system (e.g., "352902").
  String courseNumber,

  /// Internal iSchool+ course identifier (e.g., "10099386").
  ///
  /// Used by [ISchoolPlusService] to select the course via `goto_course.php`.
  String internalId,
});

/// Student enrolled in an i-School Plus course.
typedef StudentDto = ({
  /// Student's NTUT ID (e.g., "111360109").
  String? id,

  /// Student's full name.
  String? name,
});

/// Reference to a course material file in i-School Plus.
typedef MaterialRefDto = ({
  /// The course this material belongs to.
  ISchoolCourseDto course,

  /// Title/filename of the material.
  String? title,

  /// SCORM resource identifier for the material.
  ///
  /// This is an encoded identifier from the SCORM manifest.
  /// This value is used internally by I-School Plus to locate the resource.
  String? href,
});

/// Downloadable course material with its access information.
typedef MaterialDto = ({
  /// Direct download URL for the material file.
  /// Can also be used for streaming media content.
  Uri downloadUrl,

  /// Optional Referer URL for some downloads (e.g., PDF viewer pages).
  /// If non-null, must be included as the HTTP Referer header when
  /// downloading or streaming. For other materials, this is `null`
  /// and no Referer header is required.
  String? referer,

  /// Whether this material can be streamed (e.g., video/audio recordings).
  bool streamable,
});

/// Provides the singleton [ISchoolPlusService] instance.
final iSchoolPlusServiceProvider = Provider<ISchoolPlusService>(
  (ref) => NtutISchoolPlusService(),
);

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
/// Call [getCourseList] first to obtain [ISchoolCourseDto] references,
/// then pass them to other methods. Not all courses from the course system
/// are available on I-School Plus (e.g., internships, early-semester courses).
///
/// Data is parsed from HTML/XML pages as NTUT does not provide a REST API.
abstract interface class ISchoolPlusService {
  /// Fetches the list of courses available on iSchool+ for the current user.
  ///
  /// Returns course references that can be passed to [getStudents],
  /// [getMaterials], and [getMaterial]. Not all courses from the course
  /// system will be present — internships and newly added courses may
  /// not appear until they are set up on I-School Plus.
  ///
  /// The returned list preserves the order from the I-School Plus sidebar.
  Future<List<ISchoolCourseDto>> getCourseList();

  /// Fetches the list of students enrolled in the specified course.
  ///
  /// Returns student information (ID and name) for all students enrolled in
  /// the given [course].
  ///
  /// The [course] should be obtained from [getCourseList].
  ///
  /// System accounts (e.g., "istudyoaa") are automatically filtered out.
  ///
  /// Throws an [Exception] if no student data exists.
  Future<List<StudentDto>> getStudents(ISchoolCourseDto course);

  /// Fetches the list of course materials for the specified course.
  ///
  /// Returns references to all files and materials posted to I-School Plus
  /// for the given [course].
  ///
  /// The [course] should be obtained from [getCourseList].
  ///
  /// Each material reference includes a title and SCORM resource identifier
  /// (href) that can be passed to [getMaterial] to obtain download information.
  ///
  /// Materials are extracted from the course's SCORM manifest XML.
  /// Folder/directory items without actual files are automatically excluded.
  Future<List<MaterialRefDto>> getMaterials(ISchoolCourseDto course);

  /// Fetches download information for a specific course material.
  ///
  /// Returns the direct download URL and optional referer header required to
  /// download the material file.
  ///
  /// The [material] should be obtained from [getMaterials].
  ///
  /// The download process varies by material type:
  /// - Standard files: Direct download URL
  /// - PDFs: Requires a referer URL for access
  /// - Course recordings: Returns iStream URL with `streamable: true`
  ///
  /// When the returned [MaterialDto] has a non-null `referer` field, it must
  /// be included as the Referer header when downloading the file.
  ///
  /// Throws an [Exception] if the material cannot be accessed or parsed.
  Future<MaterialDto> getMaterial(MaterialRefDto material);
}
