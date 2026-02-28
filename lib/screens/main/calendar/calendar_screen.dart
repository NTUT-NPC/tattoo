import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/models/calendar.dart';
import 'package:tattoo/screens/main/calendar/calendar_providers.dart';

/// Main calendar tab screen.
///
/// Displays upcoming events, supports pull-to-refresh, and shows cache status.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  bool _showEndedEvents = false;

  /// Reloads calendar data by invalidating and re-reading the provider.
  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(calendarEventsProvider);
    await ref.read(calendarEventsProvider.future);
  }

  void _toggleEndedEvents() {
    setState(() {
      _showEndedEvents = !_showEndedEvents;
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(calendarEventsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              centerTitle: true,
              title: Text(t.nav.calendar),
            ),
            ...eventsAsync.when(
              loading: () => const [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (error, _) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text('${t.calendar.loadFailed}\n$error'),
                  ),
                ),
              ],
              data: (snapshot) => _buildEventSlivers(context, snapshot),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEventSlivers(
    BuildContext context,
    CalendarSnapshot snapshot,
  ) {
    final now = DateTime.now();
    final groupedEvents = _groupAndSortEvents(snapshot.events, now);
    final activeEvents = groupedEvents.active;
    final endedEvents = groupedEvents.ended;

    final hasVisibleEvents = activeEvents.isNotEmpty || endedEvents.isNotEmpty;

    return [
      if (!snapshot.refreshedFromNetwork)
        _buildMetaTileSliver(
          context,
          text: t.calendar.offlineMode,
          topPadding: 12,
          bottomPadding: 0,
        ),
      if (snapshot.fetchedAt != null)
        _buildMetaTileSliver(
          context,
          text: t.calendar.updatedAt(
            date: DateFormat(
              'yyyy/MM/dd HH:mm',
            ).format(snapshot.fetchedAt!.toLocal()),
          ),
          topPadding: 8,
          bottomPadding: 4,
        ),
      if (!hasVisibleEvents)
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: Text(t.calendar.noUpcomingEvents)),
        )
      else ...[
        if (activeEvents.isNotEmpty)
          _buildEventCardSliver(
            activeEvents,
            top: 8,
            bottom: endedEvents.isNotEmpty ? 0 : 24,
          ),
        if (endedEvents.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            sliver: SliverToBoxAdapter(
              child: _EndedEventsSection(
                events: endedEvents,
                expanded: _showEndedEvents,
                onToggle: _toggleEndedEvents,
              ),
            ),
          ),
        if (_showEndedEvents && endedEvents.isNotEmpty)
          _buildEventCardSliver(
            endedEvents,
            top: 8,
            bottom: 24,
          )
        else
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    ];
  }

  Widget _buildEventCardSliver(
    List<CalendarEvent> events, {
    required double top,
    required double bottom,
  }) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16, top, 16, bottom),
      sliver: SliverList.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _CalendarEventCard(event: event),
          );
        },
      ),
    );
  }

  Widget _buildMetaTileSliver(
    BuildContext context, {
    required String text,
    required double topPadding,
    required double bottomPadding,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, topPadding, 16, bottomPadding),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          title: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ),
    );
  }

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

    final active = retainedEvents.where((event) => !_isEventEnded(event, now)).toList()
      ..sort((left, right) {
        final leftGroup = _eventSortGroup(left, now);
        final rightGroup = _eventSortGroup(right, now);

        if (leftGroup != rightGroup) {
          return leftGroup.compareTo(rightGroup);
        }

        if (leftGroup == 0) {
          final endCompare = _effectiveEnd(left).compareTo(_effectiveEnd(right));
          if (endCompare != 0) {
            return endCompare;
          }
        }

        return left.start.compareTo(right.start);
      });

    final ended = retainedEvents.where((event) => _isEventEnded(event, now)).toList()
      ..sort((left, right) => _effectiveEnd(right).compareTo(_effectiveEnd(left)));

    return (active: active, ended: ended);
  }
}

