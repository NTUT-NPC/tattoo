import 'dart:developer';
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
    if (user == null) return [];

    // calendarFetchedAt is authoritative for cache presence. The range-filtered
    // query below may return an empty list even when the full academic year is
    // cached (e.g. a future date range), so we must not use cached.isEmpty as
    // the nil-check — that would cause spurious network fetches.
    final hasCachedData = user.calendarFetchedAt != null;
    final cached = hasCachedData
        ? await _eventsOverlapping(startDate, endDate).get()
        : null;

    return fetchWithTtl<List<CalendarEvent>>(
      cached: cached,
      getFetchedAt: (_) => user.calendarFetchedAt,
      fetchFromNetwork: () =>
          _fetchCalendarFromNetwork(user.id, startDate, endDate),
      refresh: refresh,
    );
  }

  /// Selects calendar events that overlap with the given date range,
  /// ordered by start date ascending.
  SimpleSelectStatement<$CalendarEventsTable, CalendarEvent> _eventsOverlapping(
    DateTime startDate,
    DateTime endDate,
  ) {
    return _database.select(_database.calendarEvents)
      ..where(
        (e) =>
            e.start.isSmallerOrEqualValue(endDate) &
            e.end.isBiggerOrEqualValue(startDate),
      )
      ..orderBy([(e) => OrderingTerm.asc(e.start)]);
  }

  Future<List<CalendarEvent>> _fetchCalendarFromNetwork(
    int userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Fetch a wide range (full academic year) to ensure a complete cache for
    // the entire year, preventing partial range bugs on subsequent calls.
    // NTUT academic years run from Aug 1 to July 31.
    final wideStartDate = startDate.month < 8
        ? DateTime(startDate.year - 1, 8, 1)
        : DateTime(startDate.year, 8, 1);
    // Use the start of the next day (exclusive upper bound) so events ending
    // at any time on July 31 are included in the sync window.
    final wideEndDate = DateTime(wideStartDate.year + 1, 8, 1);

    // No SSO needed — getCalendar uses the portal session established at login.
    final dtos = await _authRepository.withAuth(
      () => _portalService.getCalendar(wideStartDate, wideEndDate),
    );

    await _database.transaction(() async {
      final portalIds = dtos.map((e) => e.id).whereType<int>().toSet();

      await _database.batch((batch) {
        for (final dto in dtos) {
          final id = dto.id;
          // portalId is nullable in the DTO (NTUT servers occasionally omit it).
          // Skip events without an ID — we can't sync or deduplicate them.
          if (id == null) continue;

          batch.insert(
            _database.calendarEvents,
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
      });

      // Sync: delete events in the fetched range that are no longer on the
      // portal. Use overlap semantics (consistent with read queries) so
      // boundary-spanning events are also cleaned up.
      if (portalIds.isNotEmpty) {
        await (_database.delete(_database.calendarEvents)..where((e) {
              return e.start.isSmallerOrEqualValue(wideEndDate) &
                  e.end.isBiggerOrEqualValue(wideStartDate) &
                  e.portalId.isNotIn(portalIds);
            }))
            .go();
      } else {
        // Portal returned no events (or none with IDs). This could be a
        // transient portal error, so log a warning before wiping the cache.
        log(
          'Portal returned 0 syncable events for '
          '${wideStartDate.toIso8601String()}–${wideEndDate.toIso8601String()}, '
          'clearing cached events in range',
          name: 'CalendarRepository',
        );
        await (_database.delete(_database.calendarEvents)..where((e) {
              return e.start.isSmallerOrEqualValue(wideEndDate) &
                  e.end.isBiggerOrEqualValue(wideStartDate);
            }))
            .go();
      }

      // Update the fetch timestamp for this user only.
      await (_database.update(_database.users)
            ..where((u) => u.id.equals(userId)))
          .write(UsersCompanion(calendarFetchedAt: Value(DateTime.now())));
    });

    // Re-fetch from DB to return only the originally requested range
    return _eventsOverlapping(startDate, endDate).get();
  }
}
