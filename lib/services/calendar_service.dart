import 'package:riverpod/riverpod.dart';
import 'package:tattoo/services/calendar_feed.dart';
import 'package:tattoo/utils/http.dart';

typedef CalendarEventDto = ({
  String id,
  String title,
  String? location,
  String? description,
  DateTime start,
  DateTime end,
  bool isAllDay,
});

final calendarServiceProvider = Provider<CalendarService>((ref) {
  return CalendarService();
});

class CalendarService {
  Future<String> fetchCalendarIcs() async {
    final response = await createDio().get<String>(
      calendarPublicIcsUrl,
      options: Options(responseType: ResponseType.plain),
    );

    final ics = response.data;
    if (ics == null || ics.trim().isEmpty) {
      throw StateError('Calendar feed is empty');
    }
    return ics;
  }

  List<CalendarEventDto> parseEvents(String content) {
    final unfoldedLines = _unfoldLines(content);
    final events = <CalendarEventDto>[];

    var inEvent = false;
    final properties = <String, List<_IcsProperty>>{};

    void flushEvent() {
      final startProperty = _firstProperty(properties, 'DTSTART');
      if (startProperty == null) return;

      final start = _parseDateValue(startProperty);
      if (start == null) return;

      final endProperty = _firstProperty(properties, 'DTEND');
      final end = _parseDateValue(endProperty) ?? start;
      final summary = _firstProperty(properties, 'SUMMARY')?.value.trim();
      final title = (summary == null || summary.isEmpty)
          ? 'Untitled event'
          : summary;

      final location = _firstProperty(properties, 'LOCATION')?.value.trim();
      final description = _firstProperty(properties, 'DESCRIPTION')?.value;
      final uid = _firstProperty(properties, 'UID')?.value;
      final isAllDay = _isDateOnly(startProperty);

      final normalizedEnd = end.isBefore(start) ? start : end;
      events.add(
        (
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
      final name = parts.first.toUpperCase();
      final params = <String, String>{};

      for (final param in parts.skip(1)) {
        final index = param.indexOf('=');
        if (index <= 0) continue;
        final key = param.substring(0, index).toUpperCase();
        final value = param.substring(index + 1);
        params[key] = value;
      }

      properties
          .putIfAbsent(name, () => [])
          .add(
            _IcsProperty(
              name: name,
              value: _unescapeIcsValue(rawValue),
              params: params,
            ),
          );
    }

    events.sort((left, right) => left.start.compareTo(right.start));
    return events;
  }

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

  _IcsProperty? _firstProperty(
    Map<String, List<_IcsProperty>> properties,
    String name,
  ) {
    return properties[name]?.first;
  }

  bool _isDateOnly(_IcsProperty property) {
    return property.params['VALUE']?.toUpperCase() == 'DATE' ||
        property.value.length == 8;
  }

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

  String _unescapeIcsValue(String value) {
    return value
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\N', '\n')
        .replaceAll(r'\,', ',')
        .replaceAll(r'\;', ';')
        .replaceAll(r'\\', r'\');
  }
}

class _IcsProperty {
  final String name;
  final String value;
  final Map<String, String> params;

  const _IcsProperty({
    required this.name,
    required this.value,
    required this.params,
  });
}
