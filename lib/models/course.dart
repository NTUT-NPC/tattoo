enum DayOfWeek {
  sunday,
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
}

// 第幾節課 (1-4,N,5-9,A-D)
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

enum CourseType {
  required('必'),
  elective('選'),
  general('通');

  final String code;
  const CourseType(this.code);
}

class EntityRef {
  final String? id;
  final String? name;

  EntityRef({this.id, this.name});
}

class CourseSchedule {
  final String? number;
  final EntityRef? course;
  final double? credits;
  final int? hours;
  final CourseType? type;
  final EntityRef? teacher;
  final List<EntityRef>? classes;
  final List<(DayOfWeek, Period)>? schedule;
  final EntityRef? classroom;
  final String? status;
  final String? language;
  final String? syllabusId;
  final String? remarks;

  CourseSchedule({
    this.number,
    this.course,
    this.credits,
    this.hours,
    this.type,
    this.teacher,
    this.classes,
    this.schedule,
    this.classroom,
    this.status,
    this.language,
    this.syllabusId,
    this.remarks,
  });
}
