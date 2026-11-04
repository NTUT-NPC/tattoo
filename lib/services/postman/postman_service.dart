import 'package:riverpod/riverpod.dart';
import 'package:tattoo/services/demo_mode.dart';
import 'package:tattoo/services/postman/mock_postman_service.dart';
import 'package:tattoo/services/postman/ntut_postman_service.dart';

/// Pagination metadata comes from the server, not the number of returned items.
typedef PostmanAnnouncementPageDto = ({
  List<PostmanAnnouncementDto> announcements,
  int page,
  int totalPages,
});

/// A school announcement in the Postman list, in server display order.
typedef PostmanAnnouncementDto = ({
  String id,
  String category,
  String title,
  String department,
  DateTime publishedAt,
});

/// Details returned by the announcement modal, without list-only date metadata.
typedef PostmanAnnouncementDetailDto = ({
  String id,
  String category,
  String title,
  String summary,

  /// Untrusted, server-supplied HTML. Consumers must render it safely.
  String contentHtml,
  List<PostmanAttachmentDto> attachments,

  /// Publisher and contact information, preserving line breaks.
  String contact,
});

/// An attachment link supplied by Postman; downloading requires NTUT cookies.
typedef PostmanAttachmentDto = ({String name, Uri url});

final postmanServiceProvider = Provider<PostmanService>((ref) {
  if (ref.watch(isDemoProvider)) return MockPostmanService();
  return NtutPostmanService();
});

/// School announcements from NTUT's 小郵差 (`test_postman`).
///
/// Authenticate through `PortalService.sso` with
/// `PortalServiceCode.postmanService` before requesting announcements.
abstract interface class PostmanService {
  /// Fetches a one-based [page] without changing the server's page size.
  ///
  /// The returned page number reflects the server response. Use `totalPages`
  /// to stop pagination. Throws [RangeError] for a non-positive [page].
  /// Requests beyond the last page throw [RangeError] when no data exists.
  Future<PostmanAnnouncementPageDto> getAnnouncements({int page = 1});

  /// Fetches details for an [id] returned by [getAnnouncements].
  ///
  /// Throws [FormatException] if the ID is unavailable or the response cannot
  /// be parsed, and `SessionExpiredException` when portal SSO has expired.
  Future<PostmanAnnouncementDetailDto> getAnnouncement(String id);
}
