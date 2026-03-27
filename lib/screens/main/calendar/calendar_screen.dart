import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/screens/main/calendar/calendar_providers.dart';
import 'package:tattoo/database/database.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final focusedDay = ref.watch(calendarFocusedDayProvider);
    final eventsAsyncValue = ref.watch(calendarEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.nav.calendar),
      ),
      body: eventsAsyncValue.when(
        data: (eventsMap) {
          final selectedEvents = _getEventsForDay(
            eventsMap,
            _selectedDay ?? focusedDay,
          );

          return Column(
            children: [
              TableCalendar<CalendarEvent>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: focusedDay,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, newFocusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                  });
                  ref.read(calendarFocusedDayProvider.notifier).updateDate(newFocusedDay);
                },
                onPageChanged: (newFocusedDay) {
                  ref.read(calendarFocusedDayProvider.notifier).updateDate(newFocusedDay);

                  // Update range if needed
                  final range = ref.read(calendarRangeProvider);
                  if (newFocusedDay.isBefore(range.start) ||
                      newFocusedDay.isAfter(range.end)) {
                    ref
                        .read(calendarRangeProvider.notifier)
                        .updateRange(DateTimeRange(
                      start: DateTime(
                        newFocusedDay.year,
                        newFocusedDay.month - 1,
                        1,
                      ),
                      end: DateTime(
                        newFocusedDay.year,
                        newFocusedDay.month + 2,
                        0,
                      ),
                    ));
                  }
                },
                eventLoader: (day) {
                  return _getEventsForDay(eventsMap, day);
                },
                calendarFormat: CalendarFormat.month,
                availableCalendarFormats: const {
                  CalendarFormat.month: 'Month',
                },
              ),
              const SizedBox(height: 8.0),
              Expanded(
                child: ListView.builder(
                  itemCount: selectedEvents.length,
                  itemBuilder: (context, index) {
                    final event = selectedEvents[index];
                    final title = event.title ?? t.general.unknown;
                    final String formattedStart = event.start != null ? _formatDate(event.start!) : '?';
                    String formattedEnd = '?';
                    
                    if (event.end != null) {
                      var displayEnd = event.end!;
                      // If the event ends exactly at 00:00:00 of a day and isn't a zero-length event,
                      // the visual "end day" is actually the day before.
                      if (displayEnd.hour == 0 && 
                          displayEnd.minute == 0 && 
                          displayEnd.second == 0 && 
                          event.start != null && 
                          displayEnd.isAfter(event.start!)) {
                        displayEnd = displayEnd.subtract(const Duration(milliseconds: 1));
                      }
                      formattedEnd = _formatDate(displayEnd);
                    }
                    
                    final subtitleText = formattedStart == formattedEnd 
                        ? formattedStart 
                        : '$formattedStart - $formattedEnd';

                    return ListTile(
                      title: Text(title),
                      subtitle: Text(subtitleText),
                      trailing: event.place != null && event.place!.isNotEmpty
                          ? Text(event.place!)
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
    Map<DateTime, List<CalendarEvent>> eventsMap,
    DateTime day,
  ) {
    final date = DateTime(day.year, day.month, day.day);
    return eventsMap[date] ?? [];
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
