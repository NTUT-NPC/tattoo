// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $StudentsTable extends Students with TableInfo<$StudentsTable, Student> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StudentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _studentIdMeta = const VerificationMeta(
    'studentId',
  );
  @override
  late final GeneratedColumn<String> studentId = GeneratedColumn<String>(
    'student_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, studentId, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'students';
  @override
  VerificationContext validateIntegrity(
    Insertable<Student> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('student_id')) {
      context.handle(
        _studentIdMeta,
        studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_studentIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Student map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Student(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      studentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}student_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
    );
  }

  @override
  $StudentsTable createAlias(String alias) {
    return $StudentsTable(attachedDatabase, alias);
  }
}

class Student extends DataClass implements Insertable<Student> {
  /// Auto-incrementing primary key.
  final int id;

  /// Unique student ID (學號).
  final String studentId;

  /// Student's name.
  ///
  /// Nullable because some students in I-School Plus rosters have no name
  /// recorded (e.g., student 110440001 in course 292704).
  final String? name;
  const Student({required this.id, required this.studentId, this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['student_id'] = Variable<String>(studentId);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    return map;
  }

  StudentsCompanion toCompanion(bool nullToAbsent) {
    return StudentsCompanion(
      id: Value(id),
      studentId: Value(studentId),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
    );
  }

  factory Student.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Student(
      id: serializer.fromJson<int>(json['id']),
      studentId: serializer.fromJson<String>(json['studentId']),
      name: serializer.fromJson<String?>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'studentId': serializer.toJson<String>(studentId),
      'name': serializer.toJson<String?>(name),
    };
  }

