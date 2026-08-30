import 'package:tattoo/models/course.dart';
import 'package:tattoo/repositories/course_repository.dart';

/// A wall-clock time in the NTUT course schedule.
typedef CourseScheduleTime = ({int hour, int minute});

/// One concrete occurrence of a course-table entry on the current date.
typedef CourseScheduleMeeting = ({
  CourseTableCellData course,
  Period startPeriod,
  Period endPeriod,
  DateTime start,
  DateTime end,
  bool isOngoing,
});

/// Official NTUT class times for each [Period].
extension PeriodScheduleTime on Period {
  CourseScheduleTime get startTime => switch (this) {
    .first => (hour: 8, minute: 10),
    .second => (hour: 9, minute: 10),
    .third => (hour: 10, minute: 10),
    .fourth => (hour: 11, minute: 10),
    .nPeriod => (hour: 12, minute: 10),
    .fifth => (hour: 13, minute: 10),
    .sixth => (hour: 14, minute: 10),
    .seventh => (hour: 15, minute: 10),
    .eighth => (hour: 16, minute: 10),
    .ninth => (hour: 17, minute: 10),
    .aPeriod => (hour: 18, minute: 30),
    .bPeriod => (hour: 19, minute: 20),
    .cPeriod => (hour: 20, minute: 20),
    .dPeriod => (hour: 21, minute: 10),
  };

  CourseScheduleTime get endTime => switch (this) {
    .first => (hour: 9, minute: 0),
    .second => (hour: 10, minute: 0),
    .third => (hour: 11, minute: 0),
    .fourth => (hour: 12, minute: 0),
    .nPeriod => (hour: 13, minute: 0),
    .fifth => (hour: 14, minute: 0),
    .sixth => (hour: 15, minute: 0),
    .seventh => (hour: 16, minute: 0),
    .eighth => (hour: 17, minute: 0),
    .ninth => (hour: 18, minute: 0),
    .aPeriod => (hour: 19, minute: 20),
    .bPeriod => (hour: 20, minute: 10),
    .cPeriod => (hour: 21, minute: 10),
    .dPeriod => (hour: 22, minute: 0),
  };
}

/// Returns the final period occupied by a merged course-table cell.
Period courseMeetingEndPeriod({
  required Period startPeriod,
  required int span,
  required bool crossesNoon,
}) {
  if (span < 1) {
    throw ArgumentError.value(span, 'span', 'Must be at least 1');
  }

  var endIndex = startPeriod.index + span - 1;
  if (crossesNoon && endIndex >= Period.nPeriod.index) endIndex++;
  if (endIndex >= Period.values.length) {
    throw RangeError.range(
      endIndex,
      0,
      Period.values.length - 1,
      'span',
      'Course meeting extends beyond period D',
    );
  }

  return Period.values[endIndex];
}

/// Returns today's scheduled meetings in chronological order.
List<CourseScheduleMeeting> todayCourseMeetings(
  CourseTableData courseTable, {
  required DateTime now,
}) {
  final today = _dayOfWeek(now);
  final meetings =
      [
        for (final entry in courseTable.scheduled.entries)
          if (entry.key.day == today)
            _meetingFor(
              date: now,
              startPeriod: entry.key.period,
              course: entry.value,
              now: now,
            ),
      ]..sort((first, second) {
        final startComparison = first.start.compareTo(second.start);
        if (startComparison != 0) return startComparison;
        return first.course.id.compareTo(second.course.id);
      });

  return meetings;
}

/// Selects the card that should receive focus on the home carousel.
///
/// A course starting within [imminentThreshold] takes priority over an
/// overlapping ongoing course. Otherwise the ongoing course is preferred,
/// followed by the next course later today. Returns `null` after today's final
/// course has ended.
int? preferredTodayCourseIndex(
  List<CourseScheduleMeeting> meetings, {
  required DateTime now,
  Duration imminentThreshold = const Duration(minutes: 30),
}) {
  final imminentLimit = now.add(imminentThreshold);
  final imminentIndex = meetings.indexWhere(
    (meeting) =>
        meeting.start.isAfter(now) && !meeting.start.isAfter(imminentLimit),
  );
  if (imminentIndex >= 0) return imminentIndex;

  final ongoingIndex = meetings.indexWhere((meeting) => meeting.isOngoing);
  if (ongoingIndex >= 0) return ongoingIndex;

  final nextIndex = meetings.indexWhere(
    (meeting) => meeting.start.isAfter(now),
  );
  return nextIndex < 0 ? null : nextIndex;
}

CourseScheduleMeeting _meetingFor({
  required DateTime date,
  required Period startPeriod,
  required CourseTableCellData course,
  required DateTime now,
}) {
  final endPeriod = courseMeetingEndPeriod(
    startPeriod: startPeriod,
    span: course.span,
    crossesNoon: course.crossesNoon,
  );
  final start = _dateAtTime(date, startPeriod.startTime);
  final end = _dateAtTime(date, endPeriod.endTime);
  return (
    course: course,
    startPeriod: startPeriod,
    endPeriod: endPeriod,
    start: start,
    end: end,
    isOngoing: !now.isBefore(start) && now.isBefore(end),
  );
}

DateTime _dateAtTime(DateTime date, CourseScheduleTime time) =>
    switch (date.isUtc) {
      true => DateTime.utc(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
      false => DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    };

DayOfWeek _dayOfWeek(DateTime date) => switch (date.weekday) {
  DateTime.monday => .monday,
  DateTime.tuesday => .tuesday,
  DateTime.wednesday => .wednesday,
  DateTime.thursday => .thursday,
  DateTime.friday => .friday,
  DateTime.saturday => .saturday,
  DateTime.sunday => .sunday,
  _ => throw StateError('Unsupported weekday: ${date.weekday}'),
};
