import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tattoo/models/calendar.dart';
import 'package:tattoo/services/calendar_service.dart';
import 'package:tattoo/utils/http.dart';
import 'package:tattoo/utils/shared_preferences.dart';

/// SharedPreferences key for the raw ICS payload.
const _calendarIcsCacheKey = 'calendar.ics.raw';

/// SharedPreferences key for the timestamp when ICS cache was last updated.
const _calendarIcsCachedAtKey = 'calendar.ics.cachedAt';

/// Dependency-injected provider for [CalendarRepository].
final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  return CalendarRepository(
    prefs: ref.watch(sharedPreferencesProvider),
    calendarService: ref.watch(calendarServiceProvider),
  );
});

/// Repository for calendar event data.
///
/// This repository fetches events from Google Calendar ICS via [CalendarService],
/// persists the raw payload in local storage, and falls back to cached content
/// when the network request fails.
class CalendarRepository {
  final SharedPreferencesAsync _prefs;
  final CalendarService _calendarService;

  CalendarRepository({
    required SharedPreferencesAsync prefs,
    required CalendarService calendarService,
  }) : _prefs = prefs,
       _calendarService = calendarService;

  /// Returns calendar events with cache fallback behavior.
  ///
  /// Behavior summary:
  /// - If there is no local cache and `refresh` is false, fetch from network.
  /// - Otherwise, try network first.
  /// - On network failure, return cached events when cache exists.
  /// - Re-throw the network error if no cache is available.
  ///
  /// Note: Only [DioException] (network errors) is caught for fallback to cached ICS.
  /// Other errors (such as [StateError] for empty/invalid ICS, or parsing bugs) are NOT caught intentionally.
  ///
  /// Rationale: This app only keeps events for one day after they end, so the cache is always recent.
  /// If the server returns an empty or invalid feed, it's likely a real upstream problem (e.g., calendar deleted, access revoked, or a breaking change).
  /// In these cases, showing old data could mislead users (e.g., showing already-expired events as if they're current).
  ///
  /// Therefore, we only fallback to cache on network errors, not on data/logic errors, to avoid surfacing stale or misleading information.
  Future<CalendarSnapshot> getEvents({bool refresh = false}) async {
    final cachedRaw = await _prefs.getString(_calendarIcsCacheKey);
    final cachedAt = DateTime.tryParse(
      await _prefs.getString(_calendarIcsCachedAtKey) ?? '',
    );

    if (!refresh && cachedRaw == null) {
      return _fetchFromNetworkOrThrow();
    }

    try {
      return await _fetchFromNetworkOrThrow();
    } on DioException {
      if (cachedRaw == null) rethrow;

      return CalendarSnapshot(
        events: _calendarService
            .parseEvents(cachedRaw)
            .map(_mapToDomainEvent)
            .toList(),
        cachedAt: cachedAt,
        refreshedFromNetwork: false,
      );
    }
  }

  /// Fetches ICS from the network, parses events, and updates local cache.
  Future<CalendarSnapshot> _fetchFromNetworkOrThrow() async {
    final ics = await _calendarService.fetchCalendarIcs();
    final parsedEvents = _calendarService
        .parseEvents(ics)
        .map(_mapToDomainEvent)
        .toList();

    final now = DateTime.now();
    await _prefs.setString(_calendarIcsCacheKey, ics);
    await _prefs.setString(_calendarIcsCachedAtKey, now.toIso8601String());

    return CalendarSnapshot(
      events: parsedEvents,
      cachedAt: now,
      refreshedFromNetwork: true,
    );
  }

  /// Maps service DTO records to UI-facing [CalendarEvent] domain models.
  CalendarEvent _mapToDomainEvent(CalendarEventDto dto) {
    return CalendarEvent(
      id: dto.id,
      title: dto.title,
      location: dto.location,
      description: dto.description,
      start: dto.start,
      end: dto.end,
      isAllDay: dto.isAllDay,
    );
  }
}
