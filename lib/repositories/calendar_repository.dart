import 'package:drift/drift.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/services/calendar_service.dart';

/// Result of fetching calendar events, including cache metadata.
typedef CalendarEventsResult = ({
  List<CalendarEventDto> events,
  DateTime? fetchedAt,
});

/// Provides the [CalendarRepository] instance.
final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  return CalendarRepository(
    calendarService: ref.watch(calendarServiceProvider),
    database: ref.watch(databaseProvider),
  );
});

/// Provides calendar events, backed by the local [CalendarEvents] table.
///
/// - On first launch (empty DB): fetches from network, shows loading spinner.
/// - On subsequent launches: returns DB rows immediately, no network call.
/// - Pull-to-refresh calls [CalendarRepository.refreshEvents] directly and
///   then invalidates this provider to rebuild with the new DB rows — the
///   loading state is never triggered because the DB already has data.
final calendarEventsProvider = FutureProvider<CalendarEventsResult>((
  ref,
) async {
  final repo = ref.watch(calendarRepositoryProvider);
  return repo.getEvents();
});

/// Manages calendar event persistence.
///
/// Events are fetched from the network only on first launch (empty DB) or
/// when the user explicitly pulls to refresh.  There is no automatic
/// background refresh.
class CalendarRepository {
  final CalendarService _calendarService;
  final AppDatabase _database;

  CalendarRepository({
    required CalendarService calendarService,
    required AppDatabase database,
  }) : _calendarService = calendarService,
       _database = database;

  /// Returns calendar events from the local DB.
  ///
  /// Fetches from the network only when the DB is empty (first launch).
  Future<CalendarEventsResult> getEvents() async {
    final cached = await _getCachedEvents();
    if (cached.isNotEmpty) {
      return (
        events: _rowsToDtos(cached),
        fetchedAt: cached.first.fetchedAt,
      );
    }

    // First launch: no local data, fetch from network.
    return _fetchAndStore();
  }

  /// Force-fetches from the network and replaces all local events.
  ///
  /// Called by pull-to-refresh. Throws on network failure so the caller
  /// can show an error snackbar.
  Future<CalendarEventsResult> refreshEvents() => _fetchAndStore();

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<List<CalendarEvent>> _getCachedEvents() => (_database.select(
    _database.calendarEvents,
  )..orderBy([(t) => OrderingTerm.asc(t.start)])).get();

  Future<CalendarEventsResult> _fetchAndStore() async {
    final now = DateTime.now();

    final timeMin = DateTime(now.year - 1, now.month, now.day);
    final timeMax = DateTime(now.year + 1, now.month, now.day);

    final dtos = await _calendarService.getEvents(
      timeMin: timeMin,
      timeMax: timeMax,
    );

    // Replace all cached rows atomically.
    await _database.transaction(() async {
      await _database.delete(_database.calendarEvents).go();
      await _database.batch((batch) {
        batch.insertAll(
          _database.calendarEvents,
          dtos.map(
            (dto) => CalendarEventsCompanion.insert(
              eventId: dto.id,
              summary: Value(dto.summary),
              description: Value(dto.description),
              location: Value(dto.location),
              start: Value(dto.start),
              end: Value(dto.end),
              fetchedAt: Value(now),
            ),
          ),
        );
      });
    });

    return (events: dtos, fetchedAt: now);
  }

  List<CalendarEventDto> _rowsToDtos(List<CalendarEvent> rows) {
    return rows
        .map(
          (row) => (
            id: row.eventId,
            summary: row.summary,
            description: row.description,
            location: row.location,
            start: row.start,
            end: row.end,
          ),
        )
        .toList();
  }
}
