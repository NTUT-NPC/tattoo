import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/models/calendar.dart';
import 'package:tattoo/repositories/calendar_repository.dart';

enum CalendarEventStatus { upcoming, ongoing, ended }

class CalendarViewData {
  final CalendarSnapshot snapshot;
  final List<CalendarEvent> activeEvents;
  final List<CalendarEvent> endedEvents;

  const CalendarViewData({
    required this.snapshot,
    required this.activeEvents,
    required this.endedEvents,
  });

  bool get hasVisibleEvents =>
      activeEvents.isNotEmpty || endedEvents.isNotEmpty;
}

/// Screen-level provider that loads calendar events for [CalendarScreen].
final calendarEventsProvider = FutureProvider<CalendarSnapshot>((ref) async {
  final repository = ref.watch(calendarRepositoryProvider);
  return repository.getEvents();
});

final calendarViewDataProvider = FutureProvider<CalendarViewData>((ref) async {
  final snapshot = await ref.watch(calendarEventsProvider.future);
  final now = DateTime.now();
  final groupedEvents = _groupAndSortEvents(snapshot.events, now);

  return CalendarViewData(
    snapshot: snapshot,
    activeEvents: groupedEvents.active,
    endedEvents: groupedEvents.ended,
  );
});

({List<CalendarEvent> active, List<CalendarEvent> ended}) _groupAndSortEvents(
  List<CalendarEvent> events,
  DateTime now,
) {
  final retainedEvents = events
      .where(
        (event) => event.end.isAfter(
          now.subtract(const Duration(days: 30)),
        ),
      )
      .toList();

  final active =
      retainedEvents
          .where(
            (event) =>
                calendarEventStatus(event, now) != CalendarEventStatus.ended,
          )
          .toList()
        ..sort((left, right) {
          final leftGroup = _eventSortGroup(left, now);
          final rightGroup = _eventSortGroup(right, now);

          if (leftGroup != rightGroup) {
            return leftGroup.compareTo(rightGroup);
          }

          if (leftGroup == 0) {
            final endCompare = calendarEventEffectiveEnd(left).compareTo(
              calendarEventEffectiveEnd(right),
            );
            if (endCompare != 0) {
              return endCompare;
            }
          }

          return left.start.compareTo(right.start);
        });

  final ended =
      retainedEvents
          .where(
            (event) =>
                calendarEventStatus(event, now) == CalendarEventStatus.ended,
          )
          .toList()
        ..sort(
          (left, right) => calendarEventEffectiveEnd(right).compareTo(
            calendarEventEffectiveEnd(left),
          ),
        );

  return (active: active, ended: ended);
}

DateTime calendarEventEffectiveEnd(CalendarEvent event) {
  if (!event.isAllDay) return event.end;

  final startDate = DateTime(
    event.start.year,
    event.start.month,
    event.start.day,
  );
  final endDate = DateTime(event.end.year, event.end.month, event.end.day);

  if (endDate.isAfter(startDate)) {
    return endDate.subtract(const Duration(days: 1));
  }
  return endDate;
}

CalendarEventStatus calendarEventStatus(CalendarEvent event, DateTime now) {
  if (event.isAllDay) {
    final nowDate = DateTime(now.year, now.month, now.day);
    final startDate = DateTime(
      event.start.year,
      event.start.month,
      event.start.day,
    );

    if (nowDate.isAfter(calendarEventEffectiveEnd(event))) {
      return CalendarEventStatus.ended;
    }

    if (!nowDate.isBefore(startDate)) {
      return CalendarEventStatus.ongoing;
    }

    return CalendarEventStatus.upcoming;
  }

  if (!now.isBefore(event.end)) {
    return CalendarEventStatus.ended;
  }

  if (!now.isBefore(event.start)) {
    return CalendarEventStatus.ongoing;
  }

  return CalendarEventStatus.upcoming;
}

int _eventSortGroup(CalendarEvent event, DateTime now) {
  switch (calendarEventStatus(event, now)) {
    case CalendarEventStatus.ongoing:
      return 0;
    case CalendarEventStatus.upcoming:
      return 1;
    case CalendarEventStatus.ended:
      return 2;
  }
}
