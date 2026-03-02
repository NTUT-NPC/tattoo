import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/services/calendar_service.dart';

import '../test_helpers.dart';

void main() {
  group('CalendarService Integration Tests', () {
    late CalendarService calendarService;

    setUpAll(() {
      TestCredentials.validateGoogleCalendarApiKey();
    });

    setUp(() {
      calendarService = CalendarService();
    });

    test('should fetch calendar events with explicit time range', () async {
      final now = DateTime.now();
      final twoWeeksLater = now.add(const Duration(days: 14));

      final events = await calendarService.getEvents(
        timeMin: now,
        timeMax: twoWeeksLater,
        maxResults: 10,
      );

      // Basic validation - the API should return a list (may be empty)
      expect(events, isA<List<CalendarEventDto>>());
      expect(events.length, lessThanOrEqualTo(10));
    });

    test('should fetch events within a date range', () async {
      final now = DateTime.now();
      final oneMonthLater = now.add(const Duration(days: 30));

      final events = await calendarService.getEvents(
        timeMin: now,
        timeMax: oneMonthLater,
      );

      expect(events, isA<List<CalendarEventDto>>());
    });

    test('should parse event fields correctly', () async {
      final events = await calendarService.getEvents(maxResults: 5);

      for (final event in events) {
        // ID should always be present
        expect(event.id, isNotEmpty);

        // Start and end should be parsed (may be null for malformed events)
        // but if present, end should be after or equal to start
        if (event.start != null && event.end != null) {
          expect(
            event.end!.isAfter(event.start!) ||
                event.end!.isAtSameMomentAs(event.start!),
            isTrue,
            reason: 'Event end should be after or equal to start',
          );
        }
      }
    });
  });
}
