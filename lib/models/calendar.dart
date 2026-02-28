/// Domain model for a single calendar event used by the UI layer.
class CalendarEvent {
  final String id;
  final String title;
  final String? location;
  final String? description;
  final DateTime start;
  final DateTime end;
  final bool isAllDay;

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.location,
    required this.description,
    required this.start,
    required this.end,
    required this.isAllDay,
  });
}

/// Repository result model containing event list and cache metadata.
class CalendarSnapshot {
  final List<CalendarEvent> events;
  final DateTime? fetchedAt;
  final bool refreshedFromNetwork;

  const CalendarSnapshot({
    required this.events,
    required this.fetchedAt,
    required this.refreshedFromNetwork,
  });
}
