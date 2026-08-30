/// Display state for a course in the home screen carousel.
enum NextCourseState { finished, ongoing, imminent, upcoming, scheduled }

/// A localized course summary displayed by the home screen carousel.
class NextCourse {
  const NextCourse({
    required this.title,
    required this.courseNumber,
    required this.teacher,
    required this.classroom,
    required this.time,
    required this.dayLabel,
    required this.state,
  });

  final String title;
  final String? courseNumber;
  final String teacher;
  final String classroom;
  final String time;
  final String dayLabel;
  final NextCourseState state;
}
