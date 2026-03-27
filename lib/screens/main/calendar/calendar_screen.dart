import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/screens/main/calendar/calendar_providers.dart';
import 'package:tattoo/database/database.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusedDay = ref.watch(calendarFocusedDayProvider);
    final selectedDay = ref.watch(calendarSelectedDayProvider);
    final eventsAsyncValue = ref.watch(calendarEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.nav.calendar),
      ),
      body: eventsAsyncValue.when(
        skipLoadingOnReload: true,
        data: (eventsMap) {
          final selectedEvents = _getEventsForDay(eventsMap, selectedDay);

          return Column(
            children: [
              TableCalendar<CalendarEvent>(
                firstDay: DateTime(2020, 1, 1),
                lastDay: DateTime(2030, 12, 31),
                focusedDay: focusedDay,
                selectedDayPredicate: (day) => isSameDay(selectedDay, day),
                onDaySelected: (newSelectedDay, newFocusedDay) {
                  ref
                      .read(calendarSelectedDayProvider.notifier)
                      .updateDate(newSelectedDay);
                  ref
                      .read(calendarFocusedDayProvider.notifier)
                      .updateDate(newFocusedDay);
                },
                onPageChanged: (newFocusedDay) {
                  ref
                      .read(calendarFocusedDayProvider.notifier)
                      .updateDate(newFocusedDay);

                  // Expand the fetch range when the user navigates near the
                  // current window boundary so events are always pre-loaded.
                  final range = ref.read(calendarRangeProvider);
                  final atStart =
                      (newFocusedDay.year == range.start.year &&
                      newFocusedDay.month == range.start.month);
                  final atEnd =
                      (newFocusedDay.year == range.end.year &&
                      newFocusedDay.month == range.end.month);
                  final outOfRange =
                      newFocusedDay.isBefore(range.start) ||
                      newFocusedDay.isAfter(range.end);

                  if (atStart || atEnd || outOfRange) {
                    ref
                        .read(calendarRangeProvider.notifier)
                        .updateRange(threeMonthWindow(newFocusedDay));
                  }
                },
                eventLoader: (day) => _getEventsForDay(eventsMap, day),
                calendarFormat: CalendarFormat.month,
                availableCalendarFormats: {
                  CalendarFormat.month: t.calendar.month,
                },
              ),
              const SizedBox(height: 8.0),
              Expanded(
                child: ListView.builder(
                  itemCount: selectedEvents.length,
                  itemBuilder: (context, index) {
                    final event = selectedEvents[index];
                    final title = event.title ?? t.general.unknown;
                    final String formattedStart = event.start != null
                        ? _formatDate(event.start!)
                        : '?';
                    final String formattedEnd = event.end != null
                        ? _formatDate(event.displayEndDate)
                        : formattedStart;

                    final subtitleText = formattedStart == formattedEnd
                        ? formattedStart
                        : '$formattedStart – $formattedEnd';

                    return ListTile(
                      title: Text(title),
                      subtitle: Text(subtitleText),
                      trailing: event.place != null && event.place!.isNotEmpty
                          ? ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 120),
                              child: Text(
                                event.place!,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                              ),
                            )
                          : null,
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(t.errors.occurred)),
      ),
    );
  }

  List<CalendarEvent> _getEventsForDay(
    Map<int, List<CalendarEvent>> eventsMap,
    DateTime day,
  ) {
    return eventsMap[dateKey(day.year, day.month, day.day)] ?? [];
  }

  /// Formats a [DateTime] as `yyyy-MM-dd` using the `intl` package.
  String _formatDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
}
