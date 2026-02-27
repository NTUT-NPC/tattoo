import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/models/calendar.dart';
import 'package:tattoo/screens/main/calendar/calendar_providers.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(calendarEventsProvider);
    await ref.read(calendarEventsProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(calendarEventsProvider);

    return Scaffold(
      body: eventsAsync.when(
        loading: () => CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              centerTitle: true,
              title: Text(t.nav.calendar),
            ),
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
        error: (error, _) => CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              centerTitle: true,
              title: Text(t.nav.calendar),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('${t.calendar.loadFailed}\n$error')),
            ),
          ],
        ),
        data: (snapshot) {
          final now = DateTime.now();
          final events = snapshot.events
              .where(
                (event) =>
                    event.end.isAfter(now.subtract(const Duration(days: 1))),
              )
              .toList();

          return RefreshIndicator(
            onRefresh: () => _refresh(ref),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  centerTitle: true,
                  title: Text(t.nav.calendar),
                ),
                if (!snapshot.refreshedFromNetwork)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Text(
                        t.calendar.offlineMode,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                if (snapshot.cachedAt != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(
                        t.calendar.updatedAt(
                          date: DateFormat(
                            'yyyy/MM/dd HH:mm',
                          ).format(snapshot.cachedAt!.toLocal()),
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                if (events.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text(t.calendar.noUpcomingEvents)),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CalendarEventCard extends StatelessWidget {
  final CalendarEvent event;

  const _CalendarEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    final bodyStyle = Theme.of(context).textTheme.bodyMedium;
    final dateStyle = Theme.of(context).textTheme.titleSmall;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.title, style: titleStyle),
            const SizedBox(height: 6),
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

  String _formatTimeRange(CalendarEvent event) {
    final startDate = DateTime(
      event.start.year,
      event.start.month,
      event.start.day,
    );
    var endDate = DateTime(event.end.year, event.end.month, event.end.day);

    if (event.isAllDay && endDate.isAfter(startDate)) {
      endDate = endDate.subtract(const Duration(days: 1));
    }

    final formatter = DateFormat('MM/dd');
    if (startDate == endDate) {
      return formatter.format(startDate);
    }

    return t.calendar.dateRange(
      start: formatter.format(startDate),
      end: formatter.format(endDate),
    );
  }
}
