import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/repositories/calendar_repository.dart';

extension CalendarEventDisplay on CalendarEvent {
  /// The inclusive last day/time of this event for display and bucketing.
  ///
  /// NTUT stores all-day events with `end` set to next-day midnight
  /// (exclusive — an event on Jan 5 has end = Jan 6 00:00:00). Subtracting
  /// 1 ms makes bucketing treat Jan 5 as the last day, not Jan 6. Timed
  /// events have explicit non-midnight ends and are returned as-is — NTUT only
  /// emits midnight ends for all-day events.
  DateTime get displayEndDate {
    if (!allDay) return end;
    return end.isAfter(start)
        ? end.subtract(const Duration(milliseconds: 1))
        : start;
  }
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
