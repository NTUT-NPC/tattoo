import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:riverpod/riverpod.dart';

/// Represents a calendar event from Google Calendar.
typedef CalendarEventDto = ({
  String id,
  String? summary,
  String? description,
  String? location,
  DateTime? start,
  DateTime? end,
});

/// Extension methods for [CalendarEventDto].
extension CalendarEventDtoExtension on CalendarEventDto {
  /// Whether this is an all-day event (starts at midnight with no specific time).
  bool get isAllDay =>
      start != null &&
      start!.hour == 0 &&
      start!.minute == 0 &&
      (end == null || (end!.hour == 0 && end!.minute == 0));

  /// Formats the event time for display.
  ///
  /// Returns formatted string based on event type:
  /// - Single-day all-day: "3月2日"
  /// - Multi-day all-day: "3月1日 - 3月5日"
  /// - Same-day timed: "上午 9:00 - 下午 5:00"
  /// - Multi-day timed: "3月1日 上午 9:00 - 3月5日 下午 5:00"
  String formatTime({String locale = 'zh_TW'}) {
    if (start == null) return '';

    final timeFormat = DateFormat.jm(locale);
    final dateFormat = DateFormat.MMMd(locale);

    if (isAllDay) {
      if (end == null ||
          _isSameDay(start!, end!.subtract(const Duration(days: 1)))) {
        // Single-day all-day event
        return dateFormat.format(start!);
      }
      // Multi-day all-day event
      return '${dateFormat.format(start!)} - ${dateFormat.format(end!.subtract(const Duration(days: 1)))}';
    }

    // Timed event
    if (end == null) {
      return timeFormat.format(start!);
    }

    if (_isSameDay(start!, end!)) {
      return '${timeFormat.format(start!)} - ${timeFormat.format(end!)}';
    }

    // Multi-day timed event
    return '${dateFormat.format(start!)} ${timeFormat.format(start!)} - ${dateFormat.format(end!)} ${timeFormat.format(end!)}';
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// Groups events by date, expanding multi-day events across all days they span.
///
/// For multi-day events, the event is added to each day in the range.
/// Google Calendar's end date for all-day events is exclusive (day after last day).
Map<DateTime, List<CalendarEventDto>> groupEventsByDate(
  List<CalendarEventDto> events,
) {
  final eventsByDate = <DateTime, List<CalendarEventDto>>{};

  for (final event in events) {
    final start = event.start;
    final end = event.end;

    if (start == null) continue;

    // Normalize start date
    var currentDay = DateTime(start.year, start.month, start.day);

    // For multi-day events, add to each day in the range
    // For same-day events, endDay equals currentDay, so we use do-while to include at least one day
    final endDay = end != null
        ? DateTime(end.year, end.month, end.day)
        : currentDay;

    do {
      eventsByDate.putIfAbsent(currentDay, () => []).add(event);
      currentDay = currentDay.add(const Duration(days: 1));
    } while (currentDay.isBefore(endDay));
  }

  return eventsByDate;
}

/// Provides the singleton [CalendarService] instance.
final calendarServiceProvider = Provider<CalendarService>(
  (ref) => CalendarService(),
);

// Compile-time environment variables (from --dart-define in CI/GitHub).
// For local development: flutter run --dart-define=GOOGLE_CALENDAR_API_KEY=your_key
const _envCalendarId = String.fromEnvironment('GOOGLE_CALENDAR_ID');
const _envApiKey = String.fromEnvironment('GOOGLE_CALENDAR_API_KEY');

const _defaultCalendarId =
    'docfuhim9b22fqvp2tk842ak3c@group.calendar.google.com';
const _defaultApiUrl = 'https://www.googleapis.com/calendar/v3/';

/// Service for fetching NTUT calendar events.
///
/// Currently uses Google Calendar API directly for testing.
/// TODO: Replace with proxy API in production.
class CalendarService {
  late final Dio _dio;
  final String _calendarId;
  final String _apiKey;

  CalendarService()
    : _calendarId = _envCalendarId.isNotEmpty
          ? _envCalendarId
          : _defaultCalendarId,
      _apiKey = _envApiKey {
    _dio = Dio()..options.baseUrl = _defaultApiUrl;
  }

  /// Fetches calendar events from Google Calendar.
  ///
  /// Optional [timeMin] and [timeMax] parameters can be used to filter events
  /// by date range. If not provided, defaults to events from now onwards.
  ///
  /// Returns a list of [CalendarEventDto] records.
  ///
  /// Throws [DioException] if the network request fails.
  Future<List<CalendarEventDto>> getEvents({
    DateTime? timeMin,
    DateTime? timeMax,
    int? maxResults,
  }) async {
    final queryParameters = <String, dynamic>{
      'key': _apiKey,
      'singleEvents': 'true',
      'orderBy': 'startTime',
      'timeZone': 'Asia/Taipei',
    };

    if (timeMin != null) {
      queryParameters['timeMin'] = timeMin.toUtc().toIso8601String();
    }
    if (timeMax != null) {
      queryParameters['timeMax'] = timeMax.toUtc().toIso8601String();
    }
    if (maxResults != null) {
      queryParameters['maxResults'] = maxResults.toString();
    }

    final Response<dynamic> response;
    try {
      response = await _dio.get(
        'calendars/${Uri.encodeComponent(_calendarId)}/events',
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      log('Failed to fetch calendar events: $e', name: 'CalendarService');
      rethrow;
    }

    final json = response.data as Map<String, dynamic>;
    final items = json['items'] as List<dynamic>? ?? [];
    return items.map((item) {
      final map = item as Map<String, dynamic>;
      return (
        id: map['id'] as String,
        summary: map['summary'] as String?,
        description: map['description'] as String?,
        location: map['location'] as String?,
        start: _parseDateTime(map['start'] as Map<String, dynamic>?),
        end: _parseDateTime(map['end'] as Map<String, dynamic>?),
      );
    }).toList();
  }

  /// Parses a Google Calendar date/time object.
  ///
  /// Google Calendar returns either `dateTime` (for timed events) or
  /// `date` (for all-day events). Returns local DateTime for consistent handling.
  DateTime? _parseDateTime(Map<String, dynamic>? dateTimeMap) {
    if (dateTimeMap == null) return null;

    final dateTime = dateTimeMap['dateTime'] as String?;
    if (dateTime != null) {
      // DateTime.parse handles timezone offset but returns UTC internally,
      // convert to local time for consistent display
      return DateTime.parse(dateTime).toLocal();
    }

    final date = dateTimeMap['date'] as String?;
    if (date != null) {
      // All-day events have no time component, parse as local date
      return DateTime.parse(date);
    }

    return null;
  }
}
