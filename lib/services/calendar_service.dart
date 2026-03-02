import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tattoo/services/portal_service.dart';
import 'package:tattoo/utils/http.dart';

/// Represents a calendar event from the NTUT Portal.
///
/// Events come in two flavors:
/// - **Named events** with [id], [calTitle], [ownerName], [creatorName]
///   (e.g., exam periods, registration deadlines)
/// - **Holiday markers** with [isHoliday] = "1" and an empty title
///   (weekends and national holidays)
typedef CalendarEventDto = ({
  /// Event ID (absent for holiday markers).
  int? id,

  /// Event start time (epoch milliseconds).
  int? calStart,

  /// Event end time (epoch milliseconds).
  int? calEnd,

  /// Whether this is an all-day event ("1" = yes).
  String? allDay,

  /// Event title / description.
  String? calTitle,

  /// Event location.
  String? calPlace,

  /// Event content / details.
  String? calContent,

  /// Owner name (e.g., "學校行事曆").
  String? ownerName,

  /// Creator name (e.g., "教務處").
  String? creatorName,

  /// Whether this is a holiday ("1" = yes).
  String? isHoliday,
});

/// Provides the singleton [CalendarService] instance.
final calendarServiceProvider = Provider<CalendarService>(
  (ref) => CalendarService(ref.read(portalServiceProvider)),
);

/// Service for fetching NTUT academic calendar events.
///
/// Uses the `calModeApp.do` JSON API on the NTUT Portal host.
/// Requires an active portal session (shared cookie jar from [PortalService.login]).
class CalendarService {
  final Dio _dio;

  CalendarService(PortalService portalService) : _dio = portalService.portalDio;

  /// Fetches academic calendar events within a date range.
  ///
  /// Returns a list of calendar events (e.g., holidays, exam periods,
  /// registration deadlines) between [startDate] and [endDate] inclusive.
  ///
  /// Requires an active portal session (call [PortalService.login] first).
  Future<List<CalendarEventDto>> getCalendar(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final formatter = DateFormat('yyyy/MM/dd');
    final response = await _dio.get(
      'calModeApp.do',
      queryParameters: {
        'startDate': formatter.format(startDate),
        'endDate': formatter.format(endDate),
      },
    );

    final List<dynamic> events = jsonDecode(response.data);
    return events.map<CalendarEventDto>((e) {
      String? normalizeEmpty(String? value) =>
          value?.isNotEmpty == true ? value : null;

      return (
        id: e['id'] as int?,
        calStart: e['calStart'] as int?,
        calEnd: e['calEnd'] as int?,
        allDay: normalizeEmpty(e['allDay'] as String?),
        calTitle: normalizeEmpty(e['calTitle'] as String?),
        calPlace: normalizeEmpty(e['calPlace'] as String?),
        calContent: normalizeEmpty(e['calContent'] as String?),
        ownerName: normalizeEmpty(e['ownerName'] as String?),
        creatorName: normalizeEmpty(e['creatorName'] as String?),
        isHoliday: normalizeEmpty(e['isHoliday'] as String?),
      );
    }).toList();
  }
}
