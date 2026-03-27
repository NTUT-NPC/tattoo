import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/repositories/calendar_repository.dart';

class CalendarFocusedDayNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();
  void updateDate(DateTime day) => state = day;
}

final calendarFocusedDayProvider = NotifierProvider<CalendarFocusedDayNotifier, DateTime>(
  CalendarFocusedDayNotifier.new,
);

class CalendarRangeNotifier extends Notifier<DateTimeRange> {
  @override
  DateTimeRange build() {
    final now = DateTime.now();
    return DateTimeRange(
      start: DateTime(now.year, now.month - 1, 1),
      end: DateTime(now.year, now.month + 2, 0),
    );
  }
  void updateRange(DateTimeRange range) => state = range;
}

final calendarRangeProvider = NotifierProvider<CalendarRangeNotifier, DateTimeRange>(
  CalendarRangeNotifier.new,
);

final calendarEventsProvider =
    FutureProvider<Map<DateTime, List<CalendarEvent>>>((ref) async {
      final range = ref.watch(calendarRangeProvider);
      final repo = ref.watch(calendarRepositoryProvider);

      final events = await repo.getCalendar(
        startDate: range.start,
        endDate: range.end,
      );

      final map = <DateTime, List<CalendarEvent>>{};
      for (final event in events) {
        if (event.start == null || event.end == null) continue;
        var current = DateTime(
          event.start!.year,
          event.start!.month,
          event.start!.day,
        );
        // NTUT sets the `end` epoch to exactly 00:00 on the day *after* the event finishes.
        // We subtract 1 millisecond so that 'last' falls on the true final day.
        final adjustedEnd = event.end!.subtract(const Duration(milliseconds: 1));
        
        // If start and end are exactly the same (a zero-duration event at midnight),
        // fallback to current to ensure it gets added for at least one day.
        final lastDay = adjustedEnd.isBefore(current) ? current : adjustedEnd;
        
        final last = DateTime(lastDay.year, lastDay.month, lastDay.day);
        while (!current.isAfter(last)) {
          map.putIfAbsent(current, () => []).add(event);
          current = current.add(const Duration(days: 1));
        }
      }
      return map;
    });
