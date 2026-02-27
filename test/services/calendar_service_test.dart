import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/services/calendar_service.dart';

void main() {
  group('CalendarService.parseEvents', () {
    final service = CalendarService();

    test('parses date-only (all-day) and datetime events', () {
      final ics = '''
BEGIN:VCALENDAR
BEGIN:VEVENT
SUMMARY:All-day Event
DTSTART;VALUE=DATE:20260301
DTEND;VALUE=DATE:20260302
UID:allday
END:VEVENT
BEGIN:VEVENT
SUMMARY:Timed Event
DTSTART:20260301T120000
DTEND:20260301T130000
UID:timed
END:VEVENT
END:VCALENDAR
''';
      final events = service.parseEvents(ics);
      expect(events.length, 2);
      expect(events[0].isAllDay, true);
      expect(events[0].start.hour, 0);
      expect(events[1].isAllDay, false);
      expect(events[1].start.hour, 12);
    });

    test('parses folded lines', () {
      final ics = '''
BEGIN:VCALENDAR
BEGIN:VEVENT
SUMMARY:Long 
 description
DTSTART:20260301T120000
DTEND:20260301T130000
UID:folded
END:VEVENT
END:VCALENDAR
''';
      final events = service.parseEvents(ics);
      expect(events.length, 1);
      expect(events[0].title, 'Long description');
    });

    test('unescapes ICS text', () {
      final ics = '''
BEGIN:VCALENDAR
BEGIN:VEVENT
SUMMARY:Escaped\, Comma
DESCRIPTION:Line1\\nLine2
DTSTART:20260301T120000
DTEND:20260301T130000
UID:escape
END:VEVENT
END:VCALENDAR
''';
      final events = service.parseEvents(ics);
      expect(events[0].title, 'Escaped, Comma');
      expect(events[0].description, 'Line1\nLine2');
    });
  });
}
