import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/models/calendar.dart';
import 'package:tattoo/repositories/calendar_repository.dart';

final calendarEventsProvider = FutureProvider<CalendarSnapshot>((ref) async {
  final repository = ref.watch(calendarRepositoryProvider);
  return repository.getEvents();
});
