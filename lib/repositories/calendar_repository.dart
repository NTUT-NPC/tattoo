import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tattoo/models/calendar.dart';
import 'package:tattoo/services/calendar_service.dart';
import 'package:tattoo/utils/http.dart';
import 'package:tattoo/utils/shared_preferences.dart';

const _calendarIcsCacheKey = 'calendar.ics.raw';
const _calendarIcsCachedAtKey = 'calendar.ics.cachedAt';

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  return CalendarRepository(
    prefs: ref.watch(sharedPreferencesProvider),
    calendarService: ref.watch(calendarServiceProvider),
  );
});

class CalendarRepository {
  final SharedPreferencesAsync _prefs;
  final CalendarService _calendarService;

  CalendarRepository({
    required SharedPreferencesAsync prefs,
    required CalendarService calendarService,
  }) : _prefs = prefs,
       _calendarService = calendarService;

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
