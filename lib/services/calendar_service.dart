import 'package:riverpod/riverpod.dart';
import 'package:tattoo/models/calendar.dart';
import 'package:tattoo/utils/http.dart';

const _calendarId = 'docfuhim9b22fqvp2tk842ak3c@group.calendar.google.com';

Uri _buildCalendarPublicIcsUri(String id) {
  return Uri.https(
    'calendar.google.com',
    '/calendar/ical/$id/public/basic.ics',
  );
}

String get _calendarPublicIcsUrl =>
    _buildCalendarPublicIcsUri(_calendarId).toString();

// dart format off
/// ICS property names supported by the parser.
enum IcsPropertyName {
  dtstart('DTSTART'),
  dtend('DTEND'),
  summary('SUMMARY'),
  location('LOCATION'),
  description('DESCRIPTION'),
  uid('UID');

  final String value;
  const IcsPropertyName(this.value);

  /// Return the enum case for a property name string, or null if unknown.
  static IcsPropertyName? fromString(String name) {
    for (final prop in values) {
      if (prop.value == name) return prop;
    }
    return null;
  }
}
// dart format on

/// Provider for creating [CalendarService].
final calendarServiceProvider = Provider<CalendarService>((ref) {
  return CalendarService();
});

/// Service responsible for fetching and parsing Google Calendar ICS data.
class CalendarService {
  CalendarService({Dio? dio}) : _dio = dio ?? createDio();

  final Dio _dio;

  /// Downloads the calendar ICS content as plain text.
  ///
  /// Throws a [StateError] when the response is empty.
  Future<String> fetchCalendarIcs() async {
    final response = await _dio.get<String>(
      _calendarPublicIcsUrl,
      options: Options(responseType: ResponseType.plain),
    );

    final ics = response.data;
    if (ics == null || ics.trim().isEmpty) {
      throw StateError('Calendar feed is empty');
    }
    return ics;
  }

  /// Parses ICS text into a sorted list of [CalendarEvent].
  ///
  /// Supported fields: `UID`, `SUMMARY`, `LOCATION`, `DESCRIPTION`,
  /// `DTSTART`, and `DTEND`.
  ///
  /// Note: `TZID` parameters are preserved while parsing, but are not currently
  /// applied for timezone conversion. Datetime values without a `Z` suffix are
  /// interpreted as local wall time.
  List<CalendarEvent> parseEvents(String content) {
    final unfoldedLines = _unfoldLines(content);
    final events = <CalendarEvent>[];

    var inEvent = false;
    final properties = <IcsPropertyName, List<_IcsProperty>>{};

    void flushEvent() {
      final startProperty = _firstProperty(properties, IcsPropertyName.dtstart);
      if (startProperty == null) return;

      final start = _parseDateValue(startProperty);
      if (start == null) return;

      final endProperty = _firstProperty(properties, IcsPropertyName.dtend);
      final end = _parseDateValue(endProperty) ?? start;
      final summary = _firstProperty(
        properties,
        IcsPropertyName.summary,
      )?.value.trim();
      final title = (summary == null || summary.isEmpty)
          ? 'Untitled event'
          : summary;

      final location = _firstProperty(
        properties,
        IcsPropertyName.location,
      )?.value.trim();
      final description = _firstProperty(
        properties,
        IcsPropertyName.description,
      )?.value;
      final uid = _firstProperty(properties, IcsPropertyName.uid)?.value;
      final isAllDay = _isDateOnly(startProperty);

      final normalizedEnd = end.isBefore(start) ? start : end;
      events.add(
        CalendarEvent(
          id: uid?.trim().isNotEmpty == true
              ? uid!.trim()
              : '${start.toIso8601String()}::$title',
          title: title,
          location: location?.isEmpty == true ? null : location,
          description: description?.trim().isEmpty == true ? null : description,
          start: start,
          end: normalizedEnd,
          isAllDay: isAllDay,
        ),
      );
    }

    for (final line in unfoldedLines) {
      if (line == 'BEGIN:VEVENT') {
        inEvent = true;
        properties.clear();
        continue;
      }
      if (line == 'END:VEVENT') {
        if (inEvent) {
          flushEvent();
          inEvent = false;
          properties.clear();
        }
        continue;
      }
      if (!inEvent || line.isEmpty) continue;

      final separator = line.indexOf(':');
      if (separator <= 0) continue;

      final rawNameAndParams = line.substring(0, separator);
      final rawValue = line.substring(separator + 1);

      final parts = rawNameAndParams.split(';');
      final nameString = parts.first.toUpperCase();
      final propName = IcsPropertyName.fromString(nameString);
      if (propName == null) continue; // Skip unknown properties

      final params = <String, String>{};

      for (final param in parts.skip(1)) {
        final index = param.indexOf('=');
        if (index <= 0) continue;
        final key = param.substring(0, index).toUpperCase();
        final value = param.substring(index + 1);
        params[key] = value;
      }

      properties.putIfAbsent(propName, () => []).add(
        (
          name: propName,
          value: _unescapeIcsValue(rawValue),
          params: params,
        ),
      );
    }

    events.sort((left, right) => left.start.compareTo(right.start));
    return events;
  }

