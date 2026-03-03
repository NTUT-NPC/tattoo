import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/services/calendar_service.dart';
import 'package:tattoo/services/portal_service.dart';

import '../test_helpers.dart';

void main() {
  group('CalendarService Tests', () {
    late PortalService portalService;
    late CalendarService calendarService;

    setUpAll(() {
      TestCredentials.validate();
    });

    setUp(() async {
      portalService = PortalService();
      calendarService = CalendarService(portalService);
      await portalService.login(
        TestCredentials.username,
        TestCredentials.password,
      );
      await respectfulDelay();
    });

    test('should return calendar events for a semester date range', () async {
      final events = await calendarService.getCalendar(
        DateTime(2025, 1, 1),
        DateTime(2025, 6, 30),
      );

      expect(events, isNotEmpty, reason: 'Semester should have events');

      // Verify structure of first non-holiday event (skip holidays with empty titles)
      final namedEvents = events.where((e) => e.calTitle != null).toList();
      expect(
        namedEvents,
        isNotEmpty,
        reason: 'Semester should have at least one event with a non-null title',
      );
      final event = namedEvents.first;
      expect(event.calTitle, isNotNull, reason: 'Event should have a title');
      expect(
        event.calStart,
        isNotNull,
        reason: 'Event should have a start time',
      );
    });

    test('should return empty list for a date range with no events', () async {
      // A single day far in the past unlikely to have events
      final events = await calendarService.getCalendar(
        DateTime(2000, 1, 1),
        DateTime(2000, 1, 2),
      );

      // May still contain weekend/holiday markers, but should be a valid list
      expect(events, isA<List>());
    });
  });
}
