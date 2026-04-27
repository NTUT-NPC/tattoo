import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/repositories/calendar_repository.dart';

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
  /// the raw `end` column, so boundary events may appear in a wider DB slice
  /// than the bucketing below. This intentional mismatch is safe — the display
  /// layer only places events in the correct day buckets.
  DateTime get displayEndDate {
    if (!allDay) return end;
    return end.isAfter(start)
        ? end.subtract(const Duration(milliseconds: 1))
        : start;
  }
}

/// Returns a [DateTimeRange] spanning from the start of the month before
/// [focus] to the end of the month after [focus] (three months total).
///
/// Uses Dart's normalizing DateTime constructor (day 0 = last day of the
/// previous month) to keep the arithmetic simple and correct across year
/// boundaries (e.g. month - 1 when month == 1 yields December of the
/// previous year).
DateTimeRange threeMonthWindow(DateTime focus) {
  return DateTimeRange(
    start: DateTime(focus.year, focus.month - 1, 1),
    end: DateTime(focus.year, focus.month + 2, 0),
  );
}

/// Calendar events bucketed by day for the given [DateTimeRange].
///
/// Keys are normalized to local midnight so callers can look up a day with
/// `map[DateTime(d.year, d.month, d.day)]`.
final calendarEventsProvider = StreamProvider.autoDispose
    .family<Map<DateTime, List<CalendarEvent>>, DateTimeRange>((ref, range) {
      final repo = ref.watch(calendarRepositoryProvider);
      return repo
          .watchCalendarEvents(startDate: range.start, endDate: range.end)
          .map((events) {
            final map = <DateTime, List<CalendarEvent>>{};
            for (final event in events) {
              var current = DateTime(
                event.start.year,
                event.start.month,
                event.start.day,
              );
              final adjustedEnd = event.displayEndDate;
              final lastDay = adjustedEnd.isBefore(current)
                  ? current
                  : adjustedEnd;
              final last = DateTime(lastDay.year, lastDay.month, lastDay.day);

              while (!current.isAfter(last)) {
                map.putIfAbsent(current, () => []).add(event);
                current = DateTime(
                  current.year,
                  current.month,
                  current.day + 1,
                );
              }
            }
            return map;
          });
    });
