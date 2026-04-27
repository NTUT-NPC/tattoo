import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/screens/main/calendar/calendar_providers.dart';

final _dateFormatter = DateFormat('yyyy-MM-dd');

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  DateTimeRange _range = threeMonthWindow(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(calendarEventsProvider(_range));

    return Scaffold(
      appBar: AppBar(title: Text(t.nav.calendar)),
      body: eventsAsync.when(
        skipLoadingOnReload: true,
        data: (eventsMap) {
          final selectedKey = DateTime(
            _selectedDay.year,
            _selectedDay.month,
            _selectedDay.day,
          );
          final selectedEvents = eventsMap[selectedKey] ?? const [];

          return Column(
            children: [
              TableCalendar<CalendarEvent>(
                firstDay: DateTime(2020, 1, 1),
                lastDay: DateTime(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (newSelectedDay, newFocusedDay) {
                  setState(() {
                    _selectedDay = newSelectedDay;
                    _focusedDay = newFocusedDay;
                  });
                },
                onPageChanged: (newFocusedDay) {
                  setState(() {
                    _focusedDay = newFocusedDay;
                    if (newFocusedDay.isBefore(_range.start) ||
                        newFocusedDay.isAfter(_range.end)) {
                      _range = threeMonthWindow(newFocusedDay);
                    }
                  });
                },
                eventLoader: (day) =>
                    eventsMap[DateTime(day.year, day.month, day.day)] ??
                    const [],
                calendarFormat: CalendarFormat.month,
                headerStyle: const HeaderStyle(formatButtonVisible: false),
              ),
              const SizedBox(height: 8.0),
              Expanded(
                child: ListView.builder(
                  itemCount: selectedEvents.length,
                  itemBuilder: (context, index) {
                    final event = selectedEvents[index];
                    final start = _dateFormatter.format(event.start);
                    final end = _dateFormatter.format(event.displayEndDate);
                    final subtitle = start == end ? start : '$start – $end';

                    return ListTile(
                      title: Text(event.title ?? t.general.unknown),
                      subtitle: Text(subtitle),
                      trailing: switch (event.place) {
                        final place? => ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 120),
                          child: Text(
                            place,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                          ),
                        ),
                        _ => null,
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(t.errors.occurred)),
      ),
    );
  }
}