class _EndedEventsSection extends StatelessWidget {
  final List<CalendarEvent> events;
  final bool expanded;
  final VoidCallback onToggle;

  const _EndedEventsSection({
    required this.events,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onToggle,
        leading: const Icon(Icons.history),
        title: Text(t.calendar.endedEvents),
        subtitle: Text(t.calendar.endedEventsCount(count: events.length)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              expanded
                  ? t.calendar.collapseEndedEvents
                  : t.calendar.expandEndedEvents,
            ),
            const SizedBox(width: 4),
            Icon(expanded ? Icons.expand_less : Icons.expand_more),
          ],
        ),
      ),
    );
  }
}

/// Compact card widget for rendering one [CalendarEvent].
class _CalendarEventCard extends StatelessWidget {
  final CalendarEvent event;

  const _CalendarEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final colorScheme = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    final bodyStyle = Theme.of(context).textTheme.bodyMedium;
    final dateStyle = Theme.of(context).textTheme.titleSmall;
    final endedStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );
    final ongoingStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: colorScheme.onPrimaryContainer,
      fontWeight: FontWeight.w600,
    );
    final isEnded = _isEventEnded(event, now);
    final isOngoing = _isEventOngoing(event, now);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        title: Text(
          event.title,
          style: titleStyle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: isEnded
            ? Chip(
                label: Text(t.calendar.ended, style: endedStyle),
                backgroundColor: colorScheme.surface,
                side: BorderSide(color: colorScheme.outlineVariant),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )
            : isOngoing
            ? Chip(
                label: Text(t.calendar.ongoing, style: ongoingStyle),
                backgroundColor: colorScheme.primaryContainer,
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )
            : null,
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            Text(_formatTimeRange(event), style: dateStyle),
            if (event.location != null) ...[
              const SizedBox(height: 4),
              Text(event.location!, style: bodyStyle),
            ],
            if (event.description != null) ...[
              const SizedBox(height: 4),
              Text(
                event.description!,
                style: bodyStyle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Formats event dates as either a single day or a date range.
String _formatTimeRange(CalendarEvent event) {
  final startDate = DateTime(
    event.start.year,
    event.start.month,
    event.start.day,
  );

  final effective = _effectiveEnd(event);
  final endDate = DateTime(effective.year, effective.month, effective.day);

  final formatter = DateFormat('MM/dd');
  if (startDate == endDate) {
    return formatter.format(startDate);
  }

  return t.calendar.dateRange(
    start: formatter.format(startDate),
    end: formatter.format(endDate),
  );
}

/// Returns the inclusive end date for an all-day event.
///
/// ICS all-day events use an exclusive end date (e.g. a single-day event on
/// March 1 has DTEND=March 2). This subtracts one day when end > start to
/// convert to an inclusive end. For non-all-day events, returns [event.end]
/// unchanged.
DateTime _effectiveEnd(CalendarEvent event) {
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

bool _isEventOngoing(CalendarEvent event, DateTime now) {
  if (event.isAllDay) {
    final nowDate = DateTime(now.year, now.month, now.day);
    final startDate = DateTime(
      event.start.year,
      event.start.month,
      event.start.day,
    );
    return !nowDate.isBefore(startDate) &&
        !nowDate.isAfter(_effectiveEnd(event));
  }

  return !now.isBefore(event.start) && now.isBefore(event.end);
}

bool _isEventEnded(CalendarEvent event, DateTime now) {
  if (event.isAllDay) {
    final nowDate = DateTime(now.year, now.month, now.day);
    return nowDate.isAfter(_effectiveEnd(event));
  }

  return !now.isBefore(event.end);
}

int _eventSortGroup(CalendarEvent event, DateTime now) {
  if (_isEventOngoing(event, now)) return 0;
  if (_isEventEnded(event, now)) return 2;
  return 1;
}