  Student copyWith({
    int? id,
    String? studentId,
    Value<String?> name = const Value.absent(),
  }) => Student(
    id: id ?? this.id,
    studentId: studentId ?? this.studentId,
    name: name.present ? name.value : this.name,
  );
  Student copyWithCompanion(StudentsCompanion data) {
    return Student(
      id: data.id.present ? data.id.value : this.id,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Student(')
          ..write('id: $id, ')
          ..write('studentId: $studentId, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, studentId, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Student &&
          other.id == this.id &&
          other.studentId == this.studentId &&
          other.name == this.name);
}

class StudentsCompanion extends UpdateCompanion<Student> {
  final Value<int> id;
  final Value<String> studentId;
  final Value<String?> name;
  const StudentsCompanion({
    this.id = const Value.absent(),
    this.studentId = const Value.absent(),
    this.name = const Value.absent(),
  });
  StudentsCompanion.insert({
    this.id = const Value.absent(),
    required String studentId,
    this.name = const Value.absent(),
  }) : studentId = Value(studentId);
  static Insertable<Student> custom({
    Expression<int>? id,
    Expression<String>? studentId,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (studentId != null) 'student_id': studentId,
      if (name != null) 'name': name,
    });
  }

  StudentsCompanion copyWith({
    Value<int>? id,
    Value<String>? studentId,
    Value<String?>? name,
  }) {
    return StudentsCompanion(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      name: name ?? this.name,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<String>(studentId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudentsCompanion(')
          ..write('id: $id, ')
          ..write('studentId: $studentId, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $SemestersTable extends Semesters
    with TableInfo<$SemestersTable, Semester> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SemestersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _semesterMeta = const VerificationMeta(
    'semester',
  );
  @override
  late final GeneratedColumn<int> semester = GeneratedColumn<int>(
    'semester',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, year, semester];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'semesters';
  @override
  VerificationContext validateIntegrity(
    Insertable<Semester> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('semester')) {
      context.handle(
        _semesterMeta,
        semester.isAcceptableOrUnknown(data['semester']!, _semesterMeta),
      );
    } else if (isInserting) {
      context.missing(_semesterMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {year, semester},
  ];
  @override
  Semester map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Semester(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      )!,
      semester: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}semester'],
      )!,
    );
  }

  @override
  $SemestersTable createAlias(String alias) {
    return $SemestersTable(attachedDatabase, alias);
  }
}

class Semester extends DataClass implements Insertable<Semester> {
  /// Auto-incrementing primary key.
  final int id;

  /// Academic year in ROC calendar (e.g., 114 for 2025).
  final int year;

  /// Semester number within the year (1=Fall, 2=Spring, 3=Summer).
  final int semester;
  const Semester({
    required this.id,
    required this.year,
    required this.semester,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['year'] = Variable<int>(year);
    map['semester'] = Variable<int>(semester);
    return map;
  }

  SemestersCompanion toCompanion(bool nullToAbsent) {
    return SemestersCompanion(
      id: Value(id),
      year: Value(year),
      semester: Value(semester),
    );
  }

  factory Semester.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Semester(
      id: serializer.fromJson<int>(json['id']),
      year: serializer.fromJson<int>(json['year']),
      semester: serializer.fromJson<int>(json['semester']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'year': serializer.toJson<int>(year),
      'semester': serializer.toJson<int>(semester),
    };
  }

  Semester copyWith({int? id, int? year, int? semester}) => Semester(
    id: id ?? this.id,
    year: year ?? this.year,
    semester: semester ?? this.semester,
  );
  Semester copyWithCompanion(SemestersCompanion data) {
    return Semester(
      id: data.id.present ? data.id.value : this.id,
      year: data.year.present ? data.year.value : this.year,
      semester: data.semester.present ? data.semester.value : this.semester,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Semester(')
          ..write('id: $id, ')
          ..write('year: $year, ')
          ..write('semester: $semester')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, year, semester);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Semester &&
          other.id == this.id &&
          other.year == this.year &&
          other.semester == this.semester);
}

class SemestersCompanion extends UpdateCompanion<Semester> {
  final Value<int> id;
  final Value<int> year;
  final Value<int> semester;
  const SemestersCompanion({
    this.id = const Value.absent(),
    this.year = const Value.absent(),
    this.semester = const Value.absent(),
  });
  SemestersCompanion.insert({
    this.id = const Value.absent(),
    required int year,
    required int semester,
  }) : year = Value(year),
       semester = Value(semester);
  static Insertable<Semester> custom({
    Expression<int>? id,
    Expression<int>? year,
    Expression<int>? semester,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (year != null) 'year': year,
      if (semester != null) 'semester': semester,
    });
  }

  SemestersCompanion copyWith({
    Value<int>? id,
    Value<int>? year,
    Value<int>? semester,
  }) {
    return SemestersCompanion(
      id: id ?? this.id,
      year: year ?? this.year,
      semester: semester ?? this.semester,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (semester.present) {
      map['semester'] = Variable<int>(semester.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SemestersCompanion(')
          ..write('id: $id, ')
          ..write('year: $year, ')
          ..write('semester: $semester')
          ..write(')'))
        .toString();
  }
}

class $CoursesTable extends Courses with TableInfo<$CoursesTable, Course> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CoursesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _creditsMeta = const VerificationMeta(
    'credits',
  );
  @override
  late final GeneratedColumn<double> credits = GeneratedColumn<double>(
    'credits',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hoursMeta = const VerificationMeta('hours');
  @override
  late final GeneratedColumn<int> hours = GeneratedColumn<int>(
    'hours',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameZhMeta = const VerificationMeta('nameZh');
  @override
  late final GeneratedColumn<String> nameZh = GeneratedColumn<String>(
    'name_zh',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionEnMeta = const VerificationMeta(
    'descriptionEn',
  );
  @override
  late final GeneratedColumn<String> descriptionEn = GeneratedColumn<String>(
    'description_en',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionZhMeta = const VerificationMeta(
    'descriptionZh',
  );
  @override
  late final GeneratedColumn<String> descriptionZh = GeneratedColumn<String>(
    'description_zh',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fetchedAt,
    code,
    credits,
    hours,
    nameEn,
    nameZh,
    descriptionEn,
    descriptionZh,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'courses';
  @override
  VerificationContext validateIntegrity(
    Insertable<Course> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('credits')) {
      context.handle(
        _creditsMeta,
        credits.isAcceptableOrUnknown(data['credits']!, _creditsMeta),
      );
    } else if (isInserting) {
      context.missing(_creditsMeta);
    }
    if (data.containsKey('hours')) {
      context.handle(
        _hoursMeta,
        hours.isAcceptableOrUnknown(data['hours']!, _hoursMeta),
      );
    } else if (isInserting) {
      context.missing(_hoursMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    }
    if (data.containsKey('name_zh')) {
      context.handle(
        _nameZhMeta,
        nameZh.isAcceptableOrUnknown(data['name_zh']!, _nameZhMeta),
      );
    }
    if (data.containsKey('description_en')) {
      context.handle(
        _descriptionEnMeta,
        descriptionEn.isAcceptableOrUnknown(
          data['description_en']!,
          _descriptionEnMeta,
        ),
      );
    }
    if (data.containsKey('description_zh')) {
      context.handle(
        _descriptionZhMeta,
        descriptionZh.isAcceptableOrUnknown(
          data['description_zh']!,
          _descriptionZhMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Course map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Course(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      ),
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      credits: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}credits'],
      )!,
      hours: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hours'],
      )!,
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      ),
      nameZh: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_zh'],
      ),
      descriptionEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description_en'],
      ),
      descriptionZh: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description_zh'],
      ),
    );
  }

  @override
  $CoursesTable createAlias(String alias) {
    return $CoursesTable(attachedDatabase, alias);
  }
}

class Course extends DataClass implements Insertable<Course> {
  /// Auto-incrementing primary key.
  final int id;

  /// Timestamp of when complete data was last fetched from the server.
  ///
  /// - `null`: Only partial/basic information is available (e.g., name + ID from a list page)
  /// - `non-null`: Complete details have been fetched (e.g., full profile from detail page)
  ///
  /// Use this field to:
  /// - Determine if a detail fetch is needed (null = need to fetch)
  /// - Implement cache expiration (old timestamp = stale, re-fetch)
  final DateTime? fetchedAt;

  /// Unique course code (e.g., "3004130", "3602012", "AC23502", "1001002").
  final String code;

  /// Number of credits awarded for completing this course.
  final double credits;

  /// Number of class hours per week.
  final int hours;

  /// Course name in English.
  final String? nameEn;

  /// Course name in Traditional Chinese.
  final String? nameZh;

  /// Course description in English.
  final String? descriptionEn;

  /// Course description in Traditional Chinese.
  final String? descriptionZh;
  const Course({
    required this.id,
    this.fetchedAt,
    required this.code,
    required this.credits,
    required this.hours,
    this.nameEn,
    this.nameZh,
    this.descriptionEn,
    this.descriptionZh,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || fetchedAt != null) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt);
    }
    map['code'] = Variable<String>(code);
    map['credits'] = Variable<double>(credits);
    map['hours'] = Variable<int>(hours);
    if (!nullToAbsent || nameEn != null) {
      map['name_en'] = Variable<String>(nameEn);
    }
    if (!nullToAbsent || nameZh != null) {
      map['name_zh'] = Variable<String>(nameZh);
    }
    if (!nullToAbsent || descriptionEn != null) {
      map['description_en'] = Variable<String>(descriptionEn);
    }
    if (!nullToAbsent || descriptionZh != null) {
      map['description_zh'] = Variable<String>(descriptionZh);
    }
    return map;
  }

  CoursesCompanion toCompanion(bool nullToAbsent) {
    return CoursesCompanion(
      id: Value(id),
      fetchedAt: fetchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(fetchedAt),
      code: Value(code),
      credits: Value(credits),
      hours: Value(hours),
      nameEn: nameEn == null && nullToAbsent
          ? const Value.absent()
          : Value(nameEn),
      nameZh: nameZh == null && nullToAbsent
          ? const Value.absent()
          : Value(nameZh),
      descriptionEn: descriptionEn == null && nullToAbsent
          ? const Value.absent()
          : Value(descriptionEn),
      descriptionZh: descriptionZh == null && nullToAbsent
          ? const Value.absent()
          : Value(descriptionZh),
    );
  }

  factory Course.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Course(
      id: serializer.fromJson<int>(json['id']),
      fetchedAt: serializer.fromJson<DateTime?>(json['fetchedAt']),
      code: serializer.fromJson<String>(json['code']),
      credits: serializer.fromJson<double>(json['credits']),
      hours: serializer.fromJson<int>(json['hours']),
      nameEn: serializer.fromJson<String?>(json['nameEn']),
      nameZh: serializer.fromJson<String?>(json['nameZh']),
      descriptionEn: serializer.fromJson<String?>(json['descriptionEn']),
      descriptionZh: serializer.fromJson<String?>(json['descriptionZh']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fetchedAt': serializer.toJson<DateTime?>(fetchedAt),
      'code': serializer.toJson<String>(code),
      'credits': serializer.toJson<double>(credits),
      'hours': serializer.toJson<int>(hours),
      'nameEn': serializer.toJson<String?>(nameEn),
      'nameZh': serializer.toJson<String?>(nameZh),
      'descriptionEn': serializer.toJson<String?>(descriptionEn),
      'descriptionZh': serializer.toJson<String?>(descriptionZh),
    };
  }

  Course copyWith({
    int? id,
    Value<DateTime?> fetchedAt = const Value.absent(),
    String? code,
    double? credits,
    int? hours,
    Value<String?> nameEn = const Value.absent(),
    Value<String?> nameZh = const Value.absent(),
    Value<String?> descriptionEn = const Value.absent(),
    Value<String?> descriptionZh = const Value.absent(),
  }) => Course(
    id: id ?? this.id,
    fetchedAt: fetchedAt.present ? fetchedAt.value : this.fetchedAt,
    code: code ?? this.code,
    credits: credits ?? this.credits,
    hours: hours ?? this.hours,
    nameEn: nameEn.present ? nameEn.value : this.nameEn,
    nameZh: nameZh.present ? nameZh.value : this.nameZh,
    descriptionEn: descriptionEn.present
        ? descriptionEn.value
        : this.descriptionEn,
    descriptionZh: descriptionZh.present
        ? descriptionZh.value
        : this.descriptionZh,
  );
  Course copyWithCompanion(CoursesCompanion data) {
    return Course(
      id: data.id.present ? data.id.value : this.id,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      code: data.code.present ? data.code.value : this.code,
      credits: data.credits.present ? data.credits.value : this.credits,
      hours: data.hours.present ? data.hours.value : this.hours,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      nameZh: data.nameZh.present ? data.nameZh.value : this.nameZh,
      descriptionEn: data.descriptionEn.present
          ? data.descriptionEn.value
          : this.descriptionEn,
      descriptionZh: data.descriptionZh.present
          ? data.descriptionZh.value
          : this.descriptionZh,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Course(')
          ..write('id: $id, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('code: $code, ')
          ..write('credits: $credits, ')
          ..write('hours: $hours, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameZh: $nameZh, ')
          ..write('descriptionEn: $descriptionEn, ')
          ..write('descriptionZh: $descriptionZh')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    fetchedAt,
    code,
    credits,
    hours,
    nameEn,
    nameZh,
    descriptionEn,
    descriptionZh,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Course &&
          other.id == this.id &&
          other.fetchedAt == this.fetchedAt &&
          other.code == this.code &&
          other.credits == this.credits &&
          other.hours == this.hours &&
          other.nameEn == this.nameEn &&
          other.nameZh == this.nameZh &&
          other.descriptionEn == this.descriptionEn &&
          other.descriptionZh == this.descriptionZh);
}

class CoursesCompanion extends UpdateCompanion<Course> {
  final Value<int> id;
  final Value<DateTime?> fetchedAt;
  final Value<String> code;
  final Value<double> credits;
  final Value<int> hours;
  final Value<String?> nameEn;
  final Value<String?> nameZh;
  final Value<String?> descriptionEn;
  final Value<String?> descriptionZh;
  const CoursesCompanion({
    this.id = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.code = const Value.absent(),
    this.credits = const Value.absent(),
    this.hours = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.nameZh = const Value.absent(),
    this.descriptionEn = const Value.absent(),
    this.descriptionZh = const Value.absent(),
  });
  CoursesCompanion.insert({
    this.id = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    required String code,
    required double credits,
    required int hours,
    this.nameEn = const Value.absent(),
    this.nameZh = const Value.absent(),
    this.descriptionEn = const Value.absent(),
    this.descriptionZh = const Value.absent(),
  }) : code = Value(code),
       credits = Value(credits),
       hours = Value(hours);
  static Insertable<Course> custom({
    Expression<int>? id,
    Expression<DateTime>? fetchedAt,
    Expression<String>? code,
    Expression<double>? credits,
    Expression<int>? hours,
    Expression<String>? nameEn,
    Expression<String>? nameZh,
    Expression<String>? descriptionEn,
    Expression<String>? descriptionZh,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (code != null) 'code': code,
      if (credits != null) 'credits': credits,
      if (hours != null) 'hours': hours,
      if (nameEn != null) 'name_en': nameEn,
      if (nameZh != null) 'name_zh': nameZh,
      if (descriptionEn != null) 'description_en': descriptionEn,
      if (descriptionZh != null) 'description_zh': descriptionZh,
    });
  }

  CoursesCompanion copyWith({
    Value<int>? id,
    Value<DateTime?>? fetchedAt,
    Value<String>? code,
    Value<double>? credits,
    Value<int>? hours,
    Value<String?>? nameEn,
    Value<String?>? nameZh,
    Value<String?>? descriptionEn,
    Value<String?>? descriptionZh,
  }) {
    return CoursesCompanion(
      id: id ?? this.id,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      code: code ?? this.code,
      credits: credits ?? this.credits,
      hours: hours ?? this.hours,
      nameEn: nameEn ?? this.nameEn,
      nameZh: nameZh ?? this.nameZh,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      descriptionZh: descriptionZh ?? this.descriptionZh,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (credits.present) {
      map['credits'] = Variable<double>(credits.value);
    }
    if (hours.present) {
      map['hours'] = Variable<int>(hours.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (nameZh.present) {
      map['name_zh'] = Variable<String>(nameZh.value);
    }
    if (descriptionEn.present) {
      map['description_en'] = Variable<String>(descriptionEn.value);
    }
    if (descriptionZh.present) {
      map['description_zh'] = Variable<String>(descriptionZh.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CoursesCompanion(')
          ..write('id: $id, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('code: $code, ')
          ..write('credits: $credits, ')
          ..write('hours: $hours, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameZh: $nameZh, ')
          ..write('descriptionEn: $descriptionEn, ')
          ..write('descriptionZh: $descriptionZh')
          ..write(')'))
        .toString();
  }
}

class $TeachersTable extends Teachers with TableInfo<$TeachersTable, Teacher> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TeachersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _nameZhMeta = const VerificationMeta('nameZh');
  @override
  late final GeneratedColumn<String> nameZh = GeneratedColumn<String>(
    'name_zh',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, fetchedAt, code, nameZh, email];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'teachers';
  @override
  VerificationContext validateIntegrity(
    Insertable<Teacher> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name_zh')) {
      context.handle(
        _nameZhMeta,
        nameZh.isAcceptableOrUnknown(data['name_zh']!, _nameZhMeta),
      );
    } else if (isInserting) {
      context.missing(_nameZhMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Teacher map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Teacher(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      ),
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      nameZh: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_zh'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
    );
  }

  @override
  $TeachersTable createAlias(String alias) {
    return $TeachersTable(attachedDatabase, alias);
  }
}

class Teacher extends DataClass implements Insertable<Teacher> {
  /// Auto-incrementing primary key.
  final int id;

  /// Timestamp of when complete data was last fetched from the server.
  ///
  /// - `null`: Only partial/basic information is available (e.g., name + ID from a list page)
  /// - `non-null`: Complete details have been fetched (e.g., full profile from detail page)
  ///
  /// Use this field to:
  /// - Determine if a detail fetch is needed (null = need to fetch)
  /// - Implement cache expiration (old timestamp = stale, re-fetch)
  final DateTime? fetchedAt;

  /// Unique teacher code/ID in the NTUT system.
  final String code;

  /// Teacher's name in Traditional Chinese.
  final String nameZh;

  /// Teacher's email address.
  ///
  /// Available from syllabus page (教學大綱與進度).
  final String? email;
  const Teacher({
    required this.id,
    this.fetchedAt,
    required this.code,
    required this.nameZh,
    this.email,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || fetchedAt != null) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt);
    }
    map['code'] = Variable<String>(code);
    map['name_zh'] = Variable<String>(nameZh);
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    return map;
  }

  TeachersCompanion toCompanion(bool nullToAbsent) {
    return TeachersCompanion(
      id: Value(id),
      fetchedAt: fetchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(fetchedAt),
      code: Value(code),
      nameZh: Value(nameZh),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
    );
  }

  factory Teacher.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Teacher(
      id: serializer.fromJson<int>(json['id']),
      fetchedAt: serializer.fromJson<DateTime?>(json['fetchedAt']),
      code: serializer.fromJson<String>(json['code']),
      nameZh: serializer.fromJson<String>(json['nameZh']),
      email: serializer.fromJson<String?>(json['email']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fetchedAt': serializer.toJson<DateTime?>(fetchedAt),
      'code': serializer.toJson<String>(code),
      'nameZh': serializer.toJson<String>(nameZh),
      'email': serializer.toJson<String?>(email),
    };
  }

  Teacher copyWith({
    int? id,
    Value<DateTime?> fetchedAt = const Value.absent(),
    String? code,
    String? nameZh,
    Value<String?> email = const Value.absent(),
  }) => Teacher(
    id: id ?? this.id,
    fetchedAt: fetchedAt.present ? fetchedAt.value : this.fetchedAt,
    code: code ?? this.code,
    nameZh: nameZh ?? this.nameZh,
    email: email.present ? email.value : this.email,
  );
  Teacher copyWithCompanion(TeachersCompanion data) {
    return Teacher(
      id: data.id.present ? data.id.value : this.id,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      code: data.code.present ? data.code.value : this.code,
      nameZh: data.nameZh.present ? data.nameZh.value : this.nameZh,
      email: data.email.present ? data.email.value : this.email,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Teacher(')
          ..write('id: $id, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('code: $code, ')
          ..write('nameZh: $nameZh, ')
          ..write('email: $email')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, fetchedAt, code, nameZh, email);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Teacher &&
          other.id == this.id &&
          other.fetchedAt == this.fetchedAt &&
          other.code == this.code &&
          other.nameZh == this.nameZh &&
          other.email == this.email);
}

class TeachersCompanion extends UpdateCompanion<Teacher> {
  final Value<int> id;
  final Value<DateTime?> fetchedAt;
  final Value<String> code;
  final Value<String> nameZh;
  final Value<String?> email;
  const TeachersCompanion({
    this.id = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.code = const Value.absent(),
    this.nameZh = const Value.absent(),
    this.email = const Value.absent(),
  });
  TeachersCompanion.insert({
    this.id = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    required String code,
    required String nameZh,
    this.email = const Value.absent(),
  }) : code = Value(code),
       nameZh = Value(nameZh);
  static Insertable<Teacher> custom({
    Expression<int>? id,
    Expression<DateTime>? fetchedAt,
    Expression<String>? code,
    Expression<String>? nameZh,
    Expression<String>? email,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (code != null) 'code': code,
      if (nameZh != null) 'name_zh': nameZh,
      if (email != null) 'email': email,
    });
  }

  TeachersCompanion copyWith({
    Value<int>? id,
    Value<DateTime?>? fetchedAt,
    Value<String>? code,
    Value<String>? nameZh,
    Value<String?>? email,
  }) {
    return TeachersCompanion(
      id: id ?? this.id,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      code: code ?? this.code,
      nameZh: nameZh ?? this.nameZh,
      email: email ?? this.email,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (nameZh.present) {
      map['name_zh'] = Variable<String>(nameZh.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TeachersCompanion(')
          ..write('id: $id, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('code: $code, ')
          ..write('nameZh: $nameZh, ')
          ..write('email: $email')
          ..write(')'))
        .toString();
  }
}

class $ClassesTable extends Classes with TableInfo<$ClassesTable, ClassesData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClassesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _nameZhMeta = const VerificationMeta('nameZh');
  @override
  late final GeneratedColumn<String> nameZh = GeneratedColumn<String>(
    'name_zh',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, fetchedAt, code, nameZh];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'classes';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClassesData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name_zh')) {
      context.handle(
        _nameZhMeta,
        nameZh.isAcceptableOrUnknown(data['name_zh']!, _nameZhMeta),
      );
    } else if (isInserting) {
      context.missing(_nameZhMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClassesData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClassesData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      ),
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      nameZh: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_zh'],
      )!,
    );
  }

  @override
  $ClassesTable createAlias(String alias) {
    return $ClassesTable(attachedDatabase, alias);
  }
}

class ClassesData extends DataClass implements Insertable<ClassesData> {
  /// Auto-incrementing primary key.
  final int id;

  /// Timestamp of when complete data was last fetched from the server.
  ///
  /// - `null`: Only partial/basic information is available (e.g., name + ID from a list page)
  /// - `non-null`: Complete details have been fetched (e.g., full profile from detail page)
  ///
  /// Use this field to:
  /// - Determine if a detail fetch is needed (null = need to fetch)
  /// - Implement cache expiration (old timestamp = stale, re-fetch)
  final DateTime? fetchedAt;

  /// Unique class code in the NTUT system.
  final String code;

  /// Class name in Traditional Chinese (e.g., "電子四甲").
  final String nameZh;
  const ClassesData({
    required this.id,
    this.fetchedAt,
    required this.code,
    required this.nameZh,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || fetchedAt != null) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt);
    }
    map['code'] = Variable<String>(code);
    map['name_zh'] = Variable<String>(nameZh);
    return map;
  }

  ClassesCompanion toCompanion(bool nullToAbsent) {
    return ClassesCompanion(
      id: Value(id),
      fetchedAt: fetchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(fetchedAt),
      code: Value(code),
      nameZh: Value(nameZh),
    );
  }

  factory ClassesData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClassesData(
      id: serializer.fromJson<int>(json['id']),
      fetchedAt: serializer.fromJson<DateTime?>(json['fetchedAt']),
      code: serializer.fromJson<String>(json['code']),
      nameZh: serializer.fromJson<String>(json['nameZh']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fetchedAt': serializer.toJson<DateTime?>(fetchedAt),
      'code': serializer.toJson<String>(code),
      'nameZh': serializer.toJson<String>(nameZh),
    };
  }

  ClassesData copyWith({
    int? id,
    Value<DateTime?> fetchedAt = const Value.absent(),
    String? code,
    String? nameZh,
  }) => ClassesData(
    id: id ?? this.id,
    fetchedAt: fetchedAt.present ? fetchedAt.value : this.fetchedAt,
    code: code ?? this.code,
    nameZh: nameZh ?? this.nameZh,
  );
  ClassesData copyWithCompanion(ClassesCompanion data) {
    return ClassesData(
      id: data.id.present ? data.id.value : this.id,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      code: data.code.present ? data.code.value : this.code,
      nameZh: data.nameZh.present ? data.nameZh.value : this.nameZh,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClassesData(')
          ..write('id: $id, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('code: $code, ')
          ..write('nameZh: $nameZh')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, fetchedAt, code, nameZh);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClassesData &&
          other.id == this.id &&
          other.fetchedAt == this.fetchedAt &&
          other.code == this.code &&
          other.nameZh == this.nameZh);
}

class ClassesCompanion extends UpdateCompanion<ClassesData> {
  final Value<int> id;
  final Value<DateTime?> fetchedAt;
  final Value<String> code;
  final Value<String> nameZh;
  const ClassesCompanion({
    this.id = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.code = const Value.absent(),
    this.nameZh = const Value.absent(),
  });
  ClassesCompanion.insert({
    this.id = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    required String code,
    required String nameZh,
  }) : code = Value(code),
       nameZh = Value(nameZh);
  static Insertable<ClassesData> custom({
    Expression<int>? id,
    Expression<DateTime>? fetchedAt,
    Expression<String>? code,
    Expression<String>? nameZh,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (code != null) 'code': code,
      if (nameZh != null) 'name_zh': nameZh,
    });
  }

  ClassesCompanion copyWith({
    Value<int>? id,
    Value<DateTime?>? fetchedAt,
    Value<String>? code,
    Value<String>? nameZh,
  }) {
    return ClassesCompanion(
      id: id ?? this.id,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      code: code ?? this.code,
      nameZh: nameZh ?? this.nameZh,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (nameZh.present) {
      map['name_zh'] = Variable<String>(nameZh.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClassesCompanion(')
          ..write('id: $id, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('code: $code, ')
          ..write('nameZh: $nameZh')
          ..write(')'))
        .toString();
  }
}

class $ClassroomsTable extends Classrooms
    with TableInfo<$ClassroomsTable, Classroom> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClassroomsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _nameZhMeta = const VerificationMeta('nameZh');
  @override
  late final GeneratedColumn<String> nameZh = GeneratedColumn<String>(
    'name_zh',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, fetchedAt, code, nameZh];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'classrooms';
  @override
  VerificationContext validateIntegrity(
    Insertable<Classroom> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name_zh')) {
      context.handle(
        _nameZhMeta,
        nameZh.isAcceptableOrUnknown(data['name_zh']!, _nameZhMeta),
      );
    } else if (isInserting) {
      context.missing(_nameZhMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Classroom map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Classroom(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      ),
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      nameZh: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_zh'],
      )!,
    );
  }

  @override
  $ClassroomsTable createAlias(String alias) {
    return $ClassroomsTable(attachedDatabase, alias);
  }
}

class Classroom extends DataClass implements Insertable<Classroom> {
  /// Auto-incrementing primary key.
  final int id;

  /// Timestamp of when complete data was last fetched from the server.
  ///
  /// - `null`: Only partial/basic information is available (e.g., name + ID from a list page)
  /// - `non-null`: Complete details have been fetched (e.g., full profile from detail page)
  ///
  /// Use this field to:
  /// - Determine if a detail fetch is needed (null = need to fetch)
  /// - Implement cache expiration (old timestamp = stale, re-fetch)
  final DateTime? fetchedAt;

  /// Unique classroom code in the NTUT system.
  final String code;

  /// Classroom name/location in Traditional Chinese (e.g., "共同大樓 101").
  final String nameZh;
  const Classroom({
    required this.id,
    this.fetchedAt,
    required this.code,
    required this.nameZh,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || fetchedAt != null) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt);
    }
    map['code'] = Variable<String>(code);
    map['name_zh'] = Variable<String>(nameZh);
    return map;
  }

  ClassroomsCompanion toCompanion(bool nullToAbsent) {
    return ClassroomsCompanion(
      id: Value(id),
      fetchedAt: fetchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(fetchedAt),
      code: Value(code),
      nameZh: Value(nameZh),
    );
  }

  factory Classroom.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Classroom(
      id: serializer.fromJson<int>(json['id']),
      fetchedAt: serializer.fromJson<DateTime?>(json['fetchedAt']),
      code: serializer.fromJson<String>(json['code']),
      nameZh: serializer.fromJson<String>(json['nameZh']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fetchedAt': serializer.toJson<DateTime?>(fetchedAt),
      'code': serializer.toJson<String>(code),
      'nameZh': serializer.toJson<String>(nameZh),
    };
  }

  Classroom copyWith({
    int? id,
    Value<DateTime?> fetchedAt = const Value.absent(),
    String? code,
    String? nameZh,
  }) => Classroom(
    id: id ?? this.id,
    fetchedAt: fetchedAt.present ? fetchedAt.value : this.fetchedAt,
    code: code ?? this.code,
    nameZh: nameZh ?? this.nameZh,
  );
  Classroom copyWithCompanion(ClassroomsCompanion data) {
    return Classroom(
      id: data.id.present ? data.id.value : this.id,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      code: data.code.present ? data.code.value : this.code,
      nameZh: data.nameZh.present ? data.nameZh.value : this.nameZh,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Classroom(')
          ..write('id: $id, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('code: $code, ')
          ..write('nameZh: $nameZh')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, fetchedAt, code, nameZh);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Classroom &&
          other.id == this.id &&
          other.fetchedAt == this.fetchedAt &&
          other.code == this.code &&
          other.nameZh == this.nameZh);
}

class ClassroomsCompanion extends UpdateCompanion<Classroom> {
  final Value<int> id;
  final Value<DateTime?> fetchedAt;
  final Value<String> code;
  final Value<String> nameZh;
  const ClassroomsCompanion({
    this.id = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.code = const Value.absent(),
    this.nameZh = const Value.absent(),
  });
  ClassroomsCompanion.insert({
    this.id = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    required String code,
    required String nameZh,
  }) : code = Value(code),
       nameZh = Value(nameZh);
  static Insertable<Classroom> custom({
    Expression<int>? id,
    Expression<DateTime>? fetchedAt,
    Expression<String>? code,
    Expression<String>? nameZh,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (code != null) 'code': code,
      if (nameZh != null) 'name_zh': nameZh,
    });
  }

  ClassroomsCompanion copyWith({
    Value<int>? id,
    Value<DateTime?>? fetchedAt,
    Value<String>? code,
    Value<String>? nameZh,
  }) {
    return ClassroomsCompanion(
      id: id ?? this.id,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      code: code ?? this.code,
      nameZh: nameZh ?? this.nameZh,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (nameZh.present) {
      map['name_zh'] = Variable<String>(nameZh.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClassroomsCompanion(')
          ..write('id: $id, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('code: $code, ')
          ..write('nameZh: $nameZh')
          ..write(')'))
        .toString();
  }
}

class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _studentMeta = const VerificationMeta(
    'student',
  );
  @override
  late final GeneratedColumn<int> student = GeneratedColumn<int>(
    'student',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES students (id)',
    ),
  );
  static const VerificationMeta _avatarFilenameMeta = const VerificationMeta(
    'avatarFilename',
  );
  @override
  late final GeneratedColumn<String> avatarFilename = GeneratedColumn<String>(
    'avatar_filename',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _passwordExpiresInDaysMeta =
      const VerificationMeta('passwordExpiresInDays');
  @override
  late final GeneratedColumn<int> passwordExpiresInDays = GeneratedColumn<int>(
    'password_expires_in_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    student,
    avatarFilename,
    email,
    passwordExpiresInDays,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<User> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('student')) {
      context.handle(
        _studentMeta,
        student.isAcceptableOrUnknown(data['student']!, _studentMeta),
      );
    } else if (isInserting) {
      context.missing(_studentMeta);
    }
    if (data.containsKey('avatar_filename')) {
      context.handle(
        _avatarFilenameMeta,
        avatarFilename.isAcceptableOrUnknown(
          data['avatar_filename']!,
          _avatarFilenameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_avatarFilenameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('password_expires_in_days')) {
      context.handle(
        _passwordExpiresInDaysMeta,
        passwordExpiresInDays.isAcceptableOrUnknown(
          data['password_expires_in_days']!,
          _passwordExpiresInDaysMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      student: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}student'],
      )!,
      avatarFilename: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_filename'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      passwordExpiresInDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}password_expires_in_days'],
      ),
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  /// Auto-incrementing primary key.
  final int id;

  /// Reference to the student record associated with this user account.
  final int student;

  /// Filename of the user's avatar image stored locally.
  final String avatarFilename;

  /// User's email address.
  final String email;

  /// Number of days until the user's password expires.
  ///
  /// Null if password expiration is not enforced or unknown.
  final int? passwordExpiresInDays;
  const User({
    required this.id,
    required this.student,
    required this.avatarFilename,
    required this.email,
    this.passwordExpiresInDays,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['student'] = Variable<int>(student);
    map['avatar_filename'] = Variable<String>(avatarFilename);
    map['email'] = Variable<String>(email);
    if (!nullToAbsent || passwordExpiresInDays != null) {
      map['password_expires_in_days'] = Variable<int>(passwordExpiresInDays);
    }
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      student: Value(student),
      avatarFilename: Value(avatarFilename),
      email: Value(email),
      passwordExpiresInDays: passwordExpiresInDays == null && nullToAbsent
          ? const Value.absent()
          : Value(passwordExpiresInDays),
    );
  }

  factory User.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<int>(json['id']),
      student: serializer.fromJson<int>(json['student']),
      avatarFilename: serializer.fromJson<String>(json['avatarFilename']),
      email: serializer.fromJson<String>(json['email']),
      passwordExpiresInDays: serializer.fromJson<int?>(
        json['passwordExpiresInDays'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'student': serializer.toJson<int>(student),
      'avatarFilename': serializer.toJson<String>(avatarFilename),
      'email': serializer.toJson<String>(email),
      'passwordExpiresInDays': serializer.toJson<int?>(passwordExpiresInDays),
    };
  }

  User copyWith({
    int? id,
    int? student,
    String? avatarFilename,
    String? email,
    Value<int?> passwordExpiresInDays = const Value.absent(),
  }) => User(
    id: id ?? this.id,
    student: student ?? this.student,
    avatarFilename: avatarFilename ?? this.avatarFilename,
    email: email ?? this.email,
    passwordExpiresInDays: passwordExpiresInDays.present
        ? passwordExpiresInDays.value
        : this.passwordExpiresInDays,
  );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      student: data.student.present ? data.student.value : this.student,
      avatarFilename: data.avatarFilename.present
          ? data.avatarFilename.value
          : this.avatarFilename,
      email: data.email.present ? data.email.value : this.email,
      passwordExpiresInDays: data.passwordExpiresInDays.present
          ? data.passwordExpiresInDays.value
          : this.passwordExpiresInDays,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('student: $student, ')
          ..write('avatarFilename: $avatarFilename, ')
          ..write('email: $email, ')
          ..write('passwordExpiresInDays: $passwordExpiresInDays')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, student, avatarFilename, email, passwordExpiresInDays);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.student == this.student &&
          other.avatarFilename == this.avatarFilename &&
          other.email == this.email &&
          other.passwordExpiresInDays == this.passwordExpiresInDays);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<int> id;
  final Value<int> student;
  final Value<String> avatarFilename;
  final Value<String> email;
  final Value<int?> passwordExpiresInDays;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.student = const Value.absent(),
    this.avatarFilename = const Value.absent(),
    this.email = const Value.absent(),
    this.passwordExpiresInDays = const Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const Value.absent(),
    required int student,
    required String avatarFilename,
    required String email,
    this.passwordExpiresInDays = const Value.absent(),
  }) : student = Value(student),
       avatarFilename = Value(avatarFilename),
       email = Value(email);
  static Insertable<User> custom({
    Expression<int>? id,
    Expression<int>? student,
    Expression<String>? avatarFilename,
    Expression<String>? email,
    Expression<int>? passwordExpiresInDays,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (student != null) 'student': student,
      if (avatarFilename != null) 'avatar_filename': avatarFilename,
      if (email != null) 'email': email,
      if (passwordExpiresInDays != null)
        'password_expires_in_days': passwordExpiresInDays,
    });
  }

  UsersCompanion copyWith({
    Value<int>? id,
    Value<int>? student,
    Value<String>? avatarFilename,
    Value<String>? email,
    Value<int?>? passwordExpiresInDays,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      student: student ?? this.student,
      avatarFilename: avatarFilename ?? this.avatarFilename,
      email: email ?? this.email,
      passwordExpiresInDays:
          passwordExpiresInDays ?? this.passwordExpiresInDays,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (student.present) {
      map['student'] = Variable<int>(student.value);
    }
    if (avatarFilename.present) {
      map['avatar_filename'] = Variable<String>(avatarFilename.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (passwordExpiresInDays.present) {
      map['password_expires_in_days'] = Variable<int>(
        passwordExpiresInDays.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('student: $student, ')
          ..write('avatarFilename: $avatarFilename, ')
          ..write('email: $email, ')
          ..write('passwordExpiresInDays: $passwordExpiresInDays')
          ..write(')'))
        .toString();
  }
}

class $CourseOfferingsTable extends CourseOfferings
    with TableInfo<$CourseOfferingsTable, CourseOffering> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CourseOfferingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _courseMeta = const VerificationMeta('course');
  @override
  late final GeneratedColumn<int> course = GeneratedColumn<int>(
    'course',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES courses (id)',
    ),
  );
  static const VerificationMeta _semesterMeta = const VerificationMeta(
    'semester',
  );
  @override
  late final GeneratedColumn<int> semester = GeneratedColumn<int>(
    'semester',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES semesters (id)',
    ),
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<String> number = GeneratedColumn<String>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _phaseMeta = const VerificationMeta('phase');
  @override
  late final GeneratedColumn<int> phase = GeneratedColumn<int>(
    'phase',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<CourseType, String> courseType =
      GeneratedColumn<String>(
        'course_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CourseType>($CourseOfferingsTable.$convertercourseType);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remarksMeta = const VerificationMeta(
    'remarks',
  );
  @override
  late final GeneratedColumn<String> remarks = GeneratedColumn<String>(
    'remarks',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _enrolledMeta = const VerificationMeta(
    'enrolled',
  );
  @override
  late final GeneratedColumn<int> enrolled = GeneratedColumn<int>(
    'enrolled',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _withdrawnMeta = const VerificationMeta(
    'withdrawn',
  );
  @override
  late final GeneratedColumn<int> withdrawn = GeneratedColumn<int>(
    'withdrawn',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syllabusIdMeta = const VerificationMeta(
    'syllabusId',
  );
  @override
  late final GeneratedColumn<String> syllabusId = GeneratedColumn<String>(
    'syllabus_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syllabusUpdatedAtMeta = const VerificationMeta(
    'syllabusUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syllabusUpdatedAt =
      GeneratedColumn<DateTime>(
        'syllabus_updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _objectiveMeta = const VerificationMeta(
    'objective',
  );
  @override
  late final GeneratedColumn<String> objective = GeneratedColumn<String>(
    'objective',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weeklyPlanMeta = const VerificationMeta(
    'weeklyPlan',
  );
  @override
  late final GeneratedColumn<String> weeklyPlan = GeneratedColumn<String>(
    'weekly_plan',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _evaluationMeta = const VerificationMeta(
    'evaluation',
  );
  @override
  late final GeneratedColumn<String> evaluation = GeneratedColumn<String>(
    'evaluation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _textbooksMeta = const VerificationMeta(
    'textbooks',
  );
  @override
  late final GeneratedColumn<String> textbooks = GeneratedColumn<String>(
    'textbooks',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fetchedAt,
    course,
    semester,
    number,
    phase,
    courseType,
    status,
    language,
    remarks,
    enrolled,
    withdrawn,
    syllabusId,
    syllabusUpdatedAt,
    objective,
    weeklyPlan,
    evaluation,
    textbooks,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'course_offerings';
  @override
  VerificationContext validateIntegrity(
    Insertable<CourseOffering> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    }
    if (data.containsKey('course')) {
      context.handle(
        _courseMeta,
        course.isAcceptableOrUnknown(data['course']!, _courseMeta),
      );
    } else if (isInserting) {
      context.missing(_courseMeta);
    }
    if (data.containsKey('semester')) {
      context.handle(
        _semesterMeta,
        semester.isAcceptableOrUnknown(data['semester']!, _semesterMeta),
      );
    } else if (isInserting) {
      context.missing(_semesterMeta);
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    } else if (isInserting) {
      context.missing(_numberMeta);
    }
    if (data.containsKey('phase')) {
      context.handle(
        _phaseMeta,
        phase.isAcceptableOrUnknown(data['phase']!, _phaseMeta),
      );
    } else if (isInserting) {
      context.missing(_phaseMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    }
    if (data.containsKey('remarks')) {
      context.handle(
        _remarksMeta,
        remarks.isAcceptableOrUnknown(data['remarks']!, _remarksMeta),
      );
    }
    if (data.containsKey('enrolled')) {
      context.handle(
        _enrolledMeta,
        enrolled.isAcceptableOrUnknown(data['enrolled']!, _enrolledMeta),
      );
    }
    if (data.containsKey('withdrawn')) {
      context.handle(
        _withdrawnMeta,
        withdrawn.isAcceptableOrUnknown(data['withdrawn']!, _withdrawnMeta),
      );
    }
    if (data.containsKey('syllabus_id')) {
      context.handle(
        _syllabusIdMeta,
        syllabusId.isAcceptableOrUnknown(data['syllabus_id']!, _syllabusIdMeta),
      );
    }
    if (data.containsKey('syllabus_updated_at')) {
      context.handle(
        _syllabusUpdatedAtMeta,
        syllabusUpdatedAt.isAcceptableOrUnknown(
          data['syllabus_updated_at']!,
          _syllabusUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('objective')) {
      context.handle(
        _objectiveMeta,
        objective.isAcceptableOrUnknown(data['objective']!, _objectiveMeta),
      );
    }
    if (data.containsKey('weekly_plan')) {
      context.handle(
        _weeklyPlanMeta,
        weeklyPlan.isAcceptableOrUnknown(data['weekly_plan']!, _weeklyPlanMeta),
      );
    }
    if (data.containsKey('evaluation')) {
      context.handle(
        _evaluationMeta,
        evaluation.isAcceptableOrUnknown(data['evaluation']!, _evaluationMeta),
      );
    }
    if (data.containsKey('textbooks')) {
      context.handle(
        _textbooksMeta,
        textbooks.isAcceptableOrUnknown(data['textbooks']!, _textbooksMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CourseOffering map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CourseOffering(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      ),
      course: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}course'],
      )!,
      semester: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}semester'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}number'],
      )!,
      phase: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}phase'],
      )!,
      courseType: $CourseOfferingsTable.$convertercourseType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}course_type'],
        )!,
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      ),
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      ),
      remarks: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remarks'],
      ),
      enrolled: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}enrolled'],
      ),
      withdrawn: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}withdrawn'],
      ),
      syllabusId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}syllabus_id'],
      ),
      syllabusUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}syllabus_updated_at'],
      ),
      objective: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}objective'],
      ),
      weeklyPlan: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weekly_plan'],
      ),
      evaluation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}evaluation'],
      ),
      textbooks: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}textbooks'],
      ),
    );
  }

  @override
  $CourseOfferingsTable createAlias(String alias) {
    return $CourseOfferingsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CourseType, String, String> $convertercourseType =
      const EnumNameConverter<CourseType>(CourseType.values);
}

class CourseOffering extends DataClass implements Insertable<CourseOffering> {
  /// Auto-incrementing primary key.
  final int id;

