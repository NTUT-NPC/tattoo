import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/repositories/calendar_repository.dart';

// ---------------------------------------------------------------------------
// Shared notifier — used for both focused-day and selected-day providers.
// ---------------------------------------------------------------------------

class DateTimeNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();
  void updateDate(DateTime day) => state = day;
}

final calendarFocusedDayProvider = NotifierProvider<DateTimeNotifier, DateTime>(
  DateTimeNotifier.new,
);

final calendarSelectedDayProvider =
    NotifierProvider<DateTimeNotifier, DateTime>(DateTimeNotifier.new);

// ---------------------------------------------------------------------------
// Calendar event display helpers
// ---------------------------------------------------------------------------

extension CalendarEventX on CalendarEvent {
  /// The inclusive last day/time of this event for display and bucketing.
  ///
  /// For all-day events the portal stores `end` as the exclusive next-day
  /// midnight (e.g. an event on Jan 5 has end = Jan 6 00:00:00). We subtract
  /// 1 ms so that bucketing treats Jan 5 as the last day, not Jan 6.
  ///
  /// For timed events the raw `end` is used as-is.
  ///
  /// Note: the DB overlap query in CalendarRepository._eventsOverlapping uses
  /// the raw `end` column, so boundary-events may appear in a wider DB slice
  /// than the bucketing below. This intentional mismatch is safe — the display
  /// layer only places events in the correct day buckets.
  ///
  /// Precondition: callers in [calendarEventsProvider] guard `event.start != null`
  /// before calling this getter.
  DateTime get displayEndDate {
    final e = end;
    if (e == null) return start!; // start is non-null at this call site

    if (allDay) {
      // All-day end is the exclusive next-day midnight; subtract 1 ms to keep
      // it within the correct day.
      final startDay = DateTime(start!.year, start!.month, start!.day);
      final endDay = DateTime(e.year, e.month, e.day);
      return endDay.isAfter(startDay)
          ? endDay.subtract(const Duration(milliseconds: 1))
          : startDay;
    }

    return e;
  }
}

// ---------------------------------------------------------------------------
// Range notifier — tracks the ±1-month window around the focused month.
// ---------------------------------------------------------------------------

/// Returns a [DateTimeRange] spanning from the start of the month before
/// [focus] to the end of the month two months after [focus].
///
/// Uses Dart's normalising DateTime constructor (day 0 = last day of the
/// previous month) to keep the arithmetic simple and correct across year
/// boundaries (e.g. month - 1 when month == 1 yields December of the
/// previous year).
DateTimeRange threeMonthWindow(DateTime focus) {
  return DateTimeRange(
    start: DateTime(focus.year, focus.month - 1, 1),
    end: DateTime(focus.year, focus.month + 2, 0),
  );
}

class CalendarRangeNotifier extends Notifier<DateTimeRange> {
  @override
  DateTimeRange build() => threeMonthWindow(DateTime.now());
  void updateRange(DateTimeRange range) => state = range;
}

final calendarRangeProvider =
    NotifierProvider<CalendarRangeNotifier, DateTimeRange>(
      CalendarRangeNotifier.new,
    );

// ---------------------------------------------------------------------------
// Events provider — maps normalized date integers to event lists.
// ---------------------------------------------------------------------------

/// Encodes a calendar date as a compact integer key to avoid the pitfall of
/// using [DateTime] objects (which include a time component) as map keys.
int dateKey(int year, int month, int day) => year * 10000 + month * 100 + day;

final calendarEventsProvider = FutureProvider<Map<int, List<CalendarEvent>>>((
  ref,
) async {
  final range = ref.watch(calendarRangeProvider);
  final repo = ref.watch(calendarRepositoryProvider);

  final events = await repo.getCalendar(
    startDate: range.start,
    endDate: range.end,
  );

  final map = <int, List<CalendarEvent>>{};
  for (final event in events) {
    if (event.start == null) continue;

    var current = DateTime(
      event.start!.year,
      event.start!.month,
      event.start!.day,
    );
    final adjustedEnd = event.displayEndDate;

    // If start and end coincide (zero-duration event), emit for exactly one day.
    final lastDay = adjustedEnd.isBefore(current) ? current : adjustedEnd;
    final last = DateTime(lastDay.year, lastDay.month, lastDay.day);

    while (!current.isAfter(last)) {
      map
          .putIfAbsent(
            dateKey(current.year, current.month, current.day),
            () => [],
          )
          .add(event);
      current = DateTime(current.year, current.month, current.day + 1);
    }
  }
  return map;
});
