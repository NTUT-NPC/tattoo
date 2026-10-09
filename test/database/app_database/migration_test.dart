import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/database/database.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  test(
    'v1 material migration preserves login and cached course data',
    () async {
      final schema = await verifier.schemaAt(1);
      final oldDb = v1.DatabaseAtV1(schema.newConnection());
      await oldDb.customStatement(
        "INSERT INTO users (student_id, name_zh, avatar_filename, email) VALUES ('111000001', 'Student', '', 'student@example.com')",
      );
      await oldDb.customStatement(
        'INSERT INTO semesters (id, year, term) VALUES (1, 114, 1)',
      );
      await oldDb.customStatement(
        "INSERT INTO course_offerings (id, semester, number, name_zh, student_roster_fetched_at) VALUES (1, 1, '352902', 'Course', 1000)",
      );
      await oldDb.customStatement(
        "INSERT INTO materials (course_offering, title, href) VALUES (1, 'Notes', 'resource')",
      );
      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      addTearDown(oldDb.close);
      await verifier.migrateAndValidate(db, 2);
      expect((await db.select(db.users).getSingle()).studentId, '111000001');
      final offering = await db.select(db.courseOfferings).getSingle();
      expect(offering.studentRosterFetchedAt, isNotNull);
      expect(offering.materialsFetchedAt, isNull);
      final material = await db.select(db.materials).getSingle();
      expect(material.href, 'resource');
      expect(material.iSchoolCourseId, isNull);
      expect(material.streamable, isNull);
    },
  );
}
