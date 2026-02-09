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

/// Course type for graduation credit requirements (課程標準).
///
/// Symbols indicate both the credit category and whether it's required/elective:
/// - Shape: ○● (Dept), △▲ (University), ☆★ (Elective)
/// - Fill: Empty (Common), Filled (Major)
enum CourseType {
  /// ○ Dept. Common Required Credits (系共同必修).
  deptCommonRequired('○'),

  /// △ University Common Required Credits (校共同必修).
  universityCommonRequired('△'),

  /// ☆ Common Elective Credits (共同選修).
  commonElective('☆'),

  /// ● Dept. Major Required Credits (系專業必修).
  deptMajorRequired('●'),

  /// ▲ University Major Required Credits (校專業必修).
  universityMajorRequired('▲'),

  /// ★ Major Elective Credits (專業選修).
  majorElective('★');

  /// The symbol used on the syllabus page (修 column).
  final String symbol;
  const CourseType(this.symbol);
}

/// Reference to an entity (course, teacher, classroom, etc.) with an ID and name.
typedef ReferenceDto = ({
  /// Entity's unique identifier code.
  String? id,

  /// Entity's display name.
  String? name,
});

/// Academic semester identifier.
typedef SemesterDto = ({
  /// Academic year in ROC calendar (e.g., 114 for 2025).
  int? year,

  /// Semester number (1 for fall, 2 for spring, 3 for summer).
  int? semester,
});