  /// Unfolds wrapped ICS lines according to RFC 5545 line folding rules.
  List<String> _unfoldLines(String content) {
    final lines = content
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n');
    final unfolded = <String>[];

    for (final line in lines) {
      if (line.isEmpty) {
        unfolded.add('');
        continue;
      }

      if ((line.startsWith(' ') || line.startsWith('\t')) &&
          unfolded.isNotEmpty) {
        unfolded[unfolded.length - 1] = '${unfolded.last}${line.substring(1)}';
      } else {
        unfolded.add(line);
      }
    }

    return unfolded;
  }

  /// Returns the first property by name from the parsed event property map.
  _IcsProperty? _firstProperty(
    Map<IcsPropertyName, List<_IcsProperty>> properties,
    IcsPropertyName name,
  ) {
    return properties[name]?.first;
  }

  /// Returns whether a date property represents a date-only value.
  bool _isDateOnly(_IcsProperty property) {
    return property.params['VALUE']?.toUpperCase() == 'DATE' ||
        property.value.length == 8;
  }

  /// Parses an ICS date/datetime property into local [DateTime].
  ///
  /// Handles all-day dates (`VALUE=DATE`) and UTC datetimes (`...Z`).
  ///
  /// Limitation: `TZID` is currently ignored during conversion. For datetime
  /// values without `Z`, the parser treats the timestamp as local wall time.
  DateTime? _parseDateValue(_IcsProperty? property) {
    if (property == null) return null;

    final value = property.value.trim();
    if (value.isEmpty) return null;

    if (_isDateOnly(property)) {
      if (value.length != 8) return null;
      final year = int.tryParse(value.substring(0, 4));
      final month = int.tryParse(value.substring(4, 6));
      final day = int.tryParse(value.substring(6, 8));
      if (year == null || month == null || day == null) return null;
      return DateTime(year, month, day);
    }

    final cleaned = value.endsWith('Z')
        ? value.substring(0, value.length - 1)
        : value;
    if (cleaned.length < 15) return null;

    final year = int.tryParse(cleaned.substring(0, 4));
    final month = int.tryParse(cleaned.substring(4, 6));
    final day = int.tryParse(cleaned.substring(6, 8));
    final hour = int.tryParse(cleaned.substring(9, 11));
    final minute = int.tryParse(cleaned.substring(11, 13));
    final second = int.tryParse(cleaned.substring(13, 15));

    if (year == null ||
        month == null ||
        day == null ||
        hour == null ||
        minute == null ||
        second == null) {
      return null;
    }

    if (value.endsWith('Z')) {
      return DateTime.utc(year, month, day, hour, minute, second).toLocal();
    }

    return DateTime(year, month, day, hour, minute, second);
  }

  /// Unescapes escaped ICS text sequences.
  String _unescapeIcsValue(String value) {
    final buffer = StringBuffer();
    for (var index = 0; index < value.length; index++) {
      final ch = value[index];
      if (ch == r'\') {
        if (index + 1 < value.length) {
          final next = value[++index];
          switch (next) {
            case 'n':
            case 'N':
              buffer.write('\n');
              break;
            case ',':
              buffer.write(',');
              break;
            case ';':
              buffer.write(';');
              break;
            case r'\':
              buffer.write(r'\');
              break;
            default:
              buffer.write(next);
              break;
          }
        } else {
          buffer.write(ch);
        }
      } else {
        buffer.write(ch);
      }
    }
    return buffer.toString();
  }
}

/// Internal representation of a parsed ICS property line.
typedef _IcsProperty = ({
  IcsPropertyName name,
  String value,
  Map<String, String> params,
});
