import 'package:riverpod/riverpod.dart';
import 'package:tattoo/services/calendar_service.dart';

/// Provides calendar events for the current year.
///
/// Fetches events from the calendar service and caches them.
final calendarEventsProvider =
    FutureProvider.autoDispose<List<CalendarEventDto>>((ref) async {
      final calendarService = ref.watch(calendarServiceProvider);

      // Fetch events for a reasonable range (1 year back, 1 year forward)
      final now = DateTime.now();
      final oneYearAgo = DateTime(now.year - 1, now.month, now.day);
      final oneYearLater = DateTime(now.year + 1, now.month, now.day);

      return calendarService.getEvents(
        timeMin: oneYearAgo,
        timeMax: oneYearLater,
      );
    });
