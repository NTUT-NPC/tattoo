import 'dart:async';

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
/// Caches a sliding window that spans the student's enrolled semesters plus
/// a short buffer — reads within that window hit the DB, so month-to-month
/// UI navigation never goes to the network.
///
/// ```dart
/// final repo = ref.watch(calendarRepositoryProvider);
///
/// final stream = repo.watchCalendarEvents(
///   startDate: start,
///   endDate: end,
/// );
///
/// await repo.refreshCalendarEvents(); // pull-to-refresh
/// ```
class CalendarRepository {
  final PortalService _portalService;
  final AppDatabase _database;
  final AuthRepository _authRepository;
  Completer<void>? _refreshInFlight;

  CalendarRepository({
    required PortalService portalService,
    required AppDatabase database,
    required AuthRepository authRepository,
  }) : _portalService = portalService,
       _database = database,
       _authRepository = authRepository;

  /// Watches calendar events overlapping the given date range.
  ///
  /// Reads events from the local DB and re-emits when the DB is updated. If
  /// the cached window is missing, stale, or doesn't cover the requested
  /// range (e.g., semester list just expanded), this stream awaits a refresh
  /// before yielding so it can populate or update the cache.
  ///
  /// Network errors during refresh are absorbed — the stream continues
  /// showing stale (or empty) data rather than erroring.
  Stream<List<CalendarEvent>> watchCalendarEvents({
    required DateTime startDate,
    required DateTime endDate,
  }) async* {
    const ttl = Duration(days: 1);

    // Gate: refreshCalendarEvents uses delete+insert, which reassigns
    // autoincrement IDs. Drift .watch() re-emits on every ID change, which
    // would re-trigger this branch forever for permanently out-of-window
    // requests that no refresh can ever cover.
    var refreshedForOutOfWindow = false;

    // Lazily computed and cached; re-read once when out-of-window to catch
    // semesters that landed after the stream started.
    (DateTime, DateTime)? window;

    await for (final events in _eventsOverlapping(startDate, endDate).watch()) {
      final user = await _database.select(_database.users).getSingleOrNull();
      if (user == null) {
        yield [];
        continue;
      }

      window ??= await _computeWindow();
      var (windowStart, windowEnd) = window;
      var outOfWindow =
          startDate.isBefore(windowStart) || endDate.isAfter(windowEnd);

      // If out of window, re-compute once in case the semester list expanded
      // since the stream started.
      if (outOfWindow && !refreshedForOutOfWindow) {
        window = await _computeWindow();
        (windowStart, windowEnd) = window;
        outOfWindow =
            startDate.isBefore(windowStart) || endDate.isAfter(windowEnd);
      }

      // calendarFetchedAt is authoritative for cache presence within the
      // window. For out-of-window requests, try once in case the window has
      // widened since the cached stamp (e.g., a newly enrolled semester).
      final shouldRefresh =
          user.calendarFetchedAt == null ||
          (outOfWindow && !refreshedForOutOfWindow);
      if (shouldRefresh) {
        if (outOfWindow) refreshedForOutOfWindow = true;
        try {
          await refreshCalendarEvents();
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
          await refreshCalendarEvents();
        } catch (_) {
          // Absorb: stale data is shown via stream
        }
      }
    }
  }

  /// Fetches fresh calendar data for the student's semester lifetime window
  /// and writes it to the DB.
  ///
  /// The [watchCalendarEvents] stream automatically emits the updated value.
  /// Network errors propagate to the caller.
  Future<void> refreshCalendarEvents() async {
    if (_refreshInFlight case final existing?) return existing.future;

    final completer = Completer<void>();
    _refreshInFlight = completer;
    try {
      final user = await _database.select(_database.users).getSingleOrNull();
      if (user == null) {
        completer.complete();
        return;
      }

      final (windowStart, windowEnd) = await _computeWindow();

      final dtos = await _authRepository.withAuth(
        () => _portalService.getCalendar(windowStart, windowEnd),
      );

      await _database.transaction(() async {
        // Clear the window first, then insert fresh data. Overlap semantics
        // (consistent with read queries) so boundary-spanning events are
        // cleaned up too.
        await (_database.delete(_database.calendarEvents)..where((e) {
              return e.start.isSmallerOrEqualValue(windowEnd) &
                  e.end.isBiggerOrEqualValue(windowStart);
            }))
            .go();

        // Skip events without an ID — we can't sync or dedupe them.
        final companions = dtos
            .where((dto) => dto.id != null)
            .map(
              (dto) => CalendarEventsCompanion.insert(
                portalId: dto.id!,
                start: dto.start,
                end: dto.end,
                allDay: Value(dto.allDay),
                title: Value(dto.title),
                place: Value(dto.place),
                content: Value(dto.content),
                ownerName: Value(dto.ownerName),
                creatorName: Value(dto.creatorName),
              ),
            )
            .toList();

        await _database.batch((batch) {
          batch.insertAll(_database.calendarEvents, companions);
        });

        await (_database.update(_database.users)
              ..where((u) => u.id.equals(user.id)))
            .write(UsersCompanion(calendarFetchedAt: Value(DateTime.now())));
      });

      completer.complete();
    } catch (e, st) {
      completer.completeError(e, st);
      rethrow;
    } finally {
      _refreshInFlight = null;
    }
  }

  /// Computes the fetch window from the student's enrolled semesters.
  ///
  /// Falls back to `now ± 6 months` when no semesters are known yet (e.g.,
  /// first login before [CourseRepository.refreshSemesters] has run). The
  /// window self-corrects on the next refresh once semester data lands.
  Future<(DateTime, DateTime)> _computeWindow() async {
    final semesters =
        await (_database.select(_database.semesters)
              ..where((s) => s.inCourseSemesterList.equals(true))
              ..orderBy([
                (s) => OrderingTerm.asc(s.year),
                (s) => OrderingTerm.asc(s.term),
              ]))
            .get();

    if (semesters.isEmpty) {
      final now = DateTime.now();
      return (
        DateTime(now.year, now.month - 6, 1),
        DateTime(now.year, now.month + 6, 1),
      );
    }

    final first = semesters.first;
    final last = semesters.last;
    return (
      _semesterStart(first.year, first.term),
      _semesterEnd(last.year, last.term).add(const Duration(days: 180)),
    );
  }

  /// Approximate start date of an NTUT semester.
  ///
  /// Conventions: term 0 = pre-study (Jul 1), 1 = fall (Aug 1), 2 = spring
  /// (Feb 1 of the next Western year), 3 = summer (Jul 1 of the next Western
  /// year). ROC year → AD by adding 1911.
  static DateTime _semesterStart(int rocYear, int term) {
    final adYear = rocYear + 1911;
    return switch (term) {
      0 => DateTime(adYear, 7, 1),
      1 => DateTime(adYear, 8, 1),
      2 => DateTime(adYear + 1, 2, 1),
      3 => DateTime(adYear + 1, 7, 1),
      _ => DateTime(adYear, 8, 1),
    };
  }

  /// Approximate end date of an NTUT semester.
  static DateTime _semesterEnd(int rocYear, int term) {
    final adYear = rocYear + 1911;
    return switch (term) {
      0 => DateTime(adYear, 7, 31),
      1 => DateTime(adYear + 1, 1, 31),
      2 => DateTime(adYear + 1, 7, 31),
      3 => DateTime(adYear + 1, 8, 31),
      _ => DateTime(adYear + 1, 1, 31),
    };
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
