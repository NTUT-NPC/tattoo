import 'dart:developer';
import 'package:drift/drift.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/services/portal/portal_service.dart';

/// Provides the [CalendarRepository] instance.
final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  ref.watch(sessionProvider);
  return CalendarRepository(
    portalService: ref.watch(portalServiceProvider),
    database: ref.watch(databaseProvider),
    authRepository: ref.watch(authRepositoryProvider),
  );
});

/// Manages academic calendar events from the NTUT portal.
///
/// ```dart
/// final repo = ref.watch(calendarRepositoryProvider);
///
/// // Observe events overlapping a range (auto-refreshes when stale)
/// final stream = repo.watchCalendarEvents(
///   startDate: start,
///   endDate: end,
/// );
///
/// // Force refresh for pull-to-refresh; pass any date in the year to refetch.
/// await repo.refreshCalendarEvents(date: start);
/// ```
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

  /// Watches calendar events overlapping the given date range.
  ///
  /// Emits cached data immediately, then triggers a background network fetch
  /// if the cache is empty or stale. The stream re-emits automatically when
  /// the DB is updated.
  ///
  /// Network errors during background refresh are absorbed — the stream
  /// continues showing stale (or empty) data rather than erroring.
  Stream<List<CalendarEvent>> watchCalendarEvents({
    required DateTime startDate,
    required DateTime endDate,
  }) async* {
    const ttl = Duration(days: 1);

    await for (final events in _eventsOverlapping(startDate, endDate).watch()) {
      final user = await _database.select(_database.users).getSingleOrNull();
      if (user == null) {
        yield [];
        continue;
      }

      // calendarFetchedAt is authoritative for cache presence. A range query
      // may return [] when the academic year is cached but the requested
      // range has no events, so isEmpty isn't a reliable nil-check.
      if (user.calendarFetchedAt == null) {
        try {
          await refreshCalendarEvents(date: startDate);
        } catch (_) {
          // Absorb: yield below so UI exits loading state
        }
      }

      yield events;

      final freshUser = await _database
          .select(_database.users)
          .getSingleOrNull();
      final age = switch (freshUser?.calendarFetchedAt) {
        final t? => DateTime.now().difference(t),
        null => ttl,
      };
      if (age >= ttl) {
        try {
          await refreshCalendarEvents(date: startDate);
        } catch (_) {
          // Absorb: stale data is shown via stream
        }
      }
    }
  }

  /// Fetches fresh calendar data for the academic year containing [date] and
  /// writes it to the DB.
  ///
  /// The [watchCalendarEvents] stream automatically emits the updated value.
  /// Network errors propagate to the caller.
  Future<void> refreshCalendarEvents({required DateTime date}) async {
    final user = await _database.select(_database.users).getSingleOrNull();
    if (user == null) return;

    // Fetch the full academic year so subsequent range queries hit the cache.
    // NTUT academic years run Aug 1 → July 31.
    final wideStartDate = date.month < 8
        ? DateTime(date.year - 1, 8, 1)
        : DateTime(date.year, 8, 1);
    // Exclusive upper bound: Aug 1 of the next year.
    final wideEndDate = DateTime(wideStartDate.year + 1, 8, 1);

    // No SSO needed — getCalendar uses the portal session from login.
    final dtos = await _authRepository.withAuth(
      () => _portalService.getCalendar(wideStartDate, wideEndDate),
    );

    await _database.transaction(() async {
      final portalIds = dtos.map((e) => e.id).nonNulls.toSet();

      await _database.batch((batch) {
        for (final dto in dtos) {
          final id = dto.id;
          // Skip events without an ID — we can't sync or dedupe them.
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

      // Delete events in the fetched window that are no longer on the portal.
      // Use overlap semantics (consistent with read queries) so
      // boundary-spanning events are cleaned up too.
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

      await (_database.update(_database.users)
            ..where((u) => u.id.equals(user.id)))
          .write(UsersCompanion(calendarFetchedAt: Value(DateTime.now())));
    });
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
}
