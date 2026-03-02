import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:tattoo/services/calendar_service.dart';
import 'package:tattoo/screens/main/calendar/calendar_providers.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(calendarEventsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              const Text('Failed to load events'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(calendarEventsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (events) => _buildCalendar(events),
      ),
    );
  }

  Widget _buildCalendar(List<CalendarEventDto> events) {
    // Group events by date for efficient lookup
    final eventsByDate = groupEventsByDate(events);
    final selectedEvents = _getEventsForDay(_selectedDay, eventsByDate);

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(calendarEventsProvider.future),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: TableCalendar<CalendarEventDto>(
              firstDay: DateTime.utc(2019, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              locale: 'zh_TW',
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: (day) => _getEventsForDay(day, eventsByDate),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              daysOfWeekHeight: 24,
              calendarStyle: CalendarStyle(
                markersMaxCount: 3,
                markerDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: Divider(height: 1)),
          if (selectedEvents.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  'No events on this day',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(8),
              sliver: SliverList.builder(
                itemCount: selectedEvents.length,
                itemBuilder: (context, index) {
                  final event = selectedEvents[index];
                  return _EventCard(event: event);
                },
              ),
            ),
        ],
      ),
    );
  }

  List<CalendarEventDto> _getEventsForDay(
    DateTime? day,
    Map<DateTime, List<CalendarEventDto>> eventsByDate,
  ) {
    if (day == null) return [];
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return eventsByDate[normalizedDay] ?? [];
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final CalendarEventDto event;

  void _showEventDetails(BuildContext context) {
    final hasDescription =
        event.description != null && event.description!.isNotEmpty;
    final hasLocation = event.location != null && event.location!.isNotEmpty;
    final timeText = event.formatTime();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.25,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  event.summary ?? 'Unknown',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                if (timeText.isNotEmpty) ...[
                  Text(
                    timeText,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                ],
                if (hasLocation) ...[
                  Text(
                    event.location!,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                ],
                if (hasDescription) ...[
                  const Divider(height: 32),
                  Text(
                    event.description!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (!hasLocation && !hasDescription) ...[
                  const SizedBox(height: 8),
                  Text(
                    'No additional details',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeText = event.formatTime();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showEventDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.summary ?? 'Unknown',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (timeText.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        timeText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