  /// Timestamp of when complete data was last fetched from the server.
  ///
  /// - `null`: Only partial/basic information is available (e.g., name + ID from a list page)
  /// - `non-null`: Complete details have been fetched (e.g., full profile from detail page)
  ///
  /// Use this field to:
  /// - Determine if a detail fetch is needed (null = need to fetch)
  /// - Implement cache expiration (old timestamp = stale, re-fetch)
  final DateTime? fetchedAt;

  /// Reference to the course definition.
  final int course;

  /// Reference to the semester when this course is offered.
  final int semester;

  /// Unique course offering number (e.g., "313146", "352902").
  final String number;

  /// Course sequence phase/stage number (階段, e.g., "1", "2").
  ///
  /// For multi-part courses like 物理 with the same name. Some courses
  /// encode the sequence in the name instead (e.g., 英文溝通與應用(一)).
  final int phase;

  /// Course type for graduation credit requirements (課程標準).
  ///
  /// Uses symbols from syllabus page: ○, △, ☆, ●, ▲, ★
  /// See [CourseType] enum for mapping.
  final CourseType courseType;

  /// Enrollment status for special cases (e.g., "撤選" for withdrawal).
  ///
  /// Normally null for regular enrolled courses.
  final String? status;

  /// Language of instruction (e.g., "英語").
  final String? language;

  /// Additional remarks or notes about this offering.
  final String? remarks;

  /// Number of enrolled students (人).
  final int? enrolled;

  /// Number of withdrawn students (撤).
  final int? withdrawn;

  /// Syllabus ID for fetching detailed syllabus information.
  final String? syllabusId;

  /// When the syllabus was last updated (最後更新時間).
  final DateTime? syllabusUpdatedAt;

  /// Course objective/outline (課程大綱).
  final String? objective;

  /// Weekly plan describing topics covered each week (課程進度).
  ///
  /// Note: Called "Course Schedule" on English page, but refers to weekly
  /// topics, not class meeting times.
  final String? weeklyPlan;

  /// Evaluation and grading policy (評量方式與標準).
  final String? evaluation;

