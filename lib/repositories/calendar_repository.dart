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
    // calendarFetchedAt is authoritative for cache presence. The range-filtered
    // query below may return an empty list even when the full academic year is
    // cached (e.g. a future date range), so we must not use cached.isEmpty as
    // the nil-check — that would cause spurious network fetches.
    final hasCachedData = user?.calendarFetchedAt != null;
    final cached =
        await (_database.select(_database.calendarEvents)
              ..where((e) {
                // Include events that overlap with the range
                return e.start.isSmallerOrEqualValue(endDate) &
                    e.end.isBiggerOrEqualValue(startDate);
              })
              ..orderBy([(e) => OrderingTerm.asc(e.start)]))
            .get();

    return fetchWithTtl<List<CalendarEvent>>(
      cached: hasCachedData ? cached : null,
      getFetchedAt: (_) => user?.calendarFetchedAt,
      fetchFromNetwork: () => _fetchCalendarFromNetwork(startDate, endDate),
      refresh: refresh,
    );
  }

  Future<List<CalendarEvent>> _fetchCalendarFromNetwork(
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Fetch a wide range (full academic year) to ensure a complete cache for
    // the entire year, preventing partial range bugs on subsequent calls.
    // NTUT academic years run from Aug 1 to July 31.
    final wideStartDate = startDate.month < 8
        ? DateTime(startDate.year - 1, 8, 1)
        : DateTime(startDate.year, 8, 1);
    final wideEndDate = DateTime(wideStartDate.year + 1, 7, 31);

    // No SSO needed — getCalendar uses the portal session established at login.
    final dtos = await _authRepository.withAuth(
      () => _portalService.getCalendar(wideStartDate, wideEndDate),
    );

    // getUser() is non-null here because this repository is session-scoped
    // and only reachable after a successful login.
    final userId = (await _database.getUser())!.id;

    await _database.transaction(() async {
      final portalIds = dtos.map((e) => e.id).whereType<int>().toSet();

      for (final dto in dtos) {
        final id = dto.id;
        // portalId is nullable in the DTO (NTUT servers occasionally omit it).
        // Skip events without an ID — we can't sync or deduplicate them.
        if (id == null) continue;

        await _database
            .into(_database.calendarEvents)
            .insert(
              CalendarEventsCompanion.insert(
                portalId: id,
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

      // Sync: delete events in the fetched range that are no longer on the portal.
      await (_database.delete(_database.calendarEvents)..where((e) {
            return e.start.isBiggerOrEqualValue(wideStartDate) &
                e.end.isSmallerOrEqualValue(wideEndDate) &
                e.portalId.isNotIn(portalIds);
          }))
          .go();

      // Update the fetch timestamp for this user only.
      await (_database.update(_database.users)
            ..where((u) => u.id.equals(userId)))
          .write(UsersCompanion(calendarFetchedAt: Value(DateTime.now())));
    });

    // Re-fetch from DB to return only the originally requested range
    return (_database.select(_database.calendarEvents)
          ..where((e) {
            return e.start.isSmallerOrEqualValue(endDate) &
                e.end.isBiggerOrEqualValue(startDate);
          })
          ..orderBy([(e) => OrderingTerm.asc(e.start)]))
        .get();
  }
}
