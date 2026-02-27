import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/models/calendar.dart';
import 'package:tattoo/repositories/calendar_repository.dart';

/// Screen-level provider that loads calendar events for [CalendarScreen].
final calendarEventsProvider = FutureProvider<CalendarSnapshot>((ref) async {
  final repository = ref.watch(calendarRepositoryProvider);
  return repository.getEvents();
});
