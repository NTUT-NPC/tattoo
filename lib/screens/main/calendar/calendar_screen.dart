import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/screens/main/calendar/calendar_providers.dart';

final _dateFormatter = DateFormat('yyyy-MM-dd');

/// Returns a half-open [DateTimeRange] `[start, end)` covering the month
/// before [focus], the focus month, and the month after — three months total.
///
/// `start` is the first instant of the previous month; `end` is the first
/// instant of the month two months after [focus] (exclusive). The DB query
/// in [CalendarRepository] uses the same half-open convention.
DateTimeRange _threeMonthWindow(DateTime focus) {
  return DateTimeRange(
    start: DateTime(focus.year, focus.month - 1, 1),
    end: DateTime(focus.year, focus.month + 2, 1),
  );
}

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  static const _yearSpan = 5;

  DateTime _focusedDay = .now();
  DateTime _selectedDay = .now();
  DateTimeRange _range = _threeMonthWindow(.now());
  final DateTime _firstDay = DateTime(DateTime.now().year - _yearSpan, 1, 1);
  final DateTime _lastDay = DateTime(DateTime.now().year + _yearSpan, 12, 31);

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(calendarEventsProvider(_range));

    return Scaffold(
      appBar: AppBar(
        title: Text(t.nav.calendar),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: t.calendar.today,
            onPressed: _isOnToday() ? null : _goToToday,
          ),
        ],
      ),
      body: eventsAsync.when(
        skipLoadingOnReload: true,
        data: _buildBody,
        loading: () => _buildBody(const {}),
        // Network errors are absorbed in CalendarRepository.watchCalendarEvents,
        // so this path only fires on rare DB failures the user can't act on.
        // Match the about_screen pattern: silently degrade to an empty calendar.
        error: (_, _) => _buildBody(const {}),
      ),
    );
  }

  bool _isOnToday() {
    final today = DateTime.now();
    return _focusedDay.year == today.year &&
        _focusedDay.month == today.month &&
        isSameDay(_selectedDay, today);
  }

  void _goToToday() {
    final today = DateTime.now();
    setState(() {
      _selectedDay = today;
      _focusedDay = today;
      if (today.isBefore(_range.start) || !today.isBefore(_range.end)) {
        _range = _threeMonthWindow(today);
      }
    });
  }

  Widget _buildBody(Map<DateTime, List<CalendarEvent>> eventsMap) {
    final selectedKey = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );
    final selectedEvents = eventsMap[selectedKey] ?? const [];

    return Column(
      children: [
        TableCalendar<CalendarEvent>(
          firstDay: _firstDay,
          lastDay: _lastDay,
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (newSelectedDay, newFocusedDay) {
            setState(() {
              _selectedDay = newSelectedDay;
              _focusedDay = newFocusedDay;
              if (newSelectedDay.isBefore(_range.start) ||
                  !newSelectedDay.isBefore(_range.end)) {
                _range = _threeMonthWindow(newSelectedDay);
              }
            });
          },
          onPageChanged: (newFocusedDay) {
            setState(() {
              _focusedDay = newFocusedDay;
              if (newFocusedDay.isBefore(_range.start) ||
                  !newFocusedDay.isBefore(_range.end)) {
                _range = _threeMonthWindow(newFocusedDay);
              }
            });
          },
          eventLoader: (day) =>
              eventsMap[DateTime(day.year, day.month, day.day)] ?? const [],
          calendarFormat: .month,
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
                      overflow: .ellipsis,
                      textAlign: .end,
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
  }
}
