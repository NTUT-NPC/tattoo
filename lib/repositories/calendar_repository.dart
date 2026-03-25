import 'package:drift/drift.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/services/portal/portal_service.dart';
import 'package:tattoo/utils/fetch_with_ttl.dart';

/// Provides the [CalendarRepository] instance.
final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  // Clear repository state when the session ends
  ref.watch(sessionProvider);

  return CalendarRepository(
    portalService: ref.watch(portalServiceProvider),
    database: ref.watch(databaseProvider),
    authRepository: ref.watch(authRepositoryProvider),
  );
});

/// Manages academic calendar events from the NTUT portal.
class CalendarRepository {
  final PortalService _portalService;
  final AppDatabase _database;
  final AuthRepository _authRepository;

  CalendarRepository({
    required PortalService portalService,
    required AppDatabase database,
    required AuthRepository authRepository,
  }) : _portalService = portalService,
       _database = database,
       _authRepository = authRepository;

  /// Gets academic calendar events for the given date range.
  ///
  /// Returns cached data if fresh (within TTL). Set [refresh] to `true` to
  /// bypass TTL (pull-to-refresh).
  Future<List<CalendarEvent>> getCalendar({
    required DateTime startDate,
    required DateTime endDate,
    bool refresh = false,
  }) async {
    final user = await _database.getUser();
    final cached =
        await (_database.select(_database.calendarEvents)
              ..where((e) {
                // Include events that overlap with the range
                return e.start.isSmallerOrEqualValue(endDate) &
                    e.end.isGreaterOrEqualValue(startDate);
              })
              ..orderBy([(e) => OrderingTerm.asc(e.start)]))
            .get();

    return fetchWithTtl<List<CalendarEvent>>(
      // If we have any cached data for this range, pass it to TTL check.
      // Wide-range fetching ensures that if we have partial data, we likely
      // have the full academic year cached.
      cached: cached.isEmpty ? null : cached,
      getFetchedAt: (_) => user?.calendarFetchedAt,
      fetchFromNetwork: () => _fetchCalendarFromNetwork(startDate, endDate),
      refresh: refresh,
    );
  }

  Future<List<CalendarEvent>> _fetchCalendarFromNetwork(
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Recommendation 1: Fetch a wide range (full academic year) to ensure a
    // complete cache for the entire year, preventing partial range bugs.
    // NTUT academic years run from Aug 1 to July 31.
    final wideStartDate = startDate.month < 8
        ? DateTime(startDate.year - 1, 8, 1)
        : DateTime(startDate.year, 8, 1);
    final wideEndDate = DateTime(wideStartDate.year + 1, 7, 31);

    final dtos = await _authRepository.withAuth(
      () => _portalService.getCalendar(wideStartDate, wideEndDate),
    );

    await _database.transaction(() async {
      final portalIds = dtos.map((e) => e.id).whereType<int>().toSet();

      for (final dto in dtos) {
        final id = dto.id;
        if (id == null)
          continue; // Recommendation 2: Handle non-nullable portalId

        await _database
            .into(_database.calendarEvents)
            .insert(
              CalendarEventsCompanion.insert(
                portalId: Value(id),
                start: Value(dto.start),
                end: Value(dto.end),
                allDay: Value(dto.allDay),
                title: Value(dto.title),
                place: Value(dto.place),
                content: Value(dto.content),
                ownerName: Value(dto.ownerName),
                creatorName: Value(dto.creatorName),
              ),
              onConflict: DoUpdate(
                (old) => CalendarEventsCompanion(
                  start: Value(dto.start),
                  end: Value(dto.end),
                  allDay: Value(dto.allDay),
                  title: Value(dto.title),
                  place: Value(dto.place),
                  content: Value(dto.content),
                  ownerName: Value(dto.ownerName),
                  creatorName: Value(dto.creatorName),
                ),
                target: [_database.calendarEvents.portalId],
              ),
            );
      }

      // Recommendation 3: Sync by deleting events in the fetched range that
      // are no longer present on the portal.
      await (_database.delete(_database.calendarEvents)..where((e) {
            return e.start.isGreaterOrEqualValue(wideStartDate) &
                e.end.isSmallerOrEqualValue(wideEndDate) &
                e.portalId.isNotIn(portalIds);
          }))
          .go();

      // Update the global fetch timestamp for the calendar
      await _database
          .update(_database.users)
          .write(
            UsersCompanion(calendarFetchedAt: Value(DateTime.now())),
          );
    });

    // Re-fetch from DB to return only the originally requested range
    return (_database.select(_database.calendarEvents)
          ..where((e) {
            return e.start.isSmallerOrEqualValue(endDate) &
                e.end.isGreaterOrEqualValue(startDate);
          })
          ..orderBy([(e) => OrderingTerm.asc(e.start)]))
        .get();
  }
}