  /// Textbooks and reference materials (使用教材、參考書目或其他).
  final String? textbooks;
  const CourseOffering({
    required this.id,
    this.fetchedAt,
    required this.course,
    required this.semester,
    required this.number,
    required this.phase,
    required this.courseType,
    this.status,
    this.language,
    this.remarks,
    this.enrolled,
    this.withdrawn,
    this.syllabusId,
    this.syllabusUpdatedAt,
    this.objective,
    this.weeklyPlan,
    this.evaluation,
    this.textbooks,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || fetchedAt != null) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt);
    }
    map['course'] = Variable<int>(course);
    map['semester'] = Variable<int>(semester);
    map['number'] = Variable<String>(number);
    map['phase'] = Variable<int>(phase);
    {
      map['course_type'] = Variable<String>(
        $CourseOfferingsTable.$convertercourseType.toSql(courseType),
      );
    }
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(status);
    }
    if (!nullToAbsent || language != null) {
      map['language'] = Variable<String>(language);
    }
    if (!nullToAbsent || remarks != null) {
      map['remarks'] = Variable<String>(remarks);
    }
    if (!nullToAbsent || enrolled != null) {
      map['enrolled'] = Variable<int>(enrolled);
    }
    if (!nullToAbsent || withdrawn != null) {
      map['withdrawn'] = Variable<int>(withdrawn);
    }
    if (!nullToAbsent || syllabusId != null) {
      map['syllabus_id'] = Variable<String>(syllabusId);
    }
    if (!nullToAbsent || syllabusUpdatedAt != null) {
      map['syllabus_updated_at'] = Variable<DateTime>(syllabusUpdatedAt);
    }
    if (!nullToAbsent || objective != null) {
      map['objective'] = Variable<String>(objective);
    }
    if (!nullToAbsent || weeklyPlan != null) {
      map['weekly_plan'] = Variable<String>(weeklyPlan);
    }
    if (!nullToAbsent || evaluation != null) {
      map['evaluation'] = Variable<String>(evaluation);
    }
    if (!nullToAbsent || textbooks != null) {
      map['textbooks'] = Variable<String>(textbooks);
    }
    return map;
  }

  CourseOfferingsCompanion toCompanion(bool nullToAbsent) {
    return CourseOfferingsCompanion(
      id: Value(id),
      fetchedAt: fetchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(fetchedAt),
      course: Value(course),
      semester: Value(semester),
      number: Value(number),
      phase: Value(phase),
      courseType: Value(courseType),
      status: status == null && nullToAbsent
          ? const Value.absent()
          : Value(status),
      language: language == null && nullToAbsent
          ? const Value.absent()
          : Value(language),
      remarks: remarks == null && nullToAbsent
          ? const Value.absent()
          : Value(remarks),
      enrolled: enrolled == null && nullToAbsent
          ? const Value.absent()
          : Value(enrolled),
      withdrawn: withdrawn == null && nullToAbsent
          ? const Value.absent()
          : Value(withdrawn),
      syllabusId: syllabusId == null && nullToAbsent
          ? const Value.absent()
          : Value(syllabusId),
      syllabusUpdatedAt: syllabusUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syllabusUpdatedAt),
      objective: objective == null && nullToAbsent
          ? const Value.absent()
          : Value(objective),
      weeklyPlan: weeklyPlan == null && nullToAbsent
          ? const Value.absent()
          : Value(weeklyPlan),
      evaluation: evaluation == null && nullToAbsent
          ? const Value.absent()
          : Value(evaluation),
      textbooks: textbooks == null && nullToAbsent
          ? const Value.absent()
          : Value(textbooks),
    );
  }

  factory CourseOffering.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CourseOffering(
      id: serializer.fromJson<int>(json['id']),
      fetchedAt: serializer.fromJson<DateTime?>(json['fetchedAt']),
      course: serializer.fromJson<int>(json['course']),
      semester: serializer.fromJson<int>(json['semester']),
      number: serializer.fromJson<String>(json['number']),
      phase: serializer.fromJson<int>(json['phase']),
      courseType: $CourseOfferingsTable.$convertercourseType.fromJson(
        serializer.fromJson<String>(json['courseType']),
      ),
      status: serializer.fromJson<String?>(json['status']),
      language: serializer.fromJson<String?>(json['language']),
      remarks: serializer.fromJson<String?>(json['remarks']),
      enrolled: serializer.fromJson<int?>(json['enrolled']),
      withdrawn: serializer.fromJson<int?>(json['withdrawn']),
      syllabusId: serializer.fromJson<String?>(json['syllabusId']),
      syllabusUpdatedAt: serializer.fromJson<DateTime?>(
        json['syllabusUpdatedAt'],
      ),
      objective: serializer.fromJson<String?>(json['objective']),
      weeklyPlan: serializer.fromJson<String?>(json['weeklyPlan']),
      evaluation: serializer.fromJson<String?>(json['evaluation']),
      textbooks: serializer.fromJson<String?>(json['textbooks']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fetchedAt': serializer.toJson<DateTime?>(fetchedAt),
      'course': serializer.toJson<int>(course),
      'semester': serializer.toJson<int>(semester),
      'number': serializer.toJson<String>(number),
      'phase': serializer.toJson<int>(phase),
      'courseType': serializer.toJson<String>(
        $CourseOfferingsTable.$convertercourseType.toJson(courseType),
      ),
      'status': serializer.toJson<String?>(status),
      'language': serializer.toJson<String?>(language),
      'remarks': serializer.toJson<String?>(remarks),
      'enrolled': serializer.toJson<int?>(enrolled),
      'withdrawn': serializer.toJson<int?>(withdrawn),
      'syllabusId': serializer.toJson<String?>(syllabusId),
      'syllabusUpdatedAt': serializer.toJson<DateTime?>(syllabusUpdatedAt),
      'objective': serializer.toJson<String?>(objective),
      'weeklyPlan': serializer.toJson<String?>(weeklyPlan),
      'evaluation': serializer.toJson<String?>(evaluation),
      'textbooks': serializer.toJson<String?>(textbooks),
    };
  }

  CourseOffering copyWith({
    int? id,
    Value<DateTime?> fetchedAt = const Value.absent(),
    int? course,
    int? semester,
    String? number,
    int? phase,
    CourseType? courseType,
    Value<String?> status = const Value.absent(),
    Value<String?> language = const Value.absent(),
    Value<String?> remarks = const Value.absent(),
    Value<int?> enrolled = const Value.absent(),
    Value<int?> withdrawn = const Value.absent(),
    Value<String?> syllabusId = const Value.absent(),
    Value<DateTime?> syllabusUpdatedAt = const Value.absent(),
    Value<String?> objective = const Value.absent(),
    Value<String?> weeklyPlan = const Value.absent(),
    Value<String?> evaluation = const Value.absent(),
    Value<String?> textbooks = const Value.absent(),
  }) => CourseOffering(
    id: id ?? this.id,
    fetchedAt: fetchedAt.present ? fetchedAt.value : this.fetchedAt,
    course: course ?? this.course,
    semester: semester ?? this.semester,
    number: number ?? this.number,
    phase: phase ?? this.phase,
    courseType: courseType ?? this.courseType,
    status: status.present ? status.value : this.status,
    language: language.present ? language.value : this.language,
    remarks: remarks.present ? remarks.value : this.remarks,
    enrolled: enrolled.present ? enrolled.value : this.enrolled,
    withdrawn: withdrawn.present ? withdrawn.value : this.withdrawn,
    syllabusId: syllabusId.present ? syllabusId.value : this.syllabusId,
    syllabusUpdatedAt: syllabusUpdatedAt.present
        ? syllabusUpdatedAt.value
        : this.syllabusUpdatedAt,
    objective: objective.present ? objective.value : this.objective,
    weeklyPlan: weeklyPlan.present ? weeklyPlan.value : this.weeklyPlan,
    evaluation: evaluation.present ? evaluation.value : this.evaluation,
    textbooks: textbooks.present ? textbooks.value : this.textbooks,
  );
  CourseOffering copyWithCompanion(CourseOfferingsCompanion data) {
    return CourseOffering(
      id: data.id.present ? data.id.value : this.id,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      course: data.course.present ? data.course.value : this.course,
      semester: data.semester.present ? data.semester.value : this.semester,
      number: data.number.present ? data.number.value : this.number,
      phase: data.phase.present ? data.phase.value : this.phase,
      courseType: data.courseType.present
          ? data.courseType.value
          : this.courseType,
      status: data.status.present ? data.status.value : this.status,
      language: data.language.present ? data.language.value : this.language,
      remarks: data.remarks.present ? data.remarks.value : this.remarks,
      enrolled: data.enrolled.present ? data.enrolled.value : this.enrolled,
      withdrawn: data.withdrawn.present ? data.withdrawn.value : this.withdrawn,
      syllabusId: data.syllabusId.present
          ? data.syllabusId.value
          : this.syllabusId,
      syllabusUpdatedAt: data.syllabusUpdatedAt.present
          ? data.syllabusUpdatedAt.value
          : this.syllabusUpdatedAt,
      objective: data.objective.present ? data.objective.value : this.objective,
      weeklyPlan: data.weeklyPlan.present
          ? data.weeklyPlan.value
          : this.weeklyPlan,
      evaluation: data.evaluation.present
          ? data.evaluation.value
          : this.evaluation,
      textbooks: data.textbooks.present ? data.textbooks.value : this.textbooks,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CourseOffering(')
          ..write('id: $id, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('course: $course, ')
          ..write('semester: $semester, ')
          ..write('number: $number, ')
          ..write('phase: $phase, ')
          ..write('courseType: $courseType, ')
          ..write('status: $status, ')
          ..write('language: $language, ')
          ..write('remarks: $remarks, ')
          ..write('enrolled: $enrolled, ')
          ..write('withdrawn: $withdrawn, ')
          ..write('syllabusId: $syllabusId, ')
          ..write('syllabusUpdatedAt: $syllabusUpdatedAt, ')
          ..write('objective: $objective, ')
          ..write('weeklyPlan: $weeklyPlan, ')
          ..write('evaluation: $evaluation, ')
          ..write('textbooks: $textbooks')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    fetchedAt,
    course,
    semester,
    number,
    phase,
    courseType,
    status,
    language,
    remarks,
    enrolled,
    withdrawn,
    syllabusId,
    syllabusUpdatedAt,
    objective,
    weeklyPlan,
    evaluation,
    textbooks,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CourseOffering &&
          other.id == this.id &&
          other.fetchedAt == this.fetchedAt &&
          other.course == this.course &&
          other.semester == this.semester &&
          other.number == this.number &&
          other.phase == this.phase &&
          other.courseType == this.courseType &&
          other.status == this.status &&
          other.language == this.language &&
          other.remarks == this.remarks &&
          other.enrolled == this.enrolled &&
          other.withdrawn == this.withdrawn &&
          other.syllabusId == this.syllabusId &&
          other.syllabusUpdatedAt == this.syllabusUpdatedAt &&
          other.objective == this.objective &&
          other.weeklyPlan == this.weeklyPlan &&
          other.evaluation == this.evaluation &&
          other.textbooks == this.textbooks);
}

class CourseOfferingsCompanion extends UpdateCompanion<CourseOffering> {
  final Value<int> id;
  final Value<DateTime?> fetchedAt;
  final Value<int> course;
  final Value<int> semester;
  final Value<String> number;
  final Value<int> phase;
  final Value<CourseType> courseType;
  final Value<String?> status;
  final Value<String?> language;
  final Value<String?> remarks;
  final Value<int?> enrolled;
  final Value<int?> withdrawn;
  final Value<String?> syllabusId;
  final Value<DateTime?> syllabusUpdatedAt;
  final Value<String?> objective;
  final Value<String?> weeklyPlan;
  final Value<String?> evaluation;
  final Value<String?> textbooks;
  const CourseOfferingsCompanion({
    this.id = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.course = const Value.absent(),
    this.semester = const Value.absent(),
    this.number = const Value.absent(),
    this.phase = const Value.absent(),
    this.courseType = const Value.absent(),
    this.status = const Value.absent(),
    this.language = const Value.absent(),
    this.remarks = const Value.absent(),
    this.enrolled = const Value.absent(),
    this.withdrawn = const Value.absent(),
    this.syllabusId = const Value.absent(),
    this.syllabusUpdatedAt = const Value.absent(),
    this.objective = const Value.absent(),
    this.weeklyPlan = const Value.absent(),
    this.evaluation = const Value.absent(),
    this.textbooks = const Value.absent(),
  });
  CourseOfferingsCompanion.insert({
    this.id = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    required int course,
    required int semester,
    required String number,
    required int phase,
    required CourseType courseType,
    this.status = const Value.absent(),
    this.language = const Value.absent(),
    this.remarks = const Value.absent(),
    this.enrolled = const Value.absent(),
    this.withdrawn = const Value.absent(),
    this.syllabusId = const Value.absent(),
    this.syllabusUpdatedAt = const Value.absent(),
    this.objective = const Value.absent(),
    this.weeklyPlan = const Value.absent(),
    this.evaluation = const Value.absent(),
    this.textbooks = const Value.absent(),
  }) : course = Value(course),
       semester = Value(semester),
       number = Value(number),
       phase = Value(phase),
       courseType = Value(courseType);
  static Insertable<CourseOffering> custom({
    Expression<int>? id,
    Expression<DateTime>? fetchedAt,
    Expression<int>? course,
    Expression<int>? semester,
    Expression<String>? number,
    Expression<int>? phase,
    Expression<String>? courseType,
    Expression<String>? status,
    Expression<String>? language,
    Expression<String>? remarks,
    Expression<int>? enrolled,
    Expression<int>? withdrawn,
    Expression<String>? syllabusId,
    Expression<DateTime>? syllabusUpdatedAt,
    Expression<String>? objective,
    Expression<String>? weeklyPlan,
    Expression<String>? evaluation,
    Expression<String>? textbooks,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (course != null) 'course': course,
      if (semester != null) 'semester': semester,
      if (number != null) 'number': number,
      if (phase != null) 'phase': phase,
      if (courseType != null) 'course_type': courseType,
      if (status != null) 'status': status,
      if (language != null) 'language': language,
      if (remarks != null) 'remarks': remarks,
      if (enrolled != null) 'enrolled': enrolled,
      if (withdrawn != null) 'withdrawn': withdrawn,
      if (syllabusId != null) 'syllabus_id': syllabusId,
      if (syllabusUpdatedAt != null) 'syllabus_updated_at': syllabusUpdatedAt,
      if (objective != null) 'objective': objective,
      if (weeklyPlan != null) 'weekly_plan': weeklyPlan,
      if (evaluation != null) 'evaluation': evaluation,
      if (textbooks != null) 'textbooks': textbooks,
    });
  }

  CourseOfferingsCompanion copyWith({
    Value<int>? id,
    Value<DateTime?>? fetchedAt,
    Value<int>? course,
    Value<int>? semester,
    Value<String>? number,
    Value<int>? phase,
    Value<CourseType>? courseType,
    Value<String?>? status,
    Value<String?>? language,
    Value<String?>? remarks,
    Value<int?>? enrolled,
    Value<int?>? withdrawn,
    Value<String?>? syllabusId,
    Value<DateTime?>? syllabusUpdatedAt,
    Value<String?>? objective,
    Value<String?>? weeklyPlan,
    Value<String?>? evaluation,
    Value<String?>? textbooks,
  }) {
    return CourseOfferingsCompanion(
      id: id ?? this.id,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      course: course ?? this.course,
      semester: semester ?? this.semester,
      number: number ?? this.number,
      phase: phase ?? this.phase,
      courseType: courseType ?? this.courseType,
      status: status ?? this.status,
      language: language ?? this.language,
      remarks: remarks ?? this.remarks,
      enrolled: enrolled ?? this.enrolled,
      withdrawn: withdrawn ?? this.withdrawn,
      syllabusId: syllabusId ?? this.syllabusId,
      syllabusUpdatedAt: syllabusUpdatedAt ?? this.syllabusUpdatedAt,
      objective: objective ?? this.objective,
      weeklyPlan: weeklyPlan ?? this.weeklyPlan,
      evaluation: evaluation ?? this.evaluation,
      textbooks: textbooks ?? this.textbooks,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (course.present) {
      map['course'] = Variable<int>(course.value);
    }
    if (semester.present) {
      map['semester'] = Variable<int>(semester.value);
    }
    if (number.present) {
      map['number'] = Variable<String>(number.value);
    }
    if (phase.present) {
      map['phase'] = Variable<int>(phase.value);
    }
    if (courseType.present) {
      map['course_type'] = Variable<String>(
        $CourseOfferingsTable.$convertercourseType.toSql(courseType.value),
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (remarks.present) {
      map['remarks'] = Variable<String>(remarks.value);
    }
    if (enrolled.present) {
      map['enrolled'] = Variable<int>(enrolled.value);
    }
    if (withdrawn.present) {
      map['withdrawn'] = Variable<int>(withdrawn.value);
    }
    if (syllabusId.present) {
      map['syllabus_id'] = Variable<String>(syllabusId.value);
    }
    if (syllabusUpdatedAt.present) {
      map['syllabus_updated_at'] = Variable<DateTime>(syllabusUpdatedAt.value);
    }
    if (objective.present) {
      map['objective'] = Variable<String>(objective.value);
    }
    if (weeklyPlan.present) {
      map['weekly_plan'] = Variable<String>(weeklyPlan.value);
    }
    if (evaluation.present) {
      map['evaluation'] = Variable<String>(evaluation.value);
    }
    if (textbooks.present) {
      map['textbooks'] = Variable<String>(textbooks.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CourseOfferingsCompanion(')
          ..write('id: $id, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('course: $course, ')
          ..write('semester: $semester, ')
          ..write('number: $number, ')
          ..write('phase: $phase, ')
          ..write('courseType: $courseType, ')
          ..write('status: $status, ')
          ..write('language: $language, ')
          ..write('remarks: $remarks, ')
          ..write('enrolled: $enrolled, ')
          ..write('withdrawn: $withdrawn, ')
          ..write('syllabusId: $syllabusId, ')
          ..write('syllabusUpdatedAt: $syllabusUpdatedAt, ')
          ..write('objective: $objective, ')
          ..write('weeklyPlan: $weeklyPlan, ')
          ..write('evaluation: $evaluation, ')
          ..write('textbooks: $textbooks')
          ..write(')'))
        .toString();
  }
}

class $CourseOfferingTeachersTable extends CourseOfferingTeachers
    with TableInfo<$CourseOfferingTeachersTable, CourseOfferingTeacher> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CourseOfferingTeachersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _courseOfferingMeta = const VerificationMeta(
    'courseOffering',
  );
  @override
  late final GeneratedColumn<int> courseOffering = GeneratedColumn<int>(
    'course_offering',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES course_offerings (id)',
    ),
  );
  static const VerificationMeta _teacherMeta = const VerificationMeta(
    'teacher',
  );
  @override
  late final GeneratedColumn<int> teacher = GeneratedColumn<int>(
    'teacher',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES teachers (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [courseOffering, teacher];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'course_offering_teachers';
  @override
  VerificationContext validateIntegrity(
    Insertable<CourseOfferingTeacher> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('course_offering')) {
      context.handle(
        _courseOfferingMeta,
        courseOffering.isAcceptableOrUnknown(
          data['course_offering']!,
          _courseOfferingMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_courseOfferingMeta);
    }
    if (data.containsKey('teacher')) {
      context.handle(
        _teacherMeta,
        teacher.isAcceptableOrUnknown(data['teacher']!, _teacherMeta),
      );
    } else if (isInserting) {
      context.missing(_teacherMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {courseOffering, teacher};
  @override
  CourseOfferingTeacher map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CourseOfferingTeacher(
      courseOffering: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}course_offering'],
      )!,
      teacher: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}teacher'],
      )!,
    );
  }

  @override
  $CourseOfferingTeachersTable createAlias(String alias) {
    return $CourseOfferingTeachersTable(attachedDatabase, alias);
  }
}

class CourseOfferingTeacher extends DataClass
    implements Insertable<CourseOfferingTeacher> {
  /// Reference to the course offering.
  final int courseOffering;

  /// Reference to the teacher.
  final int teacher;
  const CourseOfferingTeacher({
    required this.courseOffering,
    required this.teacher,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['course_offering'] = Variable<int>(courseOffering);
    map['teacher'] = Variable<int>(teacher);
    return map;
  }

  CourseOfferingTeachersCompanion toCompanion(bool nullToAbsent) {
    return CourseOfferingTeachersCompanion(
      courseOffering: Value(courseOffering),
      teacher: Value(teacher),
    );
  }

  factory CourseOfferingTeacher.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CourseOfferingTeacher(
      courseOffering: serializer.fromJson<int>(json['courseOffering']),
      teacher: serializer.fromJson<int>(json['teacher']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'courseOffering': serializer.toJson<int>(courseOffering),
      'teacher': serializer.toJson<int>(teacher),
    };
  }

  CourseOfferingTeacher copyWith({int? courseOffering, int? teacher}) =>
      CourseOfferingTeacher(
        courseOffering: courseOffering ?? this.courseOffering,
        teacher: teacher ?? this.teacher,
      );
  CourseOfferingTeacher copyWithCompanion(
    CourseOfferingTeachersCompanion data,
  ) {
    return CourseOfferingTeacher(
      courseOffering: data.courseOffering.present
          ? data.courseOffering.value
          : this.courseOffering,
      teacher: data.teacher.present ? data.teacher.value : this.teacher,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CourseOfferingTeacher(')
          ..write('courseOffering: $courseOffering, ')
          ..write('teacher: $teacher')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(courseOffering, teacher);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CourseOfferingTeacher &&
          other.courseOffering == this.courseOffering &&
          other.teacher == this.teacher);
}

class CourseOfferingTeachersCompanion
    extends UpdateCompanion<CourseOfferingTeacher> {
  final Value<int> courseOffering;
  final Value<int> teacher;
  final Value<int> rowid;
  const CourseOfferingTeachersCompanion({
    this.courseOffering = const Value.absent(),
    this.teacher = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CourseOfferingTeachersCompanion.insert({
    required int courseOffering,
    required int teacher,
    this.rowid = const Value.absent(),
  }) : courseOffering = Value(courseOffering),
       teacher = Value(teacher);
  static Insertable<CourseOfferingTeacher> custom({
    Expression<int>? courseOffering,
    Expression<int>? teacher,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (courseOffering != null) 'course_offering': courseOffering,
      if (teacher != null) 'teacher': teacher,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CourseOfferingTeachersCompanion copyWith({
    Value<int>? courseOffering,
    Value<int>? teacher,
    Value<int>? rowid,
  }) {
    return CourseOfferingTeachersCompanion(
      courseOffering: courseOffering ?? this.courseOffering,
      teacher: teacher ?? this.teacher,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (courseOffering.present) {
      map['course_offering'] = Variable<int>(courseOffering.value);
    }
    if (teacher.present) {
      map['teacher'] = Variable<int>(teacher.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CourseOfferingTeachersCompanion(')
          ..write('courseOffering: $courseOffering, ')
          ..write('teacher: $teacher, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CourseOfferingClassesTable extends CourseOfferingClasses
    with TableInfo<$CourseOfferingClassesTable, CourseOfferingClassesData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CourseOfferingClassesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _courseOfferingMeta = const VerificationMeta(
    'courseOffering',
  );
  @override
  late final GeneratedColumn<int> courseOffering = GeneratedColumn<int>(
    'course_offering',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES course_offerings (id)',
    ),
  );
  static const VerificationMeta _classEntityMeta = const VerificationMeta(
    'classEntity',
  );
  @override
  late final GeneratedColumn<int> classEntity = GeneratedColumn<int>(
    'class_entity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES classes (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [courseOffering, classEntity];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'course_offering_classes';
  @override
  VerificationContext validateIntegrity(
    Insertable<CourseOfferingClassesData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('course_offering')) {
      context.handle(
        _courseOfferingMeta,
        courseOffering.isAcceptableOrUnknown(
          data['course_offering']!,
          _courseOfferingMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_courseOfferingMeta);
    }
    if (data.containsKey('class_entity')) {
      context.handle(
        _classEntityMeta,
        classEntity.isAcceptableOrUnknown(
          data['class_entity']!,
          _classEntityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_classEntityMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {courseOffering, classEntity};
  @override
  CourseOfferingClassesData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CourseOfferingClassesData(
      courseOffering: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}course_offering'],
      )!,
      classEntity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}class_entity'],
      )!,
    );
  }

  @override
  $CourseOfferingClassesTable createAlias(String alias) {
    return $CourseOfferingClassesTable(attachedDatabase, alias);
  }
}

class CourseOfferingClassesData extends DataClass
    implements Insertable<CourseOfferingClassesData> {
  /// Reference to the course offering.
  final int courseOffering;

  /// Reference to the class/major.
  final int classEntity;
  const CourseOfferingClassesData({
    required this.courseOffering,
    required this.classEntity,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['course_offering'] = Variable<int>(courseOffering);
    map['class_entity'] = Variable<int>(classEntity);
    return map;
  }

  CourseOfferingClassesCompanion toCompanion(bool nullToAbsent) {
    return CourseOfferingClassesCompanion(
      courseOffering: Value(courseOffering),
      classEntity: Value(classEntity),
    );
  }

  factory CourseOfferingClassesData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CourseOfferingClassesData(
      courseOffering: serializer.fromJson<int>(json['courseOffering']),
      classEntity: serializer.fromJson<int>(json['classEntity']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'courseOffering': serializer.toJson<int>(courseOffering),
      'classEntity': serializer.toJson<int>(classEntity),
    };
  }

  CourseOfferingClassesData copyWith({int? courseOffering, int? classEntity}) =>
      CourseOfferingClassesData(
        courseOffering: courseOffering ?? this.courseOffering,
        classEntity: classEntity ?? this.classEntity,
      );
  CourseOfferingClassesData copyWithCompanion(
    CourseOfferingClassesCompanion data,
  ) {
    return CourseOfferingClassesData(
      courseOffering: data.courseOffering.present
          ? data.courseOffering.value
          : this.courseOffering,
      classEntity: data.classEntity.present
          ? data.classEntity.value
          : this.classEntity,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CourseOfferingClassesData(')
          ..write('courseOffering: $courseOffering, ')
          ..write('classEntity: $classEntity')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(courseOffering, classEntity);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CourseOfferingClassesData &&
          other.courseOffering == this.courseOffering &&
          other.classEntity == this.classEntity);
}

class CourseOfferingClassesCompanion
    extends UpdateCompanion<CourseOfferingClassesData> {
  final Value<int> courseOffering;
  final Value<int> classEntity;
  final Value<int> rowid;
  const CourseOfferingClassesCompanion({
    this.courseOffering = const Value.absent(),
    this.classEntity = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CourseOfferingClassesCompanion.insert({
    required int courseOffering,
    required int classEntity,
    this.rowid = const Value.absent(),
  }) : courseOffering = Value(courseOffering),
       classEntity = Value(classEntity);
  static Insertable<CourseOfferingClassesData> custom({
    Expression<int>? courseOffering,
    Expression<int>? classEntity,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (courseOffering != null) 'course_offering': courseOffering,
      if (classEntity != null) 'class_entity': classEntity,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CourseOfferingClassesCompanion copyWith({
    Value<int>? courseOffering,
    Value<int>? classEntity,
    Value<int>? rowid,
  }) {
    return CourseOfferingClassesCompanion(
      courseOffering: courseOffering ?? this.courseOffering,
      classEntity: classEntity ?? this.classEntity,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (courseOffering.present) {
      map['course_offering'] = Variable<int>(courseOffering.value);
    }
    if (classEntity.present) {
      map['class_entity'] = Variable<int>(classEntity.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CourseOfferingClassesCompanion(')
          ..write('courseOffering: $courseOffering, ')
          ..write('classEntity: $classEntity, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CourseOfferingClassroomsTable extends CourseOfferingClassrooms
    with TableInfo<$CourseOfferingClassroomsTable, CourseOfferingClassroom> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CourseOfferingClassroomsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _courseOfferingMeta = const VerificationMeta(
    'courseOffering',
  );
  @override
  late final GeneratedColumn<int> courseOffering = GeneratedColumn<int>(
    'course_offering',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES course_offerings (id)',
    ),
  );
  static const VerificationMeta _classroomMeta = const VerificationMeta(
    'classroom',
  );
  @override
  late final GeneratedColumn<int> classroom = GeneratedColumn<int>(
    'classroom',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES classrooms (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [courseOffering, classroom];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'course_offering_classrooms';
  @override
  VerificationContext validateIntegrity(
    Insertable<CourseOfferingClassroom> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('course_offering')) {
      context.handle(
        _courseOfferingMeta,
        courseOffering.isAcceptableOrUnknown(
          data['course_offering']!,
          _courseOfferingMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_courseOfferingMeta);
    }
    if (data.containsKey('classroom')) {
      context.handle(
        _classroomMeta,
        classroom.isAcceptableOrUnknown(data['classroom']!, _classroomMeta),
      );
    } else if (isInserting) {
      context.missing(_classroomMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {courseOffering, classroom};
  @override
  CourseOfferingClassroom map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CourseOfferingClassroom(
      courseOffering: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}course_offering'],
      )!,
      classroom: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}classroom'],
      )!,
    );
  }

  @override
  $CourseOfferingClassroomsTable createAlias(String alias) {
    return $CourseOfferingClassroomsTable(attachedDatabase, alias);
  }
}

class CourseOfferingClassroom extends DataClass
    implements Insertable<CourseOfferingClassroom> {
  /// Reference to the course offering.
  final int courseOffering;

  /// Reference to the classroom.
  final int classroom;
  const CourseOfferingClassroom({
    required this.courseOffering,
    required this.classroom,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['course_offering'] = Variable<int>(courseOffering);
    map['classroom'] = Variable<int>(classroom);
    return map;
  }

  CourseOfferingClassroomsCompanion toCompanion(bool nullToAbsent) {
    return CourseOfferingClassroomsCompanion(
      courseOffering: Value(courseOffering),
      classroom: Value(classroom),
    );
  }

  factory CourseOfferingClassroom.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CourseOfferingClassroom(
      courseOffering: serializer.fromJson<int>(json['courseOffering']),
      classroom: serializer.fromJson<int>(json['classroom']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'courseOffering': serializer.toJson<int>(courseOffering),
      'classroom': serializer.toJson<int>(classroom),
    };
  }

  CourseOfferingClassroom copyWith({int? courseOffering, int? classroom}) =>
      CourseOfferingClassroom(
        courseOffering: courseOffering ?? this.courseOffering,
        classroom: classroom ?? this.classroom,
      );
  CourseOfferingClassroom copyWithCompanion(
    CourseOfferingClassroomsCompanion data,
  ) {
    return CourseOfferingClassroom(
      courseOffering: data.courseOffering.present
          ? data.courseOffering.value
          : this.courseOffering,
      classroom: data.classroom.present ? data.classroom.value : this.classroom,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CourseOfferingClassroom(')
          ..write('courseOffering: $courseOffering, ')
          ..write('classroom: $classroom')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(courseOffering, classroom);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CourseOfferingClassroom &&
          other.courseOffering == this.courseOffering &&
          other.classroom == this.classroom);
}

class CourseOfferingClassroomsCompanion
    extends UpdateCompanion<CourseOfferingClassroom> {
  final Value<int> courseOffering;
  final Value<int> classroom;
  final Value<int> rowid;
  const CourseOfferingClassroomsCompanion({
    this.courseOffering = const Value.absent(),
    this.classroom = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CourseOfferingClassroomsCompanion.insert({
    required int courseOffering,
    required int classroom,
    this.rowid = const Value.absent(),
  }) : courseOffering = Value(courseOffering),
       classroom = Value(classroom);
  static Insertable<CourseOfferingClassroom> custom({
    Expression<int>? courseOffering,
    Expression<int>? classroom,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (courseOffering != null) 'course_offering': courseOffering,
      if (classroom != null) 'classroom': classroom,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CourseOfferingClassroomsCompanion copyWith({
    Value<int>? courseOffering,
    Value<int>? classroom,
    Value<int>? rowid,
  }) {
    return CourseOfferingClassroomsCompanion(
      courseOffering: courseOffering ?? this.courseOffering,
      classroom: classroom ?? this.classroom,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (courseOffering.present) {
      map['course_offering'] = Variable<int>(courseOffering.value);
    }
    if (classroom.present) {
      map['classroom'] = Variable<int>(classroom.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CourseOfferingClassroomsCompanion(')
          ..write('courseOffering: $courseOffering, ')
          ..write('classroom: $classroom, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CourseOfferingStudentsTable extends CourseOfferingStudents
    with TableInfo<$CourseOfferingStudentsTable, CourseOfferingStudent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CourseOfferingStudentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _courseOfferingMeta = const VerificationMeta(
    'courseOffering',
  );
  @override
  late final GeneratedColumn<int> courseOffering = GeneratedColumn<int>(
    'course_offering',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES course_offerings (id)',
    ),
  );
  static const VerificationMeta _studentMeta = const VerificationMeta(
    'student',
  );
  @override
  late final GeneratedColumn<int> student = GeneratedColumn<int>(
    'student',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES students (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [courseOffering, student];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'course_offering_students';
  @override
  VerificationContext validateIntegrity(
    Insertable<CourseOfferingStudent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('course_offering')) {
      context.handle(
        _courseOfferingMeta,
        courseOffering.isAcceptableOrUnknown(
          data['course_offering']!,
          _courseOfferingMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_courseOfferingMeta);
    }
    if (data.containsKey('student')) {
      context.handle(
        _studentMeta,
        student.isAcceptableOrUnknown(data['student']!, _studentMeta),
      );
    } else if (isInserting) {
      context.missing(_studentMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {courseOffering, student};
  @override
  CourseOfferingStudent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CourseOfferingStudent(
      courseOffering: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}course_offering'],
      )!,
      student: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}student'],
      )!,
    );
  }

  @override
  $CourseOfferingStudentsTable createAlias(String alias) {
    return $CourseOfferingStudentsTable(attachedDatabase, alias);
  }
}

class CourseOfferingStudent extends DataClass
    implements Insertable<CourseOfferingStudent> {
  /// Reference to the course offering.
  final int courseOffering;

  /// Reference to the student.
  final int student;
  const CourseOfferingStudent({
    required this.courseOffering,
    required this.student,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['course_offering'] = Variable<int>(courseOffering);
    map['student'] = Variable<int>(student);
    return map;
  }

  CourseOfferingStudentsCompanion toCompanion(bool nullToAbsent) {
    return CourseOfferingStudentsCompanion(
      courseOffering: Value(courseOffering),
      student: Value(student),
    );
  }

  factory CourseOfferingStudent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CourseOfferingStudent(
      courseOffering: serializer.fromJson<int>(json['courseOffering']),
      student: serializer.fromJson<int>(json['student']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'courseOffering': serializer.toJson<int>(courseOffering),
      'student': serializer.toJson<int>(student),
    };
  }

  CourseOfferingStudent copyWith({int? courseOffering, int? student}) =>
      CourseOfferingStudent(
        courseOffering: courseOffering ?? this.courseOffering,
        student: student ?? this.student,
      );
  CourseOfferingStudent copyWithCompanion(
    CourseOfferingStudentsCompanion data,
  ) {
    return CourseOfferingStudent(
      courseOffering: data.courseOffering.present
          ? data.courseOffering.value
          : this.courseOffering,
      student: data.student.present ? data.student.value : this.student,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CourseOfferingStudent(')
          ..write('courseOffering: $courseOffering, ')
          ..write('student: $student')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(courseOffering, student);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CourseOfferingStudent &&
          other.courseOffering == this.courseOffering &&
          other.student == this.student);
}

class CourseOfferingStudentsCompanion
    extends UpdateCompanion<CourseOfferingStudent> {
  final Value<int> courseOffering;
  final Value<int> student;
  final Value<int> rowid;
  const CourseOfferingStudentsCompanion({
    this.courseOffering = const Value.absent(),
    this.student = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CourseOfferingStudentsCompanion.insert({
    required int courseOffering,
    required int student,
    this.rowid = const Value.absent(),
  }) : courseOffering = Value(courseOffering),
       student = Value(student);
  static Insertable<CourseOfferingStudent> custom({
    Expression<int>? courseOffering,
    Expression<int>? student,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (courseOffering != null) 'course_offering': courseOffering,
      if (student != null) 'student': student,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CourseOfferingStudentsCompanion copyWith({
    Value<int>? courseOffering,
    Value<int>? student,
    Value<int>? rowid,
  }) {
    return CourseOfferingStudentsCompanion(
      courseOffering: courseOffering ?? this.courseOffering,
      student: student ?? this.student,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (courseOffering.present) {
      map['course_offering'] = Variable<int>(courseOffering.value);
    }
    if (student.present) {
      map['student'] = Variable<int>(student.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CourseOfferingStudentsCompanion(')
          ..write('courseOffering: $courseOffering, ')
          ..write('student: $student, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SchedulesTable extends Schedules
    with TableInfo<$SchedulesTable, Schedule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SchedulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _courseOfferingMeta = const VerificationMeta(
    'courseOffering',
  );
  @override
  late final GeneratedColumn<int> courseOffering = GeneratedColumn<int>(
    'course_offering',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES course_offerings (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DayOfWeek, int> dayOfWeek =
      GeneratedColumn<int>(
        'day_of_week',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DayOfWeek>($SchedulesTable.$converterdayOfWeek);
  @override
  late final GeneratedColumnWithTypeConverter<Period, int> period =
      GeneratedColumn<int>(
        'period',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<Period>($SchedulesTable.$converterperiod);
  @override
  List<GeneratedColumn> get $columns => [id, courseOffering, dayOfWeek, period];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'schedules';
  @override
  VerificationContext validateIntegrity(
    Insertable<Schedule> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('course_offering')) {
      context.handle(
        _courseOfferingMeta,
        courseOffering.isAcceptableOrUnknown(
          data['course_offering']!,
          _courseOfferingMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_courseOfferingMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {courseOffering, dayOfWeek, period},
  ];
  @override
  Schedule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Schedule(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      courseOffering: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}course_offering'],
      )!,
      dayOfWeek: $SchedulesTable.$converterdayOfWeek.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}day_of_week'],
        )!,
      ),
      period: $SchedulesTable.$converterperiod.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}period'],
        )!,
      ),
    );
  }

  @override
  $SchedulesTable createAlias(String alias) {
    return $SchedulesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DayOfWeek, int, int> $converterdayOfWeek =
      const EnumIndexConverter<DayOfWeek>(DayOfWeek.values);
  static JsonTypeConverter2<Period, int, int> $converterperiod =
      const EnumIndexConverter<Period>(Period.values);
}

class Schedule extends DataClass implements Insertable<Schedule> {
  /// Auto-incrementing primary key.
  final int id;

  /// Reference to the course offering.
  final int courseOffering;

  /// Day of the week for this class session.
  final DayOfWeek dayOfWeek;

  /// Period within the day for this class session.
  final Period period;
  const Schedule({
    required this.id,
    required this.courseOffering,
    required this.dayOfWeek,
    required this.period,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['course_offering'] = Variable<int>(courseOffering);
    {
      map['day_of_week'] = Variable<int>(
        $SchedulesTable.$converterdayOfWeek.toSql(dayOfWeek),
      );
    }
    {
      map['period'] = Variable<int>(
        $SchedulesTable.$converterperiod.toSql(period),
      );
    }
    return map;
  }

  SchedulesCompanion toCompanion(bool nullToAbsent) {
    return SchedulesCompanion(
      id: Value(id),
      courseOffering: Value(courseOffering),
      dayOfWeek: Value(dayOfWeek),
      period: Value(period),
    );
  }

  factory Schedule.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Schedule(
      id: serializer.fromJson<int>(json['id']),
      courseOffering: serializer.fromJson<int>(json['courseOffering']),
      dayOfWeek: $SchedulesTable.$converterdayOfWeek.fromJson(
        serializer.fromJson<int>(json['dayOfWeek']),
      ),
      period: $SchedulesTable.$converterperiod.fromJson(
        serializer.fromJson<int>(json['period']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'courseOffering': serializer.toJson<int>(courseOffering),
      'dayOfWeek': serializer.toJson<int>(
        $SchedulesTable.$converterdayOfWeek.toJson(dayOfWeek),
      ),
      'period': serializer.toJson<int>(
        $SchedulesTable.$converterperiod.toJson(period),
      ),
    };
  }

  Schedule copyWith({
    int? id,
    int? courseOffering,
    DayOfWeek? dayOfWeek,
    Period? period,
  }) => Schedule(
    id: id ?? this.id,
    courseOffering: courseOffering ?? this.courseOffering,
    dayOfWeek: dayOfWeek ?? this.dayOfWeek,
    period: period ?? this.period,
  );
  Schedule copyWithCompanion(SchedulesCompanion data) {
    return Schedule(
      id: data.id.present ? data.id.value : this.id,
      courseOffering: data.courseOffering.present
          ? data.courseOffering.value
          : this.courseOffering,
      dayOfWeek: data.dayOfWeek.present ? data.dayOfWeek.value : this.dayOfWeek,
      period: data.period.present ? data.period.value : this.period,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Schedule(')
          ..write('id: $id, ')
          ..write('courseOffering: $courseOffering, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('period: $period')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, courseOffering, dayOfWeek, period);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Schedule &&
          other.id == this.id &&
          other.courseOffering == this.courseOffering &&
          other.dayOfWeek == this.dayOfWeek &&
          other.period == this.period);
}

class SchedulesCompanion extends UpdateCompanion<Schedule> {
  final Value<int> id;
  final Value<int> courseOffering;
  final Value<DayOfWeek> dayOfWeek;
  final Value<Period> period;
  const SchedulesCompanion({
    this.id = const Value.absent(),
    this.courseOffering = const Value.absent(),
    this.dayOfWeek = const Value.absent(),
    this.period = const Value.absent(),
  });
  SchedulesCompanion.insert({
    this.id = const Value.absent(),
    required int courseOffering,
    required DayOfWeek dayOfWeek,
    required Period period,
  }) : courseOffering = Value(courseOffering),
       dayOfWeek = Value(dayOfWeek),
       period = Value(period);
  static Insertable<Schedule> custom({
    Expression<int>? id,
    Expression<int>? courseOffering,
    Expression<int>? dayOfWeek,
    Expression<int>? period,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (courseOffering != null) 'course_offering': courseOffering,
      if (dayOfWeek != null) 'day_of_week': dayOfWeek,
      if (period != null) 'period': period,
    });
  }

  SchedulesCompanion copyWith({
    Value<int>? id,
    Value<int>? courseOffering,
    Value<DayOfWeek>? dayOfWeek,
    Value<Period>? period,
  }) {
    return SchedulesCompanion(
      id: id ?? this.id,
      courseOffering: courseOffering ?? this.courseOffering,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      period: period ?? this.period,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (courseOffering.present) {
      map['course_offering'] = Variable<int>(courseOffering.value);
    }
    if (dayOfWeek.present) {
      map['day_of_week'] = Variable<int>(
        $SchedulesTable.$converterdayOfWeek.toSql(dayOfWeek.value),
      );
    }
    if (period.present) {
      map['period'] = Variable<int>(
        $SchedulesTable.$converterperiod.toSql(period.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SchedulesCompanion(')
          ..write('id: $id, ')
          ..write('courseOffering: $courseOffering, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('period: $period')
          ..write(')'))
        .toString();
  }
}

class $MaterialsTable extends Materials
    with TableInfo<$MaterialsTable, Material> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MaterialsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _courseOfferingMeta = const VerificationMeta(
    'courseOffering',
  );
  @override
  late final GeneratedColumn<int> courseOffering = GeneratedColumn<int>(
    'course_offering',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES course_offerings (id)',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hrefMeta = const VerificationMeta('href');
  @override
  late final GeneratedColumn<String> href = GeneratedColumn<String>(
    'href',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, courseOffering, title, href];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'materials';
  @override
  VerificationContext validateIntegrity(
    Insertable<Material> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('course_offering')) {
      context.handle(
        _courseOfferingMeta,
        courseOffering.isAcceptableOrUnknown(
          data['course_offering']!,
          _courseOfferingMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_courseOfferingMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('href')) {
      context.handle(
        _hrefMeta,
        href.isAcceptableOrUnknown(data['href']!, _hrefMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {courseOffering, href},
  ];
  @override
  Material map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Material(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      courseOffering: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}course_offering'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      href: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}href'],
      ),
    );
  }

  @override
  $MaterialsTable createAlias(String alias) {
    return $MaterialsTable(attachedDatabase, alias);
  }
}

class Material extends DataClass implements Insertable<Material> {
  /// Auto-incrementing primary key.
  final int id;

  /// Reference to the course offering this material belongs to.
  final int courseOffering;

  /// Title/name of the material or resource.
  final String? title;

  /// SCORM resource identifier for the material.
  ///
  /// This is an encoded identifier from the SCORM manifest, typically starting
  /// with "@" followed by a hash (e.g., "@JMsMWnkmxfPFKNAvTmCuuQOeeDyjdh0hXA_...").
  /// This value is used internally by I-School Plus to locate the resource.
  final String? href;
  const Material({
    required this.id,
    required this.courseOffering,
    this.title,
    this.href,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['course_offering'] = Variable<int>(courseOffering);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || href != null) {
      map['href'] = Variable<String>(href);
    }
    return map;
  }

  MaterialsCompanion toCompanion(bool nullToAbsent) {
    return MaterialsCompanion(
      id: Value(id),
      courseOffering: Value(courseOffering),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      href: href == null && nullToAbsent ? const Value.absent() : Value(href),
    );
  }

  factory Material.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Material(
      id: serializer.fromJson<int>(json['id']),
      courseOffering: serializer.fromJson<int>(json['courseOffering']),
      title: serializer.fromJson<String?>(json['title']),
      href: serializer.fromJson<String?>(json['href']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'courseOffering': serializer.toJson<int>(courseOffering),
      'title': serializer.toJson<String?>(title),
      'href': serializer.toJson<String?>(href),
    };
  }

  Material copyWith({
    int? id,
    int? courseOffering,
    Value<String?> title = const Value.absent(),
    Value<String?> href = const Value.absent(),
  }) => Material(
    id: id ?? this.id,
    courseOffering: courseOffering ?? this.courseOffering,
    title: title.present ? title.value : this.title,
    href: href.present ? href.value : this.href,
  );
  Material copyWithCompanion(MaterialsCompanion data) {
    return Material(
      id: data.id.present ? data.id.value : this.id,
      courseOffering: data.courseOffering.present
          ? data.courseOffering.value
          : this.courseOffering,
      title: data.title.present ? data.title.value : this.title,
      href: data.href.present ? data.href.value : this.href,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Material(')
          ..write('id: $id, ')
          ..write('courseOffering: $courseOffering, ')
          ..write('title: $title, ')
          ..write('href: $href')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, courseOffering, title, href);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Material &&
          other.id == this.id &&
          other.courseOffering == this.courseOffering &&
          other.title == this.title &&
          other.href == this.href);
}

class MaterialsCompanion extends UpdateCompanion<Material> {
  final Value<int> id;
  final Value<int> courseOffering;
  final Value<String?> title;
  final Value<String?> href;
  const MaterialsCompanion({
    this.id = const Value.absent(),
    this.courseOffering = const Value.absent(),
    this.title = const Value.absent(),
    this.href = const Value.absent(),
  });
  MaterialsCompanion.insert({
    this.id = const Value.absent(),
    required int courseOffering,
    this.title = const Value.absent(),
    this.href = const Value.absent(),
  }) : courseOffering = Value(courseOffering);
  static Insertable<Material> custom({
    Expression<int>? id,
    Expression<int>? courseOffering,
    Expression<String>? title,
    Expression<String>? href,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (courseOffering != null) 'course_offering': courseOffering,
      if (title != null) 'title': title,
      if (href != null) 'href': href,
    });
  }

  MaterialsCompanion copyWith({
    Value<int>? id,
    Value<int>? courseOffering,
    Value<String?>? title,
    Value<String?>? href,
  }) {
    return MaterialsCompanion(
      id: id ?? this.id,
      courseOffering: courseOffering ?? this.courseOffering,
      title: title ?? this.title,
      href: href ?? this.href,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (courseOffering.present) {
      map['course_offering'] = Variable<int>(courseOffering.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (href.present) {
      map['href'] = Variable<String>(href.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MaterialsCompanion(')
          ..write('id: $id, ')
          ..write('courseOffering: $courseOffering, ')
          ..write('title: $title, ')
          ..write('href: $href')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $StudentsTable students = $StudentsTable(this);
  late final $SemestersTable semesters = $SemestersTable(this);
  late final $CoursesTable courses = $CoursesTable(this);
  late final $TeachersTable teachers = $TeachersTable(this);
  late final $ClassesTable classes = $ClassesTable(this);
  late final $ClassroomsTable classrooms = $ClassroomsTable(this);
  late final $UsersTable users = $UsersTable(this);
  late final $CourseOfferingsTable courseOfferings = $CourseOfferingsTable(
    this,
  );
  late final $CourseOfferingTeachersTable courseOfferingTeachers =
      $CourseOfferingTeachersTable(this);
  late final $CourseOfferingClassesTable courseOfferingClasses =
      $CourseOfferingClassesTable(this);
  late final $CourseOfferingClassroomsTable courseOfferingClassrooms =
      $CourseOfferingClassroomsTable(this);
  late final $CourseOfferingStudentsTable courseOfferingStudents =
      $CourseOfferingStudentsTable(this);
  late final $SchedulesTable schedules = $SchedulesTable(this);
  late final $MaterialsTable materials = $MaterialsTable(this);
  late final Index userStudent = Index(
    'user_student',
    'CREATE INDEX user_student ON users (student)',
  );
  late final Index courseOfferingCourse = Index(
    'course_offering_course',
    'CREATE INDEX course_offering_course ON course_offerings (course)',
  );
  late final Index courseOfferingSemester = Index(
    'course_offering_semester',
    'CREATE INDEX course_offering_semester ON course_offerings (semester)',
  );
  late final Index scheduleCourseOffering = Index(
    'schedule_course_offering',
    'CREATE INDEX schedule_course_offering ON schedules (course_offering)',
  );
  late final Index materialCourseOffering = Index(
    'material_course_offering',
    'CREATE INDEX material_course_offering ON materials (course_offering)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    students,
    semesters,
    courses,
    teachers,
    classes,
    classrooms,
    users,
    courseOfferings,
    courseOfferingTeachers,
    courseOfferingClasses,
    courseOfferingClassrooms,
    courseOfferingStudents,
    schedules,
    materials,
    userStudent,
    courseOfferingCourse,
    courseOfferingSemester,
    scheduleCourseOffering,
    materialCourseOffering,
  ];
}

typedef $$StudentsTableCreateCompanionBuilder =
    StudentsCompanion Function({
      Value<int> id,
      required String studentId,
      Value<String?> name,
    });
typedef $$StudentsTableUpdateCompanionBuilder =
    StudentsCompanion Function({
      Value<int> id,
      Value<String> studentId,
      Value<String?> name,
    });

final class $$StudentsTableReferences
    extends BaseReferences<_$AppDatabase, $StudentsTable, Student> {
  $$StudentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$UsersTable, List<User>> _usersRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.users,
    aliasName: $_aliasNameGenerator(db.students.id, db.users.student),
  );

  $$UsersTableProcessedTableManager get usersRefs {
    final manager = $$UsersTableTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.student.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_usersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $CourseOfferingStudentsTable,
    List<CourseOfferingStudent>
  >
  _courseOfferingStudentsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.courseOfferingStudents,
        aliasName: $_aliasNameGenerator(
          db.students.id,
          db.courseOfferingStudents.student,
        ),
      );

  $$CourseOfferingStudentsTableProcessedTableManager
  get courseOfferingStudentsRefs {
    final manager = $$CourseOfferingStudentsTableTableManager(
      $_db,
      $_db.courseOfferingStudents,
    ).filter((f) => f.student.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _courseOfferingStudentsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$StudentsTableFilterComposer
    extends Composer<_$AppDatabase, $StudentsTable> {
  $$StudentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get studentId => $composableBuilder(
    column: $table.studentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> usersRefs(
    Expression<bool> Function($$UsersTableFilterComposer f) f,
  ) {
    final $$UsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.student,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> courseOfferingStudentsRefs(
    Expression<bool> Function($$CourseOfferingStudentsTableFilterComposer f) f,
  ) {
    final $$CourseOfferingStudentsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.courseOfferingStudents,
          getReferencedColumn: (t) => t.student,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CourseOfferingStudentsTableFilterComposer(
                $db: $db,
                $table: $db.courseOfferingStudents,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$StudentsTableOrderingComposer
    extends Composer<_$AppDatabase, $StudentsTable> {
  $$StudentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get studentId => $composableBuilder(
    column: $table.studentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StudentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StudentsTable> {
  $$StudentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get studentId =>
      $composableBuilder(column: $table.studentId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  Expression<T> usersRefs<T extends Object>(
    Expression<T> Function($$UsersTableAnnotationComposer a) f,
  ) {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.student,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> courseOfferingStudentsRefs<T extends Object>(
    Expression<T> Function($$CourseOfferingStudentsTableAnnotationComposer a) f,
  ) {
    final $$CourseOfferingStudentsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.courseOfferingStudents,
          getReferencedColumn: (t) => t.student,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CourseOfferingStudentsTableAnnotationComposer(
                $db: $db,
                $table: $db.courseOfferingStudents,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$StudentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StudentsTable,
          Student,
          $$StudentsTableFilterComposer,
          $$StudentsTableOrderingComposer,
          $$StudentsTableAnnotationComposer,
          $$StudentsTableCreateCompanionBuilder,
          $$StudentsTableUpdateCompanionBuilder,
          (Student, $$StudentsTableReferences),
          Student,
          PrefetchHooks Function({
            bool usersRefs,
            bool courseOfferingStudentsRefs,
          })
        > {
  $$StudentsTableTableManager(_$AppDatabase db, $StudentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StudentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StudentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StudentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> studentId = const Value.absent(),
                Value<String?> name = const Value.absent(),
              }) => StudentsCompanion(id: id, studentId: studentId, name: name),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String studentId,
                Value<String?> name = const Value.absent(),
              }) => StudentsCompanion.insert(
                id: id,
                studentId: studentId,
                name: name,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$StudentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({usersRefs = false, courseOfferingStudentsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (usersRefs) db.users,
                    if (courseOfferingStudentsRefs) db.courseOfferingStudents,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (usersRefs)
                        await $_getPrefetchedData<
                          Student,
                          $StudentsTable,
                          User
                        >(
                          currentTable: table,
                          referencedTable: $$StudentsTableReferences
                              ._usersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StudentsTableReferences(
                                db,
                                table,
                                p0,
                              ).usersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.student == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (courseOfferingStudentsRefs)
                        await $_getPrefetchedData<
                          Student,
                          $StudentsTable,
                          CourseOfferingStudent
                        >(
                          currentTable: table,
                          referencedTable: $$StudentsTableReferences
                              ._courseOfferingStudentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StudentsTableReferences(
                                db,
                                table,
                                p0,
                              ).courseOfferingStudentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.student == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$StudentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StudentsTable,
      Student,
      $$StudentsTableFilterComposer,
      $$StudentsTableOrderingComposer,
      $$StudentsTableAnnotationComposer,
      $$StudentsTableCreateCompanionBuilder,
      $$StudentsTableUpdateCompanionBuilder,
      (Student, $$StudentsTableReferences),
      Student,
      PrefetchHooks Function({bool usersRefs, bool courseOfferingStudentsRefs})
    >;
typedef $$SemestersTableCreateCompanionBuilder =
    SemestersCompanion Function({
      Value<int> id,
      required int year,
      required int semester,
    });
typedef $$SemestersTableUpdateCompanionBuilder =
    SemestersCompanion Function({
      Value<int> id,
      Value<int> year,
      Value<int> semester,
    });

final class $$SemestersTableReferences
    extends BaseReferences<_$AppDatabase, $SemestersTable, Semester> {
  $$SemestersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CourseOfferingsTable, List<CourseOffering>>
  _courseOfferingsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.courseOfferings,
    aliasName: $_aliasNameGenerator(
      db.semesters.id,
      db.courseOfferings.semester,
    ),
  );

  $$CourseOfferingsTableProcessedTableManager get courseOfferingsRefs {
    final manager = $$CourseOfferingsTableTableManager(
      $_db,
      $_db.courseOfferings,
    ).filter((f) => f.semester.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _courseOfferingsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SemestersTableFilterComposer
    extends Composer<_$AppDatabase, $SemestersTable> {
  $$SemestersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get semester => $composableBuilder(
    column: $table.semester,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> courseOfferingsRefs(
    Expression<bool> Function($$CourseOfferingsTableFilterComposer f) f,
  ) {
    final $$CourseOfferingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.courseOfferings,
      getReferencedColumn: (t) => t.semester,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseOfferingsTableFilterComposer(
            $db: $db,
            $table: $db.courseOfferings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SemestersTableOrderingComposer
    extends Composer<_$AppDatabase, $SemestersTable> {
  $$SemestersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get semester => $composableBuilder(
    column: $table.semester,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SemestersTableAnnotationComposer
    extends Composer<_$AppDatabase, $SemestersTable> {
  $$SemestersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<int> get semester =>
      $composableBuilder(column: $table.semester, builder: (column) => column);

  Expression<T> courseOfferingsRefs<T extends Object>(
    Expression<T> Function($$CourseOfferingsTableAnnotationComposer a) f,
  ) {
    final $$CourseOfferingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.courseOfferings,
      getReferencedColumn: (t) => t.semester,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseOfferingsTableAnnotationComposer(
            $db: $db,
            $table: $db.courseOfferings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SemestersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SemestersTable,
          Semester,
          $$SemestersTableFilterComposer,
          $$SemestersTableOrderingComposer,
          $$SemestersTableAnnotationComposer,
          $$SemestersTableCreateCompanionBuilder,
          $$SemestersTableUpdateCompanionBuilder,
          (Semester, $$SemestersTableReferences),
          Semester,
          PrefetchHooks Function({bool courseOfferingsRefs})
        > {
  $$SemestersTableTableManager(_$AppDatabase db, $SemestersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SemestersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SemestersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SemestersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> year = const Value.absent(),
                Value<int> semester = const Value.absent(),
              }) => SemestersCompanion(id: id, year: year, semester: semester),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int year,
                required int semester,
              }) => SemestersCompanion.insert(
                id: id,
                year: year,
                semester: semester,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SemestersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({courseOfferingsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (courseOfferingsRefs) db.courseOfferings,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (courseOfferingsRefs)
                    await $_getPrefetchedData<
                      Semester,
                      $SemestersTable,
                      CourseOffering
                    >(
                      currentTable: table,
                      referencedTable: $$SemestersTableReferences
                          ._courseOfferingsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SemestersTableReferences(
                            db,
                            table,
                            p0,
                          ).courseOfferingsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.semester == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SemestersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SemestersTable,
      Semester,
      $$SemestersTableFilterComposer,
      $$SemestersTableOrderingComposer,
      $$SemestersTableAnnotationComposer,
      $$SemestersTableCreateCompanionBuilder,
      $$SemestersTableUpdateCompanionBuilder,
      (Semester, $$SemestersTableReferences),
      Semester,
      PrefetchHooks Function({bool courseOfferingsRefs})
    >;
typedef $$CoursesTableCreateCompanionBuilder =
    CoursesCompanion Function({
      Value<int> id,
      Value<DateTime?> fetchedAt,
      required String code,
      required double credits,
      required int hours,
      Value<String?> nameEn,
      Value<String?> nameZh,
      Value<String?> descriptionEn,
      Value<String?> descriptionZh,
    });
typedef $$CoursesTableUpdateCompanionBuilder =
    CoursesCompanion Function({
      Value<int> id,
      Value<DateTime?> fetchedAt,
      Value<String> code,
      Value<double> credits,
      Value<int> hours,
      Value<String?> nameEn,
      Value<String?> nameZh,
      Value<String?> descriptionEn,
      Value<String?> descriptionZh,
    });

final class $$CoursesTableReferences
    extends BaseReferences<_$AppDatabase, $CoursesTable, Course> {
  $$CoursesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CourseOfferingsTable, List<CourseOffering>>
  _courseOfferingsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.courseOfferings,
    aliasName: $_aliasNameGenerator(db.courses.id, db.courseOfferings.course),
  );

  $$CourseOfferingsTableProcessedTableManager get courseOfferingsRefs {
    final manager = $$CourseOfferingsTableTableManager(
      $_db,
      $_db.courseOfferings,
    ).filter((f) => f.course.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _courseOfferingsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CoursesTableFilterComposer
    extends Composer<_$AppDatabase, $CoursesTable> {
  $$CoursesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get credits => $composableBuilder(
    column: $table.credits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hours => $composableBuilder(
    column: $table.hours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameZh => $composableBuilder(
    column: $table.nameZh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descriptionEn => $composableBuilder(
    column: $table.descriptionEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descriptionZh => $composableBuilder(
    column: $table.descriptionZh,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> courseOfferingsRefs(
    Expression<bool> Function($$CourseOfferingsTableFilterComposer f) f,
  ) {
    final $$CourseOfferingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.courseOfferings,
      getReferencedColumn: (t) => t.course,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseOfferingsTableFilterComposer(
            $db: $db,
            $table: $db.courseOfferings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CoursesTableOrderingComposer
    extends Composer<_$AppDatabase, $CoursesTable> {
  $$CoursesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get credits => $composableBuilder(
    column: $table.credits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hours => $composableBuilder(
    column: $table.hours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameZh => $composableBuilder(
    column: $table.nameZh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descriptionEn => $composableBuilder(
    column: $table.descriptionEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descriptionZh => $composableBuilder(
    column: $table.descriptionZh,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CoursesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CoursesTable> {
  $$CoursesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<double> get credits =>
      $composableBuilder(column: $table.credits, builder: (column) => column);

  GeneratedColumn<int> get hours =>
      $composableBuilder(column: $table.hours, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get nameZh =>
      $composableBuilder(column: $table.nameZh, builder: (column) => column);

  GeneratedColumn<String> get descriptionEn => $composableBuilder(
    column: $table.descriptionEn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get descriptionZh => $composableBuilder(
    column: $table.descriptionZh,
    builder: (column) => column,
  );

  Expression<T> courseOfferingsRefs<T extends Object>(
    Expression<T> Function($$CourseOfferingsTableAnnotationComposer a) f,
  ) {
    final $$CourseOfferingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.courseOfferings,
      getReferencedColumn: (t) => t.course,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseOfferingsTableAnnotationComposer(
            $db: $db,
            $table: $db.courseOfferings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CoursesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CoursesTable,
          Course,
          $$CoursesTableFilterComposer,
          $$CoursesTableOrderingComposer,
          $$CoursesTableAnnotationComposer,
          $$CoursesTableCreateCompanionBuilder,
          $$CoursesTableUpdateCompanionBuilder,
          (Course, $$CoursesTableReferences),
          Course,
          PrefetchHooks Function({bool courseOfferingsRefs})
        > {
  $$CoursesTableTableManager(_$AppDatabase db, $CoursesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CoursesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CoursesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CoursesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime?> fetchedAt = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<double> credits = const Value.absent(),
                Value<int> hours = const Value.absent(),
                Value<String?> nameEn = const Value.absent(),
                Value<String?> nameZh = const Value.absent(),
                Value<String?> descriptionEn = const Value.absent(),
                Value<String?> descriptionZh = const Value.absent(),
              }) => CoursesCompanion(
                id: id,
                fetchedAt: fetchedAt,
                code: code,
                credits: credits,
                hours: hours,
                nameEn: nameEn,
                nameZh: nameZh,
                descriptionEn: descriptionEn,
                descriptionZh: descriptionZh,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime?> fetchedAt = const Value.absent(),
                required String code,
                required double credits,
                required int hours,
                Value<String?> nameEn = const Value.absent(),
                Value<String?> nameZh = const Value.absent(),
                Value<String?> descriptionEn = const Value.absent(),
                Value<String?> descriptionZh = const Value.absent(),
              }) => CoursesCompanion.insert(
                id: id,
                fetchedAt: fetchedAt,
                code: code,
                credits: credits,
                hours: hours,
                nameEn: nameEn,
                nameZh: nameZh,
                descriptionEn: descriptionEn,
                descriptionZh: descriptionZh,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CoursesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({courseOfferingsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (courseOfferingsRefs) db.courseOfferings,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (courseOfferingsRefs)
                    await $_getPrefetchedData<
                      Course,
                      $CoursesTable,
                      CourseOffering
                    >(
                      currentTable: table,
                      referencedTable: $$CoursesTableReferences
                          ._courseOfferingsRefsTable(db),
                      managerFromTypedResult: (p0) => $$CoursesTableReferences(
                        db,
                        table,
                        p0,
                      ).courseOfferingsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.course == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CoursesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CoursesTable,
      Course,
      $$CoursesTableFilterComposer,
      $$CoursesTableOrderingComposer,
      $$CoursesTableAnnotationComposer,
      $$CoursesTableCreateCompanionBuilder,
      $$CoursesTableUpdateCompanionBuilder,
      (Course, $$CoursesTableReferences),
      Course,
      PrefetchHooks Function({bool courseOfferingsRefs})
    >;
typedef $$TeachersTableCreateCompanionBuilder =
    TeachersCompanion Function({
      Value<int> id,
      Value<DateTime?> fetchedAt,
      required String code,
      required String nameZh,
      Value<String?> email,
    });
typedef $$TeachersTableUpdateCompanionBuilder =
    TeachersCompanion Function({
      Value<int> id,
      Value<DateTime?> fetchedAt,
      Value<String> code,
      Value<String> nameZh,
      Value<String?> email,
    });

final class $$TeachersTableReferences
    extends BaseReferences<_$AppDatabase, $TeachersTable, Teacher> {
  $$TeachersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $CourseOfferingTeachersTable,
    List<CourseOfferingTeacher>
  >
  _courseOfferingTeachersRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.courseOfferingTeachers,
        aliasName: $_aliasNameGenerator(
          db.teachers.id,
          db.courseOfferingTeachers.teacher,
        ),
      );

  $$CourseOfferingTeachersTableProcessedTableManager
  get courseOfferingTeachersRefs {
    final manager = $$CourseOfferingTeachersTableTableManager(
      $_db,
      $_db.courseOfferingTeachers,
    ).filter((f) => f.teacher.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _courseOfferingTeachersRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TeachersTableFilterComposer
    extends Composer<_$AppDatabase, $TeachersTable> {
  $$TeachersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameZh => $composableBuilder(
    column: $table.nameZh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> courseOfferingTeachersRefs(
    Expression<bool> Function($$CourseOfferingTeachersTableFilterComposer f) f,
  ) {
    final $$CourseOfferingTeachersTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.courseOfferingTeachers,
          getReferencedColumn: (t) => t.teacher,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CourseOfferingTeachersTableFilterComposer(
                $db: $db,
                $table: $db.courseOfferingTeachers,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$TeachersTableOrderingComposer
    extends Composer<_$AppDatabase, $TeachersTable> {
  $$TeachersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameZh => $composableBuilder(
    column: $table.nameZh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TeachersTableAnnotationComposer
    extends Composer<_$AppDatabase, $TeachersTable> {
  $$TeachersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get nameZh =>
      $composableBuilder(column: $table.nameZh, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  Expression<T> courseOfferingTeachersRefs<T extends Object>(
    Expression<T> Function($$CourseOfferingTeachersTableAnnotationComposer a) f,
  ) {
    final $$CourseOfferingTeachersTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.courseOfferingTeachers,
          getReferencedColumn: (t) => t.teacher,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CourseOfferingTeachersTableAnnotationComposer(
                $db: $db,
                $table: $db.courseOfferingTeachers,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$TeachersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TeachersTable,
          Teacher,
          $$TeachersTableFilterComposer,
          $$TeachersTableOrderingComposer,
          $$TeachersTableAnnotationComposer,
          $$TeachersTableCreateCompanionBuilder,
          $$TeachersTableUpdateCompanionBuilder,
          (Teacher, $$TeachersTableReferences),
          Teacher,
          PrefetchHooks Function({bool courseOfferingTeachersRefs})
        > {
  $$TeachersTableTableManager(_$AppDatabase db, $TeachersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TeachersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TeachersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TeachersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime?> fetchedAt = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> nameZh = const Value.absent(),
                Value<String?> email = const Value.absent(),
              }) => TeachersCompanion(
                id: id,
                fetchedAt: fetchedAt,
                code: code,
                nameZh: nameZh,
                email: email,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime?> fetchedAt = const Value.absent(),
                required String code,
                required String nameZh,
                Value<String?> email = const Value.absent(),
              }) => TeachersCompanion.insert(
                id: id,
                fetchedAt: fetchedAt,
                code: code,
                nameZh: nameZh,
                email: email,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TeachersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({courseOfferingTeachersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (courseOfferingTeachersRefs) db.courseOfferingTeachers,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (courseOfferingTeachersRefs)
                    await $_getPrefetchedData<
                      Teacher,
                      $TeachersTable,
                      CourseOfferingTeacher
                    >(
                      currentTable: table,
                      referencedTable: $$TeachersTableReferences
                          ._courseOfferingTeachersRefsTable(db),
                      managerFromTypedResult: (p0) => $$TeachersTableReferences(
                        db,
                        table,
                        p0,
                      ).courseOfferingTeachersRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.teacher == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TeachersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TeachersTable,
      Teacher,
      $$TeachersTableFilterComposer,
      $$TeachersTableOrderingComposer,
      $$TeachersTableAnnotationComposer,
      $$TeachersTableCreateCompanionBuilder,
      $$TeachersTableUpdateCompanionBuilder,
      (Teacher, $$TeachersTableReferences),
      Teacher,
      PrefetchHooks Function({bool courseOfferingTeachersRefs})
    >;
typedef $$ClassesTableCreateCompanionBuilder =
    ClassesCompanion Function({
      Value<int> id,
      Value<DateTime?> fetchedAt,
      required String code,
      required String nameZh,
    });
typedef $$ClassesTableUpdateCompanionBuilder =
    ClassesCompanion Function({
      Value<int> id,
      Value<DateTime?> fetchedAt,
      Value<String> code,
      Value<String> nameZh,
    });

final class $$ClassesTableReferences
    extends BaseReferences<_$AppDatabase, $ClassesTable, ClassesData> {
  $$ClassesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $CourseOfferingClassesTable,
    List<CourseOfferingClassesData>
  >
  _courseOfferingClassesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.courseOfferingClasses,
        aliasName: $_aliasNameGenerator(
          db.classes.id,
          db.courseOfferingClasses.classEntity,
        ),
      );

  $$CourseOfferingClassesTableProcessedTableManager
  get courseOfferingClassesRefs {
    final manager = $$CourseOfferingClassesTableTableManager(
      $_db,
      $_db.courseOfferingClasses,
    ).filter((f) => f.classEntity.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _courseOfferingClassesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ClassesTableFilterComposer
    extends Composer<_$AppDatabase, $ClassesTable> {
  $$ClassesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameZh => $composableBuilder(
    column: $table.nameZh,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> courseOfferingClassesRefs(
    Expression<bool> Function($$CourseOfferingClassesTableFilterComposer f) f,
  ) {
    final $$CourseOfferingClassesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.courseOfferingClasses,
          getReferencedColumn: (t) => t.classEntity,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CourseOfferingClassesTableFilterComposer(
                $db: $db,
                $table: $db.courseOfferingClasses,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ClassesTableOrderingComposer
    extends Composer<_$AppDatabase, $ClassesTable> {
  $$ClassesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameZh => $composableBuilder(
    column: $table.nameZh,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClassesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClassesTable> {
  $$ClassesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get nameZh =>
      $composableBuilder(column: $table.nameZh, builder: (column) => column);

  Expression<T> courseOfferingClassesRefs<T extends Object>(
    Expression<T> Function($$CourseOfferingClassesTableAnnotationComposer a) f,
  ) {
    final $$CourseOfferingClassesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.courseOfferingClasses,
          getReferencedColumn: (t) => t.classEntity,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CourseOfferingClassesTableAnnotationComposer(
                $db: $db,
                $table: $db.courseOfferingClasses,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ClassesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClassesTable,
          ClassesData,
          $$ClassesTableFilterComposer,
          $$ClassesTableOrderingComposer,
          $$ClassesTableAnnotationComposer,
          $$ClassesTableCreateCompanionBuilder,
          $$ClassesTableUpdateCompanionBuilder,
          (ClassesData, $$ClassesTableReferences),
          ClassesData,
          PrefetchHooks Function({bool courseOfferingClassesRefs})
        > {
  $$ClassesTableTableManager(_$AppDatabase db, $ClassesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClassesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClassesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClassesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime?> fetchedAt = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> nameZh = const Value.absent(),
              }) => ClassesCompanion(
                id: id,
                fetchedAt: fetchedAt,
                code: code,
                nameZh: nameZh,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime?> fetchedAt = const Value.absent(),
                required String code,
                required String nameZh,
              }) => ClassesCompanion.insert(
                id: id,
                fetchedAt: fetchedAt,
                code: code,
                nameZh: nameZh,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ClassesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({courseOfferingClassesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (courseOfferingClassesRefs) db.courseOfferingClasses,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (courseOfferingClassesRefs)
                    await $_getPrefetchedData<
                      ClassesData,
                      $ClassesTable,
                      CourseOfferingClassesData
                    >(
                      currentTable: table,
                      referencedTable: $$ClassesTableReferences
                          ._courseOfferingClassesRefsTable(db),
                      managerFromTypedResult: (p0) => $$ClassesTableReferences(
                        db,
                        table,
                        p0,
                      ).courseOfferingClassesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.classEntity == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ClassesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClassesTable,
      ClassesData,
      $$ClassesTableFilterComposer,
      $$ClassesTableOrderingComposer,
      $$ClassesTableAnnotationComposer,
      $$ClassesTableCreateCompanionBuilder,
      $$ClassesTableUpdateCompanionBuilder,
      (ClassesData, $$ClassesTableReferences),
      ClassesData,
      PrefetchHooks Function({bool courseOfferingClassesRefs})
    >;
typedef $$ClassroomsTableCreateCompanionBuilder =
    ClassroomsCompanion Function({
      Value<int> id,
      Value<DateTime?> fetchedAt,
      required String code,
      required String nameZh,
    });
typedef $$ClassroomsTableUpdateCompanionBuilder =
    ClassroomsCompanion Function({
      Value<int> id,
      Value<DateTime?> fetchedAt,
      Value<String> code,
      Value<String> nameZh,
    });

final class $$ClassroomsTableReferences
    extends BaseReferences<_$AppDatabase, $ClassroomsTable, Classroom> {
  $$ClassroomsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $CourseOfferingClassroomsTable,
    List<CourseOfferingClassroom>
  >
  _courseOfferingClassroomsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.courseOfferingClassrooms,
        aliasName: $_aliasNameGenerator(
          db.classrooms.id,
          db.courseOfferingClassrooms.classroom,
        ),
      );

  $$CourseOfferingClassroomsTableProcessedTableManager
  get courseOfferingClassroomsRefs {
    final manager = $$CourseOfferingClassroomsTableTableManager(
      $_db,
      $_db.courseOfferingClassrooms,
    ).filter((f) => f.classroom.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _courseOfferingClassroomsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ClassroomsTableFilterComposer
    extends Composer<_$AppDatabase, $ClassroomsTable> {
  $$ClassroomsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameZh => $composableBuilder(
    column: $table.nameZh,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> courseOfferingClassroomsRefs(
    Expression<bool> Function($$CourseOfferingClassroomsTableFilterComposer f)
    f,
  ) {
    final $$CourseOfferingClassroomsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.courseOfferingClassrooms,
          getReferencedColumn: (t) => t.classroom,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CourseOfferingClassroomsTableFilterComposer(
                $db: $db,
                $table: $db.courseOfferingClassrooms,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ClassroomsTableOrderingComposer
    extends Composer<_$AppDatabase, $ClassroomsTable> {
  $$ClassroomsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameZh => $composableBuilder(
    column: $table.nameZh,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClassroomsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClassroomsTable> {
  $$ClassroomsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get nameZh =>
      $composableBuilder(column: $table.nameZh, builder: (column) => column);

  Expression<T> courseOfferingClassroomsRefs<T extends Object>(
    Expression<T> Function($$CourseOfferingClassroomsTableAnnotationComposer a)
    f,
  ) {
    final $$CourseOfferingClassroomsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.courseOfferingClassrooms,
          getReferencedColumn: (t) => t.classroom,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CourseOfferingClassroomsTableAnnotationComposer(
                $db: $db,
                $table: $db.courseOfferingClassrooms,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ClassroomsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClassroomsTable,
          Classroom,
          $$ClassroomsTableFilterComposer,
          $$ClassroomsTableOrderingComposer,
          $$ClassroomsTableAnnotationComposer,
          $$ClassroomsTableCreateCompanionBuilder,
          $$ClassroomsTableUpdateCompanionBuilder,
          (Classroom, $$ClassroomsTableReferences),
          Classroom,
          PrefetchHooks Function({bool courseOfferingClassroomsRefs})
        > {
  $$ClassroomsTableTableManager(_$AppDatabase db, $ClassroomsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClassroomsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClassroomsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClassroomsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime?> fetchedAt = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> nameZh = const Value.absent(),
              }) => ClassroomsCompanion(
                id: id,
                fetchedAt: fetchedAt,
                code: code,
                nameZh: nameZh,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime?> fetchedAt = const Value.absent(),
                required String code,
                required String nameZh,
              }) => ClassroomsCompanion.insert(
                id: id,
                fetchedAt: fetchedAt,
                code: code,
                nameZh: nameZh,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ClassroomsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({courseOfferingClassroomsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (courseOfferingClassroomsRefs) db.courseOfferingClassrooms,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (courseOfferingClassroomsRefs)
                    await $_getPrefetchedData<
                      Classroom,
                      $ClassroomsTable,
                      CourseOfferingClassroom
                    >(
                      currentTable: table,
                      referencedTable: $$ClassroomsTableReferences
                          ._courseOfferingClassroomsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ClassroomsTableReferences(
                            db,
                            table,
                            p0,
                          ).courseOfferingClassroomsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.classroom == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ClassroomsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClassroomsTable,
      Classroom,
      $$ClassroomsTableFilterComposer,
      $$ClassroomsTableOrderingComposer,
      $$ClassroomsTableAnnotationComposer,
      $$ClassroomsTableCreateCompanionBuilder,
      $$ClassroomsTableUpdateCompanionBuilder,
      (Classroom, $$ClassroomsTableReferences),
      Classroom,
      PrefetchHooks Function({bool courseOfferingClassroomsRefs})
    >;
typedef $$UsersTableCreateCompanionBuilder =
    UsersCompanion Function({
      Value<int> id,
      required int student,
      required String avatarFilename,
      required String email,
      Value<int?> passwordExpiresInDays,
    });
typedef $$UsersTableUpdateCompanionBuilder =
    UsersCompanion Function({
      Value<int> id,
      Value<int> student,
      Value<String> avatarFilename,
      Value<String> email,
      Value<int?> passwordExpiresInDays,
    });

final class $$UsersTableReferences
    extends BaseReferences<_$AppDatabase, $UsersTable, User> {
  $$UsersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $StudentsTable _studentTable(_$AppDatabase db) => db.students
      .createAlias($_aliasNameGenerator(db.users.student, db.students.id));

  $$StudentsTableProcessedTableManager get student {
    final $_column = $_itemColumn<int>('student')!;

    final manager = $$StudentsTableTableManager(
      $_db,
      $_db.students,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_studentTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarFilename => $composableBuilder(
    column: $table.avatarFilename,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get passwordExpiresInDays => $composableBuilder(
    column: $table.passwordExpiresInDays,
    builder: (column) => ColumnFilters(column),
  );

  $$StudentsTableFilterComposer get student {
    final $$StudentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.student,
      referencedTable: $db.students,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableFilterComposer(
            $db: $db,
            $table: $db.students,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarFilename => $composableBuilder(
    column: $table.avatarFilename,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get passwordExpiresInDays => $composableBuilder(
    column: $table.passwordExpiresInDays,
    builder: (column) => ColumnOrderings(column),
  );

  $$StudentsTableOrderingComposer get student {
    final $$StudentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.student,
      referencedTable: $db.students,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableOrderingComposer(
            $db: $db,
            $table: $db.students,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get avatarFilename => $composableBuilder(
    column: $table.avatarFilename,
    builder: (column) => column,
  );

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<int> get passwordExpiresInDays => $composableBuilder(
    column: $table.passwordExpiresInDays,
    builder: (column) => column,
  );

  $$StudentsTableAnnotationComposer get student {
    final $$StudentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.student,
      referencedTable: $db.students,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableAnnotationComposer(
            $db: $db,
            $table: $db.students,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsersTable,
          User,
          $$UsersTableFilterComposer,
          $$UsersTableOrderingComposer,
          $$UsersTableAnnotationComposer,
          $$UsersTableCreateCompanionBuilder,
          $$UsersTableUpdateCompanionBuilder,
          (User, $$UsersTableReferences),
          User,
          PrefetchHooks Function({bool student})
        > {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> student = const Value.absent(),
                Value<String> avatarFilename = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<int?> passwordExpiresInDays = const Value.absent(),
              }) => UsersCompanion(
                id: id,
                student: student,
                avatarFilename: avatarFilename,
                email: email,
                passwordExpiresInDays: passwordExpiresInDays,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int student,
                required String avatarFilename,
                required String email,
                Value<int?> passwordExpiresInDays = const Value.absent(),
              }) => UsersCompanion.insert(
                id: id,
                student: student,
                avatarFilename: avatarFilename,
                email: email,
                passwordExpiresInDays: passwordExpiresInDays,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$UsersTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({student = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (student) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.student,
                                referencedTable: $$UsersTableReferences
                                    ._studentTable(db),
                                referencedColumn: $$UsersTableReferences
                                    ._studentTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$UsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsersTable,
      User,
      $$UsersTableFilterComposer,
      $$UsersTableOrderingComposer,
      $$UsersTableAnnotationComposer,
      $$UsersTableCreateCompanionBuilder,
      $$UsersTableUpdateCompanionBuilder,
      (User, $$UsersTableReferences),
      User,
      PrefetchHooks Function({bool student})
    >;
typedef $$CourseOfferingsTableCreateCompanionBuilder =
    CourseOfferingsCompanion Function({
      Value<int> id,
      Value<DateTime?> fetchedAt,
      required int course,
      required int semester,
      required String number,
      required int phase,
      required CourseType courseType,
      Value<String?> status,
      Value<String?> language,
      Value<String?> remarks,
      Value<int?> enrolled,
      Value<int?> withdrawn,
      Value<String?> syllabusId,
      Value<DateTime?> syllabusUpdatedAt,
      Value<String?> objective,
      Value<String?> weeklyPlan,
      Value<String?> evaluation,
      Value<String?> textbooks,
    });
typedef $$CourseOfferingsTableUpdateCompanionBuilder =
    CourseOfferingsCompanion Function({
      Value<int> id,
      Value<DateTime?> fetchedAt,
      Value<int> course,
      Value<int> semester,
      Value<String> number,
      Value<int> phase,
      Value<CourseType> courseType,
      Value<String?> status,
      Value<String?> language,
      Value<String?> remarks,
      Value<int?> enrolled,
      Value<int?> withdrawn,
      Value<String?> syllabusId,
      Value<DateTime?> syllabusUpdatedAt,
      Value<String?> objective,
      Value<String?> weeklyPlan,
      Value<String?> evaluation,
      Value<String?> textbooks,
    });

final class $$CourseOfferingsTableReferences
    extends
        BaseReferences<_$AppDatabase, $CourseOfferingsTable, CourseOffering> {
  $$CourseOfferingsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CoursesTable _courseTable(_$AppDatabase db) => db.courses.createAlias(
    $_aliasNameGenerator(db.courseOfferings.course, db.courses.id),
  );

  $$CoursesTableProcessedTableManager get course {
    final $_column = $_itemColumn<int>('course')!;

    final manager = $$CoursesTableTableManager(
      $_db,
      $_db.courses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_courseTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $SemestersTable _semesterTable(_$AppDatabase db) =>
      db.semesters.createAlias(
        $_aliasNameGenerator(db.courseOfferings.semester, db.semesters.id),
      );

  $$SemestersTableProcessedTableManager get semester {
    final $_column = $_itemColumn<int>('semester')!;

    final manager = $$SemestersTableTableManager(
      $_db,
      $_db.semesters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_semesterTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $CourseOfferingTeachersTable,
    List<CourseOfferingTeacher>
  >
  _courseOfferingTeachersRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.courseOfferingTeachers,
        aliasName: $_aliasNameGenerator(
          db.courseOfferings.id,
          db.courseOfferingTeachers.courseOffering,
        ),
      );

  $$CourseOfferingTeachersTableProcessedTableManager
  get courseOfferingTeachersRefs {
    final manager = $$CourseOfferingTeachersTableTableManager(
      $_db,
      $_db.courseOfferingTeachers,
    ).filter((f) => f.courseOffering.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _courseOfferingTeachersRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $CourseOfferingClassesTable,
    List<CourseOfferingClassesData>
  >
  _courseOfferingClassesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.courseOfferingClasses,
        aliasName: $_aliasNameGenerator(
          db.courseOfferings.id,
          db.courseOfferingClasses.courseOffering,
        ),
      );

  $$CourseOfferingClassesTableProcessedTableManager
  get courseOfferingClassesRefs {
    final manager = $$CourseOfferingClassesTableTableManager(
      $_db,
      $_db.courseOfferingClasses,
    ).filter((f) => f.courseOffering.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _courseOfferingClassesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $CourseOfferingClassroomsTable,
    List<CourseOfferingClassroom>
  >
  _courseOfferingClassroomsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.courseOfferingClassrooms,
        aliasName: $_aliasNameGenerator(
          db.courseOfferings.id,
          db.courseOfferingClassrooms.courseOffering,
        ),
      );

  $$CourseOfferingClassroomsTableProcessedTableManager
  get courseOfferingClassroomsRefs {
    final manager = $$CourseOfferingClassroomsTableTableManager(
      $_db,
      $_db.courseOfferingClassrooms,
    ).filter((f) => f.courseOffering.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _courseOfferingClassroomsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $CourseOfferingStudentsTable,
    List<CourseOfferingStudent>
  >
  _courseOfferingStudentsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.courseOfferingStudents,
        aliasName: $_aliasNameGenerator(
          db.courseOfferings.id,
          db.courseOfferingStudents.courseOffering,
        ),
      );

  $$CourseOfferingStudentsTableProcessedTableManager
  get courseOfferingStudentsRefs {
    final manager = $$CourseOfferingStudentsTableTableManager(
      $_db,
      $_db.courseOfferingStudents,
    ).filter((f) => f.courseOffering.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _courseOfferingStudentsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SchedulesTable, List<Schedule>>
  _schedulesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.schedules,
    aliasName: $_aliasNameGenerator(
      db.courseOfferings.id,
      db.schedules.courseOffering,
    ),
  );

  $$SchedulesTableProcessedTableManager get schedulesRefs {
    final manager = $$SchedulesTableTableManager(
      $_db,
      $_db.schedules,
    ).filter((f) => f.courseOffering.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_schedulesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MaterialsTable, List<Material>>
  _materialsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.materials,
    aliasName: $_aliasNameGenerator(
      db.courseOfferings.id,
      db.materials.courseOffering,
    ),
  );

  $$MaterialsTableProcessedTableManager get materialsRefs {
    final manager = $$MaterialsTableTableManager(
      $_db,
      $_db.materials,
    ).filter((f) => f.courseOffering.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_materialsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CourseOfferingsTableFilterComposer
    extends Composer<_$AppDatabase, $CourseOfferingsTable> {
  $$CourseOfferingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get phase => $composableBuilder(
    column: $table.phase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CourseType, CourseType, String>
  get courseType => $composableBuilder(
    column: $table.courseType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remarks => $composableBuilder(
    column: $table.remarks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get enrolled => $composableBuilder(
    column: $table.enrolled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get withdrawn => $composableBuilder(
    column: $table.withdrawn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syllabusId => $composableBuilder(
    column: $table.syllabusId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syllabusUpdatedAt => $composableBuilder(
    column: $table.syllabusUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get objective => $composableBuilder(
    column: $table.objective,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weeklyPlan => $composableBuilder(
    column: $table.weeklyPlan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get evaluation => $composableBuilder(
    column: $table.evaluation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textbooks => $composableBuilder(
    column: $table.textbooks,
    builder: (column) => ColumnFilters(column),
  );

  $$CoursesTableFilterComposer get course {
    final $$CoursesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.course,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableFilterComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SemestersTableFilterComposer get semester {
    final $$SemestersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semester,
      referencedTable: $db.semesters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemestersTableFilterComposer(
            $db: $db,
            $table: $db.semesters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> courseOfferingTeachersRefs(
    Expression<bool> Function($$CourseOfferingTeachersTableFilterComposer f) f,
  ) {
    final $$CourseOfferingTeachersTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.courseOfferingTeachers,
          getReferencedColumn: (t) => t.courseOffering,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CourseOfferingTeachersTableFilterComposer(
                $db: $db,
                $table: $db.courseOfferingTeachers,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> courseOfferingClassesRefs(
    Expression<bool> Function($$CourseOfferingClassesTableFilterComposer f) f,
  ) {
    final $$CourseOfferingClassesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.courseOfferingClasses,
          getReferencedColumn: (t) => t.courseOffering,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CourseOfferingClassesTableFilterComposer(
                $db: $db,
                $table: $db.courseOfferingClasses,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> courseOfferingClassroomsRefs(
    Expression<bool> Function($$CourseOfferingClassroomsTableFilterComposer f)
    f,
  ) {
    final $$CourseOfferingClassroomsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.courseOfferingClassrooms,
          getReferencedColumn: (t) => t.courseOffering,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CourseOfferingClassroomsTableFilterComposer(
                $db: $db,
                $table: $db.courseOfferingClassrooms,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> courseOfferingStudentsRefs(
    Expression<bool> Function($$CourseOfferingStudentsTableFilterComposer f) f,
  ) {
    final $$CourseOfferingStudentsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.courseOfferingStudents,
          getReferencedColumn: (t) => t.courseOffering,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CourseOfferingStudentsTableFilterComposer(
                $db: $db,
                $table: $db.courseOfferingStudents,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> schedulesRefs(
    Expression<bool> Function($$SchedulesTableFilterComposer f) f,
  ) {
    final $$SchedulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.schedules,
      getReferencedColumn: (t) => t.courseOffering,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SchedulesTableFilterComposer(
            $db: $db,
            $table: $db.schedules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> materialsRefs(
    Expression<bool> Function($$MaterialsTableFilterComposer f) f,
  ) {
    final $$MaterialsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.materials,
      getReferencedColumn: (t) => t.courseOffering,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MaterialsTableFilterComposer(
            $db: $db,
            $table: $db.materials,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CourseOfferingsTableOrderingComposer
    extends Composer<_$AppDatabase, $CourseOfferingsTable> {
  $$CourseOfferingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get phase => $composableBuilder(
    column: $table.phase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get courseType => $composableBuilder(
    column: $table.courseType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remarks => $composableBuilder(
    column: $table.remarks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get enrolled => $composableBuilder(
    column: $table.enrolled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get withdrawn => $composableBuilder(
    column: $table.withdrawn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syllabusId => $composableBuilder(
    column: $table.syllabusId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syllabusUpdatedAt => $composableBuilder(
    column: $table.syllabusUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get objective => $composableBuilder(
    column: $table.objective,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weeklyPlan => $composableBuilder(
    column: $table.weeklyPlan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get evaluation => $composableBuilder(
    column: $table.evaluation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textbooks => $composableBuilder(
    column: $table.textbooks,
    builder: (column) => ColumnOrderings(column),
  );

  $$CoursesTableOrderingComposer get course {
    final $$CoursesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.course,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableOrderingComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SemestersTableOrderingComposer get semester {
    final $$SemestersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semester,
      referencedTable: $db.semesters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemestersTableOrderingComposer(
            $db: $db,
            $table: $db.semesters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CourseOfferingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CourseOfferingsTable> {
  $$CourseOfferingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<String> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<int> get phase =>
      $composableBuilder(column: $table.phase, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CourseType, String> get courseType =>
      $composableBuilder(
        column: $table.courseType,
        builder: (column) => column,
      );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get remarks =>
      $composableBuilder(column: $table.remarks, builder: (column) => column);

  GeneratedColumn<int> get enrolled =>
      $composableBuilder(column: $table.enrolled, builder: (column) => column);

  GeneratedColumn<int> get withdrawn =>
      $composableBuilder(column: $table.withdrawn, builder: (column) => column);

  GeneratedColumn<String> get syllabusId => $composableBuilder(
    column: $table.syllabusId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syllabusUpdatedAt => $composableBuilder(
    column: $table.syllabusUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get objective =>
      $composableBuilder(column: $table.objective, builder: (column) => column);

  GeneratedColumn<String> get weeklyPlan => $composableBuilder(
    column: $table.weeklyPlan,
    builder: (column) => column,
  );

  GeneratedColumn<String> get evaluation => $composableBuilder(
    column: $table.evaluation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get textbooks =>
      $composableBuilder(column: $table.textbooks, builder: (column) => column);

  $$CoursesTableAnnotationComposer get course {
    final $$CoursesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.course,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableAnnotationComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SemestersTableAnnotationComposer get semester {
    final $$SemestersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.semester,
      referencedTable: $db.semesters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SemestersTableAnnotationComposer(
            $db: $db,
            $table: $db.semesters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> courseOfferingTeachersRefs<T extends Object>(
    Expression<T> Function($$CourseOfferingTeachersTableAnnotationComposer a) f,
  ) {
    final $$CourseOfferingTeachersTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.courseOfferingTeachers,
          getReferencedColumn: (t) => t.courseOffering,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CourseOfferingTeachersTableAnnotationComposer(
                $db: $db,
                $table: $db.courseOfferingTeachers,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> courseOfferingClassesRefs<T extends Object>(
    Expression<T> Function($$CourseOfferingClassesTableAnnotationComposer a) f,
  ) {
    final $$CourseOfferingClassesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.courseOfferingClasses,
          getReferencedColumn: (t) => t.courseOffering,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CourseOfferingClassesTableAnnotationComposer(
                $db: $db,
                $table: $db.courseOfferingClasses,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> courseOfferingClassroomsRefs<T extends Object>(
    Expression<T> Function($$CourseOfferingClassroomsTableAnnotationComposer a)
    f,
  ) {
    final $$CourseOfferingClassroomsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.courseOfferingClassrooms,
          getReferencedColumn: (t) => t.courseOffering,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CourseOfferingClassroomsTableAnnotationComposer(
                $db: $db,
                $table: $db.courseOfferingClassrooms,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> courseOfferingStudentsRefs<T extends Object>(
    Expression<T> Function($$CourseOfferingStudentsTableAnnotationComposer a) f,
  ) {
    final $$CourseOfferingStudentsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.courseOfferingStudents,
          getReferencedColumn: (t) => t.courseOffering,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CourseOfferingStudentsTableAnnotationComposer(
                $db: $db,
                $table: $db.courseOfferingStudents,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> schedulesRefs<T extends Object>(
    Expression<T> Function($$SchedulesTableAnnotationComposer a) f,
  ) {
    final $$SchedulesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.schedules,
      getReferencedColumn: (t) => t.courseOffering,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SchedulesTableAnnotationComposer(
            $db: $db,
            $table: $db.schedules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> materialsRefs<T extends Object>(
    Expression<T> Function($$MaterialsTableAnnotationComposer a) f,
  ) {
    final $$MaterialsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.materials,
      getReferencedColumn: (t) => t.courseOffering,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MaterialsTableAnnotationComposer(
            $db: $db,
            $table: $db.materials,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CourseOfferingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CourseOfferingsTable,
          CourseOffering,
          $$CourseOfferingsTableFilterComposer,
          $$CourseOfferingsTableOrderingComposer,
          $$CourseOfferingsTableAnnotationComposer,
          $$CourseOfferingsTableCreateCompanionBuilder,
          $$CourseOfferingsTableUpdateCompanionBuilder,
          (CourseOffering, $$CourseOfferingsTableReferences),
          CourseOffering,
          PrefetchHooks Function({
            bool course,
            bool semester,
            bool courseOfferingTeachersRefs,
            bool courseOfferingClassesRefs,
            bool courseOfferingClassroomsRefs,
            bool courseOfferingStudentsRefs,
            bool schedulesRefs,
            bool materialsRefs,
          })
        > {
  $$CourseOfferingsTableTableManager(
    _$AppDatabase db,
    $CourseOfferingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CourseOfferingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CourseOfferingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CourseOfferingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime?> fetchedAt = const Value.absent(),
                Value<int> course = const Value.absent(),
                Value<int> semester = const Value.absent(),
                Value<String> number = const Value.absent(),
                Value<int> phase = const Value.absent(),
                Value<CourseType> courseType = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<String?> language = const Value.absent(),
                Value<String?> remarks = const Value.absent(),
                Value<int?> enrolled = const Value.absent(),
                Value<int?> withdrawn = const Value.absent(),
                Value<String?> syllabusId = const Value.absent(),
                Value<DateTime?> syllabusUpdatedAt = const Value.absent(),
                Value<String?> objective = const Value.absent(),
                Value<String?> weeklyPlan = const Value.absent(),
                Value<String?> evaluation = const Value.absent(),
                Value<String?> textbooks = const Value.absent(),
              }) => CourseOfferingsCompanion(
                id: id,
                fetchedAt: fetchedAt,
                course: course,
                semester: semester,
                number: number,
                phase: phase,
                courseType: courseType,
                status: status,
                language: language,
                remarks: remarks,
                enrolled: enrolled,
                withdrawn: withdrawn,
                syllabusId: syllabusId,
                syllabusUpdatedAt: syllabusUpdatedAt,
                objective: objective,
                weeklyPlan: weeklyPlan,
                evaluation: evaluation,
                textbooks: textbooks,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime?> fetchedAt = const Value.absent(),
                required int course,
                required int semester,
                required String number,
                required int phase,
                required CourseType courseType,
                Value<String?> status = const Value.absent(),
                Value<String?> language = const Value.absent(),
                Value<String?> remarks = const Value.absent(),
                Value<int?> enrolled = const Value.absent(),
                Value<int?> withdrawn = const Value.absent(),
                Value<String?> syllabusId = const Value.absent(),
                Value<DateTime?> syllabusUpdatedAt = const Value.absent(),
                Value<String?> objective = const Value.absent(),
                Value<String?> weeklyPlan = const Value.absent(),
                Value<String?> evaluation = const Value.absent(),
                Value<String?> textbooks = const Value.absent(),
              }) => CourseOfferingsCompanion.insert(
                id: id,
                fetchedAt: fetchedAt,
                course: course,
                semester: semester,
                number: number,
                phase: phase,
                courseType: courseType,
                status: status,
                language: language,
                remarks: remarks,
                enrolled: enrolled,
                withdrawn: withdrawn,
                syllabusId: syllabusId,
                syllabusUpdatedAt: syllabusUpdatedAt,
                objective: objective,
                weeklyPlan: weeklyPlan,
                evaluation: evaluation,
                textbooks: textbooks,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CourseOfferingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                course = false,
                semester = false,
                courseOfferingTeachersRefs = false,
                courseOfferingClassesRefs = false,
                courseOfferingClassroomsRefs = false,
                courseOfferingStudentsRefs = false,
                schedulesRefs = false,
                materialsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (courseOfferingTeachersRefs) db.courseOfferingTeachers,
                    if (courseOfferingClassesRefs) db.courseOfferingClasses,
                    if (courseOfferingClassroomsRefs)
                      db.courseOfferingClassrooms,
                    if (courseOfferingStudentsRefs) db.courseOfferingStudents,
                    if (schedulesRefs) db.schedules,
                    if (materialsRefs) db.materials,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (course) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.course,
                                    referencedTable:
                                        $$CourseOfferingsTableReferences
                                            ._courseTable(db),
                                    referencedColumn:
                                        $$CourseOfferingsTableReferences
                                            ._courseTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (semester) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.semester,
                                    referencedTable:
                                        $$CourseOfferingsTableReferences
                                            ._semesterTable(db),
                                    referencedColumn:
                                        $$CourseOfferingsTableReferences
                                            ._semesterTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (courseOfferingTeachersRefs)
                        await $_getPrefetchedData<
                          CourseOffering,
                          $CourseOfferingsTable,
                          CourseOfferingTeacher
                        >(
                          currentTable: table,
                          referencedTable: $$CourseOfferingsTableReferences
                              ._courseOfferingTeachersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CourseOfferingsTableReferences(
                                db,
                                table,
                                p0,
                              ).courseOfferingTeachersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.courseOffering == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (courseOfferingClassesRefs)
                        await $_getPrefetchedData<
                          CourseOffering,
                          $CourseOfferingsTable,
                          CourseOfferingClassesData
                        >(
                          currentTable: table,
                          referencedTable: $$CourseOfferingsTableReferences
                              ._courseOfferingClassesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CourseOfferingsTableReferences(
                                db,
                                table,
                                p0,
                              ).courseOfferingClassesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.courseOffering == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (courseOfferingClassroomsRefs)
                        await $_getPrefetchedData<
                          CourseOffering,
                          $CourseOfferingsTable,
                          CourseOfferingClassroom
                        >(
                          currentTable: table,
                          referencedTable: $$CourseOfferingsTableReferences
                              ._courseOfferingClassroomsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CourseOfferingsTableReferences(
                                db,
                                table,
                                p0,
                              ).courseOfferingClassroomsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.courseOffering == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (courseOfferingStudentsRefs)
                        await $_getPrefetchedData<
                          CourseOffering,
                          $CourseOfferingsTable,
                          CourseOfferingStudent
                        >(
                          currentTable: table,
                          referencedTable: $$CourseOfferingsTableReferences
                              ._courseOfferingStudentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CourseOfferingsTableReferences(
                                db,
                                table,
                                p0,
                              ).courseOfferingStudentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.courseOffering == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (schedulesRefs)
                        await $_getPrefetchedData<
                          CourseOffering,
                          $CourseOfferingsTable,
                          Schedule
                        >(
                          currentTable: table,
                          referencedTable: $$CourseOfferingsTableReferences
                              ._schedulesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CourseOfferingsTableReferences(
                                db,
                                table,
                                p0,
                              ).schedulesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.courseOffering == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (materialsRefs)
                        await $_getPrefetchedData<
                          CourseOffering,
                          $CourseOfferingsTable,
                          Material
                        >(
                          currentTable: table,
                          referencedTable: $$CourseOfferingsTableReferences
                              ._materialsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CourseOfferingsTableReferences(
                                db,
                                table,
                                p0,
                              ).materialsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.courseOffering == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CourseOfferingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CourseOfferingsTable,
      CourseOffering,
      $$CourseOfferingsTableFilterComposer,
      $$CourseOfferingsTableOrderingComposer,
      $$CourseOfferingsTableAnnotationComposer,
      $$CourseOfferingsTableCreateCompanionBuilder,
      $$CourseOfferingsTableUpdateCompanionBuilder,
      (CourseOffering, $$CourseOfferingsTableReferences),
      CourseOffering,
      PrefetchHooks Function({
        bool course,
        bool semester,
        bool courseOfferingTeachersRefs,
        bool courseOfferingClassesRefs,
        bool courseOfferingClassroomsRefs,
        bool courseOfferingStudentsRefs,
        bool schedulesRefs,
        bool materialsRefs,
      })
    >;
typedef $$CourseOfferingTeachersTableCreateCompanionBuilder =
    CourseOfferingTeachersCompanion Function({
      required int courseOffering,
      required int teacher,
      Value<int> rowid,
    });
typedef $$CourseOfferingTeachersTableUpdateCompanionBuilder =
    CourseOfferingTeachersCompanion Function({
      Value<int> courseOffering,
      Value<int> teacher,
      Value<int> rowid,
    });

final class $$CourseOfferingTeachersTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CourseOfferingTeachersTable,
          CourseOfferingTeacher
        > {
  $$CourseOfferingTeachersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CourseOfferingsTable _courseOfferingTable(_$AppDatabase db) =>
      db.courseOfferings.createAlias(
        $_aliasNameGenerator(
          db.courseOfferingTeachers.courseOffering,
          db.courseOfferings.id,
        ),
      );

  $$CourseOfferingsTableProcessedTableManager get courseOffering {
    final $_column = $_itemColumn<int>('course_offering')!;

    final manager = $$CourseOfferingsTableTableManager(
      $_db,
      $_db.courseOfferings,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_courseOfferingTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TeachersTable _teacherTable(_$AppDatabase db) =>
      db.teachers.createAlias(
        $_aliasNameGenerator(db.courseOfferingTeachers.teacher, db.teachers.id),
      );

  $$TeachersTableProcessedTableManager get teacher {
    final $_column = $_itemColumn<int>('teacher')!;

    final manager = $$TeachersTableTableManager(
      $_db,
      $_db.teachers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_teacherTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CourseOfferingTeachersTableFilterComposer
    extends Composer<_$AppDatabase, $CourseOfferingTeachersTable> {
  $$CourseOfferingTeachersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$CourseOfferingsTableFilterComposer get courseOffering {
    final $$CourseOfferingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseOffering,
      referencedTable: $db.courseOfferings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseOfferingsTableFilterComposer(
            $db: $db,
            $table: $db.courseOfferings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TeachersTableFilterComposer get teacher {
    final $$TeachersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teacher,
      referencedTable: $db.teachers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeachersTableFilterComposer(
            $db: $db,
            $table: $db.teachers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CourseOfferingTeachersTableOrderingComposer
    extends Composer<_$AppDatabase, $CourseOfferingTeachersTable> {
  $$CourseOfferingTeachersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$CourseOfferingsTableOrderingComposer get courseOffering {
    final $$CourseOfferingsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseOffering,
      referencedTable: $db.courseOfferings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseOfferingsTableOrderingComposer(
            $db: $db,
            $table: $db.courseOfferings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TeachersTableOrderingComposer get teacher {
    final $$TeachersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teacher,
      referencedTable: $db.teachers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeachersTableOrderingComposer(
            $db: $db,
            $table: $db.teachers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CourseOfferingTeachersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CourseOfferingTeachersTable> {
  $$CourseOfferingTeachersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$CourseOfferingsTableAnnotationComposer get courseOffering {
    final $$CourseOfferingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseOffering,
      referencedTable: $db.courseOfferings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseOfferingsTableAnnotationComposer(
            $db: $db,
            $table: $db.courseOfferings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TeachersTableAnnotationComposer get teacher {
    final $$TeachersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teacher,
      referencedTable: $db.teachers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeachersTableAnnotationComposer(
            $db: $db,
            $table: $db.teachers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CourseOfferingTeachersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CourseOfferingTeachersTable,
          CourseOfferingTeacher,
          $$CourseOfferingTeachersTableFilterComposer,
          $$CourseOfferingTeachersTableOrderingComposer,
          $$CourseOfferingTeachersTableAnnotationComposer,
          $$CourseOfferingTeachersTableCreateCompanionBuilder,
          $$CourseOfferingTeachersTableUpdateCompanionBuilder,
          (CourseOfferingTeacher, $$CourseOfferingTeachersTableReferences),
          CourseOfferingTeacher,
          PrefetchHooks Function({bool courseOffering, bool teacher})
        > {
  $$CourseOfferingTeachersTableTableManager(
    _$AppDatabase db,
    $CourseOfferingTeachersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CourseOfferingTeachersTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CourseOfferingTeachersTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CourseOfferingTeachersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> courseOffering = const Value.absent(),
                Value<int> teacher = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CourseOfferingTeachersCompanion(
                courseOffering: courseOffering,
                teacher: teacher,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int courseOffering,
                required int teacher,
                Value<int> rowid = const Value.absent(),
              }) => CourseOfferingTeachersCompanion.insert(
                courseOffering: courseOffering,
                teacher: teacher,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CourseOfferingTeachersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({courseOffering = false, teacher = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (courseOffering) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.courseOffering,
                                referencedTable:
                                    $$CourseOfferingTeachersTableReferences
                                        ._courseOfferingTable(db),
                                referencedColumn:
                                    $$CourseOfferingTeachersTableReferences
                                        ._courseOfferingTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (teacher) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.teacher,
                                referencedTable:
                                    $$CourseOfferingTeachersTableReferences
                                        ._teacherTable(db),
                                referencedColumn:
                                    $$CourseOfferingTeachersTableReferences
                                        ._teacherTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CourseOfferingTeachersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CourseOfferingTeachersTable,
      CourseOfferingTeacher,
      $$CourseOfferingTeachersTableFilterComposer,
      $$CourseOfferingTeachersTableOrderingComposer,
      $$CourseOfferingTeachersTableAnnotationComposer,
      $$CourseOfferingTeachersTableCreateCompanionBuilder,
      $$CourseOfferingTeachersTableUpdateCompanionBuilder,
      (CourseOfferingTeacher, $$CourseOfferingTeachersTableReferences),
      CourseOfferingTeacher,
      PrefetchHooks Function({bool courseOffering, bool teacher})
    >;
typedef $$CourseOfferingClassesTableCreateCompanionBuilder =
    CourseOfferingClassesCompanion Function({
      required int courseOffering,
      required int classEntity,
      Value<int> rowid,
    });
typedef $$CourseOfferingClassesTableUpdateCompanionBuilder =
    CourseOfferingClassesCompanion Function({
      Value<int> courseOffering,
      Value<int> classEntity,
      Value<int> rowid,
    });

final class $$CourseOfferingClassesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CourseOfferingClassesTable,
          CourseOfferingClassesData
        > {
  $$CourseOfferingClassesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CourseOfferingsTable _courseOfferingTable(_$AppDatabase db) =>
      db.courseOfferings.createAlias(
        $_aliasNameGenerator(
          db.courseOfferingClasses.courseOffering,
          db.courseOfferings.id,
        ),
      );

  $$CourseOfferingsTableProcessedTableManager get courseOffering {
    final $_column = $_itemColumn<int>('course_offering')!;

    final manager = $$CourseOfferingsTableTableManager(
      $_db,
      $_db.courseOfferings,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_courseOfferingTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ClassesTable _classEntityTable(_$AppDatabase db) =>
      db.classes.createAlias(
        $_aliasNameGenerator(
          db.courseOfferingClasses.classEntity,
          db.classes.id,
        ),
      );

  $$ClassesTableProcessedTableManager get classEntity {
    final $_column = $_itemColumn<int>('class_entity')!;

    final manager = $$ClassesTableTableManager(
      $_db,
      $_db.classes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_classEntityTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CourseOfferingClassesTableFilterComposer
    extends Composer<_$AppDatabase, $CourseOfferingClassesTable> {
  $$CourseOfferingClassesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$CourseOfferingsTableFilterComposer get courseOffering {
    final $$CourseOfferingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseOffering,
      referencedTable: $db.courseOfferings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseOfferingsTableFilterComposer(
            $db: $db,
            $table: $db.courseOfferings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ClassesTableFilterComposer get classEntity {
    final $$ClassesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.classEntity,
      referencedTable: $db.classes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClassesTableFilterComposer(
            $db: $db,
            $table: $db.classes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CourseOfferingClassesTableOrderingComposer
    extends Composer<_$AppDatabase, $CourseOfferingClassesTable> {
  $$CourseOfferingClassesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$CourseOfferingsTableOrderingComposer get courseOffering {
    final $$CourseOfferingsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseOffering,
      referencedTable: $db.courseOfferings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseOfferingsTableOrderingComposer(
            $db: $db,
            $table: $db.courseOfferings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ClassesTableOrderingComposer get classEntity {
    final $$ClassesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.classEntity,
      referencedTable: $db.classes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClassesTableOrderingComposer(
            $db: $db,
            $table: $db.classes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CourseOfferingClassesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CourseOfferingClassesTable> {
  $$CourseOfferingClassesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$CourseOfferingsTableAnnotationComposer get courseOffering {
    final $$CourseOfferingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseOffering,
      referencedTable: $db.courseOfferings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseOfferingsTableAnnotationComposer(
            $db: $db,
            $table: $db.courseOfferings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ClassesTableAnnotationComposer get classEntity {
    final $$ClassesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.classEntity,
      referencedTable: $db.classes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClassesTableAnnotationComposer(
            $db: $db,
            $table: $db.classes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CourseOfferingClassesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CourseOfferingClassesTable,
          CourseOfferingClassesData,
          $$CourseOfferingClassesTableFilterComposer,
          $$CourseOfferingClassesTableOrderingComposer,
          $$CourseOfferingClassesTableAnnotationComposer,
          $$CourseOfferingClassesTableCreateCompanionBuilder,
          $$CourseOfferingClassesTableUpdateCompanionBuilder,
          (CourseOfferingClassesData, $$CourseOfferingClassesTableReferences),
          CourseOfferingClassesData,
          PrefetchHooks Function({bool courseOffering, bool classEntity})
        > {
  $$CourseOfferingClassesTableTableManager(
    _$AppDatabase db,
    $CourseOfferingClassesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CourseOfferingClassesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CourseOfferingClassesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CourseOfferingClassesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> courseOffering = const Value.absent(),
                Value<int> classEntity = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CourseOfferingClassesCompanion(
                courseOffering: courseOffering,
                classEntity: classEntity,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int courseOffering,
                required int classEntity,
                Value<int> rowid = const Value.absent(),
              }) => CourseOfferingClassesCompanion.insert(
                courseOffering: courseOffering,
                classEntity: classEntity,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CourseOfferingClassesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({courseOffering = false, classEntity = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (courseOffering) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.courseOffering,
                                    referencedTable:
                                        $$CourseOfferingClassesTableReferences
                                            ._courseOfferingTable(db),
                                    referencedColumn:
                                        $$CourseOfferingClassesTableReferences
                                            ._courseOfferingTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (classEntity) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.classEntity,
                                    referencedTable:
                                        $$CourseOfferingClassesTableReferences
                                            ._classEntityTable(db),
                                    referencedColumn:
                                        $$CourseOfferingClassesTableReferences
                                            ._classEntityTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$CourseOfferingClassesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CourseOfferingClassesTable,
      CourseOfferingClassesData,
      $$CourseOfferingClassesTableFilterComposer,
      $$CourseOfferingClassesTableOrderingComposer,
      $$CourseOfferingClassesTableAnnotationComposer,
      $$CourseOfferingClassesTableCreateCompanionBuilder,
      $$CourseOfferingClassesTableUpdateCompanionBuilder,
      (CourseOfferingClassesData, $$CourseOfferingClassesTableReferences),
      CourseOfferingClassesData,
      PrefetchHooks Function({bool courseOffering, bool classEntity})
    >;
typedef $$CourseOfferingClassroomsTableCreateCompanionBuilder =
    CourseOfferingClassroomsCompanion Function({
      required int courseOffering,
      required int classroom,
      Value<int> rowid,
    });
typedef $$CourseOfferingClassroomsTableUpdateCompanionBuilder =
    CourseOfferingClassroomsCompanion Function({
      Value<int> courseOffering,
      Value<int> classroom,
      Value<int> rowid,
    });

final class $$CourseOfferingClassroomsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CourseOfferingClassroomsTable,
          CourseOfferingClassroom
        > {
  $$CourseOfferingClassroomsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CourseOfferingsTable _courseOfferingTable(_$AppDatabase db) =>
      db.courseOfferings.createAlias(
        $_aliasNameGenerator(
          db.courseOfferingClassrooms.courseOffering,
          db.courseOfferings.id,
        ),
      );

  $$CourseOfferingsTableProcessedTableManager get courseOffering {
    final $_column = $_itemColumn<int>('course_offering')!;

    final manager = $$CourseOfferingsTableTableManager(
      $_db,
      $_db.courseOfferings,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_courseOfferingTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ClassroomsTable _classroomTable(_$AppDatabase db) =>
      db.classrooms.createAlias(
        $_aliasNameGenerator(
          db.courseOfferingClassrooms.classroom,
          db.classrooms.id,
        ),
      );

  $$ClassroomsTableProcessedTableManager get classroom {
    final $_column = $_itemColumn<int>('classroom')!;

    final manager = $$ClassroomsTableTableManager(
      $_db,
      $_db.classrooms,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_classroomTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CourseOfferingClassroomsTableFilterComposer
    extends Composer<_$AppDatabase, $CourseOfferingClassroomsTable> {
  $$CourseOfferingClassroomsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$CourseOfferingsTableFilterComposer get courseOffering {
    final $$CourseOfferingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseOffering,
      referencedTable: $db.courseOfferings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseOfferingsTableFilterComposer(
            $db: $db,
            $table: $db.courseOfferings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ClassroomsTableFilterComposer get classroom {
    final $$ClassroomsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.classroom,
      referencedTable: $db.classrooms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClassroomsTableFilterComposer(
            $db: $db,
            $table: $db.classrooms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CourseOfferingClassroomsTableOrderingComposer
    extends Composer<_$AppDatabase, $CourseOfferingClassroomsTable> {
  $$CourseOfferingClassroomsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$CourseOfferingsTableOrderingComposer get courseOffering {
    final $$CourseOfferingsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseOffering,
      referencedTable: $db.courseOfferings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseOfferingsTableOrderingComposer(
            $db: $db,
            $table: $db.courseOfferings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ClassroomsTableOrderingComposer get classroom {
    final $$ClassroomsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.classroom,
      referencedTable: $db.classrooms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClassroomsTableOrderingComposer(
            $db: $db,
            $table: $db.classrooms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CourseOfferingClassroomsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CourseOfferingClassroomsTable> {
  $$CourseOfferingClassroomsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$CourseOfferingsTableAnnotationComposer get courseOffering {
    final $$CourseOfferingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseOffering,
      referencedTable: $db.courseOfferings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseOfferingsTableAnnotationComposer(
            $db: $db,
            $table: $db.courseOfferings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ClassroomsTableAnnotationComposer get classroom {
    final $$ClassroomsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.classroom,
      referencedTable: $db.classrooms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClassroomsTableAnnotationComposer(
            $db: $db,
            $table: $db.classrooms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CourseOfferingClassroomsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CourseOfferingClassroomsTable,
          CourseOfferingClassroom,
          $$CourseOfferingClassroomsTableFilterComposer,
          $$CourseOfferingClassroomsTableOrderingComposer,
          $$CourseOfferingClassroomsTableAnnotationComposer,
          $$CourseOfferingClassroomsTableCreateCompanionBuilder,
          $$CourseOfferingClassroomsTableUpdateCompanionBuilder,
          (CourseOfferingClassroom, $$CourseOfferingClassroomsTableReferences),
          CourseOfferingClassroom,
          PrefetchHooks Function({bool courseOffering, bool classroom})
        > {
  $$CourseOfferingClassroomsTableTableManager(
    _$AppDatabase db,
    $CourseOfferingClassroomsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CourseOfferingClassroomsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CourseOfferingClassroomsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CourseOfferingClassroomsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> courseOffering = const Value.absent(),
                Value<int> classroom = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CourseOfferingClassroomsCompanion(
                courseOffering: courseOffering,
                classroom: classroom,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int courseOffering,
                required int classroom,
                Value<int> rowid = const Value.absent(),
              }) => CourseOfferingClassroomsCompanion.insert(
                courseOffering: courseOffering,
                classroom: classroom,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CourseOfferingClassroomsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({courseOffering = false, classroom = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (courseOffering) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.courseOffering,
                                referencedTable:
                                    $$CourseOfferingClassroomsTableReferences
                                        ._courseOfferingTable(db),
                                referencedColumn:
                                    $$CourseOfferingClassroomsTableReferences
                                        ._courseOfferingTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (classroom) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.classroom,
                                referencedTable:
                                    $$CourseOfferingClassroomsTableReferences
                                        ._classroomTable(db),
                                referencedColumn:
                                    $$CourseOfferingClassroomsTableReferences
                                        ._classroomTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CourseOfferingClassroomsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CourseOfferingClassroomsTable,
      CourseOfferingClassroom,
      $$CourseOfferingClassroomsTableFilterComposer,
      $$CourseOfferingClassroomsTableOrderingComposer,
      $$CourseOfferingClassroomsTableAnnotationComposer,
      $$CourseOfferingClassroomsTableCreateCompanionBuilder,
      $$CourseOfferingClassroomsTableUpdateCompanionBuilder,
      (CourseOfferingClassroom, $$CourseOfferingClassroomsTableReferences),
      CourseOfferingClassroom,
      PrefetchHooks Function({bool courseOffering, bool classroom})
    >;
typedef $$CourseOfferingStudentsTableCreateCompanionBuilder =
    CourseOfferingStudentsCompanion Function({
      required int courseOffering,
      required int student,
      Value<int> rowid,
    });
typedef $$CourseOfferingStudentsTableUpdateCompanionBuilder =
    CourseOfferingStudentsCompanion Function({
      Value<int> courseOffering,
      Value<int> student,
      Value<int> rowid,
    });

final class $$CourseOfferingStudentsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CourseOfferingStudentsTable,
          CourseOfferingStudent
        > {
  $$CourseOfferingStudentsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CourseOfferingsTable _courseOfferingTable(_$AppDatabase db) =>
      db.courseOfferings.createAlias(
        $_aliasNameGenerator(
          db.courseOfferingStudents.courseOffering,
          db.courseOfferings.id,
        ),
      );

  $$CourseOfferingsTableProcessedTableManager get courseOffering {
    final $_column = $_itemColumn<int>('course_offering')!;

    final manager = $$CourseOfferingsTableTableManager(
      $_db,
      $_db.courseOfferings,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_courseOfferingTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $StudentsTable _studentTable(_$AppDatabase db) =>
      db.students.createAlias(
        $_aliasNameGenerator(db.courseOfferingStudents.student, db.students.id),
      );

  $$StudentsTableProcessedTableManager get student {
    final $_column = $_itemColumn<int>('student')!;

    final manager = $$StudentsTableTableManager(
      $_db,
      $_db.students,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_studentTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CourseOfferingStudentsTableFilterComposer
    extends Composer<_$AppDatabase, $CourseOfferingStudentsTable> {
  $$CourseOfferingStudentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$CourseOfferingsTableFilterComposer get courseOffering {
    final $$CourseOfferingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseOffering,
      referencedTable: $db.courseOfferings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseOfferingsTableFilterComposer(
            $db: $db,
            $table: $db.courseOfferings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StudentsTableFilterComposer get student {
    final $$StudentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.student,
      referencedTable: $db.students,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableFilterComposer(
            $db: $db,
            $table: $db.students,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CourseOfferingStudentsTableOrderingComposer
    extends Composer<_$AppDatabase, $CourseOfferingStudentsTable> {
  $$CourseOfferingStudentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$CourseOfferingsTableOrderingComposer get courseOffering {
    final $$CourseOfferingsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseOffering,
      referencedTable: $db.courseOfferings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseOfferingsTableOrderingComposer(
            $db: $db,
            $table: $db.courseOfferings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StudentsTableOrderingComposer get student {
    final $$StudentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.student,
      referencedTable: $db.students,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableOrderingComposer(
            $db: $db,
            $table: $db.students,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CourseOfferingStudentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CourseOfferingStudentsTable> {
  $$CourseOfferingStudentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$CourseOfferingsTableAnnotationComposer get courseOffering {
    final $$CourseOfferingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseOffering,
      referencedTable: $db.courseOfferings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseOfferingsTableAnnotationComposer(
            $db: $db,
            $table: $db.courseOfferings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StudentsTableAnnotationComposer get student {
    final $$StudentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.student,
      referencedTable: $db.students,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableAnnotationComposer(
            $db: $db,
            $table: $db.students,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CourseOfferingStudentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CourseOfferingStudentsTable,
          CourseOfferingStudent,
          $$CourseOfferingStudentsTableFilterComposer,
          $$CourseOfferingStudentsTableOrderingComposer,
          $$CourseOfferingStudentsTableAnnotationComposer,
          $$CourseOfferingStudentsTableCreateCompanionBuilder,
          $$CourseOfferingStudentsTableUpdateCompanionBuilder,
          (CourseOfferingStudent, $$CourseOfferingStudentsTableReferences),
          CourseOfferingStudent,
          PrefetchHooks Function({bool courseOffering, bool student})
        > {
  $$CourseOfferingStudentsTableTableManager(
    _$AppDatabase db,
    $CourseOfferingStudentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CourseOfferingStudentsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CourseOfferingStudentsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CourseOfferingStudentsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> courseOffering = const Value.absent(),
                Value<int> student = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CourseOfferingStudentsCompanion(
                courseOffering: courseOffering,
                student: student,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int courseOffering,
                required int student,
                Value<int> rowid = const Value.absent(),
              }) => CourseOfferingStudentsCompanion.insert(
                courseOffering: courseOffering,
                student: student,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CourseOfferingStudentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({courseOffering = false, student = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (courseOffering) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.courseOffering,
                                referencedTable:
                                    $$CourseOfferingStudentsTableReferences
                                        ._courseOfferingTable(db),
                                referencedColumn:
                                    $$CourseOfferingStudentsTableReferences
                                        ._courseOfferingTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (student) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.student,
                                referencedTable:
                                    $$CourseOfferingStudentsTableReferences
                                        ._studentTable(db),
                                referencedColumn:
                                    $$CourseOfferingStudentsTableReferences
                                        ._studentTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CourseOfferingStudentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CourseOfferingStudentsTable,
      CourseOfferingStudent,
      $$CourseOfferingStudentsTableFilterComposer,
      $$CourseOfferingStudentsTableOrderingComposer,
      $$CourseOfferingStudentsTableAnnotationComposer,
      $$CourseOfferingStudentsTableCreateCompanionBuilder,
      $$CourseOfferingStudentsTableUpdateCompanionBuilder,
      (CourseOfferingStudent, $$CourseOfferingStudentsTableReferences),
      CourseOfferingStudent,
      PrefetchHooks Function({bool courseOffering, bool student})
    >;
typedef $$SchedulesTableCreateCompanionBuilder =
    SchedulesCompanion Function({
      Value<int> id,
      required int courseOffering,
      required DayOfWeek dayOfWeek,
      required Period period,
    });
typedef $$SchedulesTableUpdateCompanionBuilder =
    SchedulesCompanion Function({
      Value<int> id,
      Value<int> courseOffering,
      Value<DayOfWeek> dayOfWeek,
      Value<Period> period,
    });

final class $$SchedulesTableReferences
    extends BaseReferences<_$AppDatabase, $SchedulesTable, Schedule> {
  $$SchedulesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CourseOfferingsTable _courseOfferingTable(_$AppDatabase db) =>
      db.courseOfferings.createAlias(
        $_aliasNameGenerator(
          db.schedules.courseOffering,
          db.courseOfferings.id,
        ),
      );

  $$CourseOfferingsTableProcessedTableManager get courseOffering {
    final $_column = $_itemColumn<int>('course_offering')!;

    final manager = $$CourseOfferingsTableTableManager(
      $_db,
      $_db.courseOfferings,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_courseOfferingTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SchedulesTableFilterComposer
    extends Composer<_$AppDatabase, $SchedulesTable> {
  $$SchedulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DayOfWeek, DayOfWeek, int> get dayOfWeek =>
      $composableBuilder(
        column: $table.dayOfWeek,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Period, Period, int> get period =>
      $composableBuilder(
        column: $table.period,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$CourseOfferingsTableFilterComposer get courseOffering {
    final $$CourseOfferingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseOffering,
      referencedTable: $db.courseOfferings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseOfferingsTableFilterComposer(
            $db: $db,
            $table: $db.courseOfferings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SchedulesTableOrderingComposer
    extends Composer<_$AppDatabase, $SchedulesTable> {
  $$SchedulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayOfWeek => $composableBuilder(
    column: $table.dayOfWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get period => $composableBuilder(
    column: $table.period,
    builder: (column) => ColumnOrderings(column),
  );

  $$CourseOfferingsTableOrderingComposer get courseOffering {
    final $$CourseOfferingsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseOffering,
      referencedTable: $db.courseOfferings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseOfferingsTableOrderingComposer(
            $db: $db,
            $table: $db.courseOfferings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SchedulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SchedulesTable> {
  $$SchedulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DayOfWeek, int> get dayOfWeek =>
      $composableBuilder(column: $table.dayOfWeek, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Period, int> get period =>
      $composableBuilder(column: $table.period, builder: (column) => column);

  $$CourseOfferingsTableAnnotationComposer get courseOffering {
    final $$CourseOfferingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseOffering,
      referencedTable: $db.courseOfferings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseOfferingsTableAnnotationComposer(
            $db: $db,
            $table: $db.courseOfferings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SchedulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SchedulesTable,
          Schedule,
          $$SchedulesTableFilterComposer,
          $$SchedulesTableOrderingComposer,
          $$SchedulesTableAnnotationComposer,
          $$SchedulesTableCreateCompanionBuilder,
          $$SchedulesTableUpdateCompanionBuilder,
          (Schedule, $$SchedulesTableReferences),
          Schedule,
          PrefetchHooks Function({bool courseOffering})
        > {
  $$SchedulesTableTableManager(_$AppDatabase db, $SchedulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SchedulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SchedulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SchedulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> courseOffering = const Value.absent(),
                Value<DayOfWeek> dayOfWeek = const Value.absent(),
                Value<Period> period = const Value.absent(),
              }) => SchedulesCompanion(
                id: id,
                courseOffering: courseOffering,
                dayOfWeek: dayOfWeek,
                period: period,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int courseOffering,
                required DayOfWeek dayOfWeek,
                required Period period,
              }) => SchedulesCompanion.insert(
                id: id,
                courseOffering: courseOffering,
                dayOfWeek: dayOfWeek,
                period: period,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SchedulesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({courseOffering = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (courseOffering) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.courseOffering,
                                referencedTable: $$SchedulesTableReferences
                                    ._courseOfferingTable(db),
                                referencedColumn: $$SchedulesTableReferences
                                    ._courseOfferingTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SchedulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SchedulesTable,
      Schedule,
      $$SchedulesTableFilterComposer,
      $$SchedulesTableOrderingComposer,
      $$SchedulesTableAnnotationComposer,
      $$SchedulesTableCreateCompanionBuilder,
      $$SchedulesTableUpdateCompanionBuilder,
      (Schedule, $$SchedulesTableReferences),
      Schedule,
      PrefetchHooks Function({bool courseOffering})
    >;
typedef $$MaterialsTableCreateCompanionBuilder =
    MaterialsCompanion Function({
      Value<int> id,
      required int courseOffering,
      Value<String?> title,
      Value<String?> href,
    });
typedef $$MaterialsTableUpdateCompanionBuilder =
    MaterialsCompanion Function({
      Value<int> id,
      Value<int> courseOffering,
      Value<String?> title,
      Value<String?> href,
    });

final class $$MaterialsTableReferences
    extends BaseReferences<_$AppDatabase, $MaterialsTable, Material> {
  $$MaterialsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CourseOfferingsTable _courseOfferingTable(_$AppDatabase db) =>
      db.courseOfferings.createAlias(
        $_aliasNameGenerator(
          db.materials.courseOffering,
          db.courseOfferings.id,
        ),
      );

  $$CourseOfferingsTableProcessedTableManager get courseOffering {
    final $_column = $_itemColumn<int>('course_offering')!;

    final manager = $$CourseOfferingsTableTableManager(
      $_db,
      $_db.courseOfferings,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_courseOfferingTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MaterialsTableFilterComposer
    extends Composer<_$AppDatabase, $MaterialsTable> {
  $$MaterialsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get href => $composableBuilder(
    column: $table.href,
    builder: (column) => ColumnFilters(column),
  );

  $$CourseOfferingsTableFilterComposer get courseOffering {
    final $$CourseOfferingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseOffering,
      referencedTable: $db.courseOfferings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseOfferingsTableFilterComposer(
            $db: $db,
            $table: $db.courseOfferings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MaterialsTableOrderingComposer
    extends Composer<_$AppDatabase, $MaterialsTable> {
  $$MaterialsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get href => $composableBuilder(
    column: $table.href,
    builder: (column) => ColumnOrderings(column),
  );

  $$CourseOfferingsTableOrderingComposer get courseOffering {
    final $$CourseOfferingsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseOffering,
      referencedTable: $db.courseOfferings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseOfferingsTableOrderingComposer(
            $db: $db,
            $table: $db.courseOfferings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MaterialsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MaterialsTable> {
  $$MaterialsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get href =>
      $composableBuilder(column: $table.href, builder: (column) => column);

  $$CourseOfferingsTableAnnotationComposer get courseOffering {
    final $$CourseOfferingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseOffering,
      referencedTable: $db.courseOfferings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseOfferingsTableAnnotationComposer(
            $db: $db,
            $table: $db.courseOfferings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MaterialsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MaterialsTable,
          Material,
          $$MaterialsTableFilterComposer,
          $$MaterialsTableOrderingComposer,
          $$MaterialsTableAnnotationComposer,
          $$MaterialsTableCreateCompanionBuilder,
          $$MaterialsTableUpdateCompanionBuilder,
          (Material, $$MaterialsTableReferences),
          Material,
          PrefetchHooks Function({bool courseOffering})
        > {
  $$MaterialsTableTableManager(_$AppDatabase db, $MaterialsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MaterialsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MaterialsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MaterialsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> courseOffering = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> href = const Value.absent(),
              }) => MaterialsCompanion(
                id: id,
                courseOffering: courseOffering,
                title: title,
                href: href,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int courseOffering,
                Value<String?> title = const Value.absent(),
                Value<String?> href = const Value.absent(),
              }) => MaterialsCompanion.insert(
                id: id,
                courseOffering: courseOffering,
                title: title,
                href: href,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MaterialsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({courseOffering = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (courseOffering) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.courseOffering,
                                referencedTable: $$MaterialsTableReferences
                                    ._courseOfferingTable(db),
                                referencedColumn: $$MaterialsTableReferences
                                    ._courseOfferingTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MaterialsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MaterialsTable,
      Material,
      $$MaterialsTableFilterComposer,
      $$MaterialsTableOrderingComposer,
      $$MaterialsTableAnnotationComposer,
      $$MaterialsTableCreateCompanionBuilder,
      $$MaterialsTableUpdateCompanionBuilder,
      (Material, $$MaterialsTableReferences),
      Material,
      PrefetchHooks Function({bool courseOffering})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$StudentsTableTableManager get students =>
      $$StudentsTableTableManager(_db, _db.students);
  $$SemestersTableTableManager get semesters =>
      $$SemestersTableTableManager(_db, _db.semesters);
  $$CoursesTableTableManager get courses =>
      $$CoursesTableTableManager(_db, _db.courses);
  $$TeachersTableTableManager get teachers =>
      $$TeachersTableTableManager(_db, _db.teachers);
  $$ClassesTableTableManager get classes =>
      $$ClassesTableTableManager(_db, _db.classes);
  $$ClassroomsTableTableManager get classrooms =>
      $$ClassroomsTableTableManager(_db, _db.classrooms);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$CourseOfferingsTableTableManager get courseOfferings =>
      $$CourseOfferingsTableTableManager(_db, _db.courseOfferings);
  $$CourseOfferingTeachersTableTableManager get courseOfferingTeachers =>
      $$CourseOfferingTeachersTableTableManager(
        _db,
        _db.courseOfferingTeachers,
      );
  $$CourseOfferingClassesTableTableManager get courseOfferingClasses =>
      $$CourseOfferingClassesTableTableManager(_db, _db.courseOfferingClasses);
  $$CourseOfferingClassroomsTableTableManager get courseOfferingClassrooms =>
      $$CourseOfferingClassroomsTableTableManager(
        _db,
        _db.courseOfferingClassrooms,
      );
  $$CourseOfferingStudentsTableTableManager get courseOfferingStudents =>
      $$CourseOfferingStudentsTableTableManager(
        _db,
        _db.courseOfferingStudents,
      );
  $$SchedulesTableTableManager get schedules =>
      $$SchedulesTableTableManager(_db, _db.schedules);
  $$MaterialsTableTableManager get materials =>
      $$MaterialsTableTableManager(_db, _db.materials);
}
