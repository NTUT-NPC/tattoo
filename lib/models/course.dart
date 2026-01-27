/// Day of the week for class schedules.
enum DayOfWeek {
  sunday,
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
}

/// Class period within a day, following NTUT's schedule structure.
///
/// NTUT uses periods 1-4, N (noon), 5-9, and A-D:
/// - 1-4: Morning periods
/// - N: Noon period
/// - 5-9: Afternoon periods
/// - A-D: Evening periods
enum Period {
  first('1'),
  second('2'),
  third('3'),
  fourth('4'),
  nPeriod('N'),
  fifth('5'),
  sixth('6'),
  seventh('7'),
  eighth('8'),
  ninth('9'),
  aPeriod('A'),
  bPeriod('B'),
  cPeriod('C'),
  dPeriod('D');

  final String code;
  const Period(this.code);
}

/// Type of course for graduation requirements.
enum CourseType {
  /// Required course for the major/program.
  required,

  /// Elective course within the major/program.
  elective,

  /// General education course.
  general,
}
