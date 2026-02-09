import 'package:drift/drift.dart';
import 'package:tattoo/database/schema.dart';

/// User profile view joining [Users] and [Students].
abstract class UserProfiles extends View {
  Users get users;
  Students get students;

  @override
  Query as() =>
      select([
        users.id,
        users.avatarFilename,
        users.email,
        users.passwordExpiresInDays,
        students.studentId,
        students.name,
      ]).from(users).join([
        innerJoin(students, students.id.equalsExp(users.student)),
      ]);
}
