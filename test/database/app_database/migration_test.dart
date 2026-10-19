import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
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

  test(
    'v1 to v2 migration preserves cached data and adds map schema',
    () async {
      final schema = await verifier.schemaAt(1);
      final oldDb = v1.DatabaseAtV1(schema.newConnection());
      await oldDb.customStatement(
        "INSERT INTO users (student_id, name_zh, avatar_filename, email) "
        "VALUES ('111000001', 'Student', '', 'student@example.com')",
      );
      await oldDb.customStatement(
        'INSERT INTO semesters (id, year, term) VALUES (1, 114, 1)',
      );
      await oldDb.customStatement(
        "INSERT INTO course_offerings "
        "(id, semester, number, name_zh, student_roster_fetched_at) "
        "VALUES (1, 1, '352902', 'Course', 1000)",
      );
      await oldDb.customStatement(
        "INSERT INTO materials (course_offering, title, href) "
        "VALUES (1, 'Notes', 'resource')",
      );

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      addTearDown(oldDb.close);
      await verifier.migrateAndValidate(db, 2);

      expect((await db.select(db.users).getSingle()).studentId, '111000001');
      expect((await db.select(db.semesters).getSingle()).year, 114);
      final offering = await db.select(db.courseOfferings).getSingle();
      expect(offering.number, '352902');
      expect(offering.studentRosterFetchedAt, isNotNull);
      final material = await db.select(db.materials).getSingle();
      expect(material.href, 'resource');
      expect(material.title, 'Notes');

      await _expectMapSchema(db);
      await _expectCascadeDeleteAndSync(db);
    },
  );

  test(
    'v1 preview map schema keeps rows and tolerates existing indexes',
    () async {
      final schema = await verifier.schemaAt(2);
      schema.rawDatabase.execute('PRAGMA user_version = 1');
      schema.rawDatabase.execute(
        "INSERT INTO campus_map_buildings (code, name, geometry) "
        "VALUES ('PREVIEW', 'Preview Building', '[]')",
      );
      schema.rawDatabase.execute(
        "INSERT INTO campus_map_floors (layer_name, building, code) "
        "VALUES ('preview:1f', 'PREVIEW', '1F')",
      );
      schema.rawDatabase.execute(
        "INSERT INTO campus_map_rooms "
        "(id, layer_name, name_zh, name_en, number) "
        "VALUES ('preview:1f.1', 'preview:1f', '教室', 'Classroom', '101')",
      );
      schema.rawDatabase.execute(
        "INSERT INTO campus_map_syncs (namespace) VALUES ('preview')",
      );

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 2);

      expect(
        await db
            .customSelect('SELECT name FROM campus_map_buildings')
            .map((row) => row.read<String>('name'))
            .get(),
        ['Preview Building'],
      );
      expect(
        await db
            .customSelect('SELECT number FROM campus_map_rooms')
            .map((row) => row.read<String>('number'))
            .get(),
        ['101'],
      );
      expect(
        await db
            .customSelect('SELECT namespace FROM campus_map_syncs')
            .map((row) => row.read<String>('namespace'))
            .get(),
        ['preview'],
      );
      await _expectMapSchema(db);
    },
  );

  test('fresh v2 database validates and supports map rows', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await db.customSelect('SELECT 1').getSingle();
    await db.validateDatabaseSchema();
    await _expectMapSchema(db);
    await _expectCascadeDeleteAndSync(db);
  });
}

Future<void> _expectMapSchema(AppDatabase db) async {
  final indexes = await db
      .customSelect(
        "SELECT name FROM sqlite_master "
        "WHERE type = 'index' "
        "AND name IN ('campus_map_floor_building', 'campus_map_room_layer')",
      )
      .get();
  expect(
    indexes.map((row) => row.read<String>('name')).toSet(),
    {'campus_map_floor_building', 'campus_map_room_layer'},
  );

  final floorForeignKeys = await db
      .customSelect(
        "PRAGMA foreign_key_list('campus_map_floors')",
      )
      .get();
  expect(
    floorForeignKeys.any(
      (row) =>
          row.read<String>('table') == 'campus_map_buildings' &&
          row.read<String>('on_delete').toUpperCase() == 'CASCADE',
    ),
    isTrue,
  );
  final roomForeignKeys = await db
      .customSelect(
        "PRAGMA foreign_key_list('campus_map_rooms')",
      )
      .get();
  expect(
    roomForeignKeys.any(
      (row) =>
          row.read<String>('table') == 'campus_map_floors' &&
          row.read<String>('on_delete').toUpperCase() == 'CASCADE',
    ),
    isTrue,
  );
}

Future<void> _expectCascadeDeleteAndSync(AppDatabase db) async {
  await db.customStatement(
    "INSERT INTO campus_map_buildings (code, name, geometry) "
    "VALUES ('A', 'Building A', '[]')",
  );
  await db.customStatement(
    "INSERT INTO campus_map_floors (layer_name, building, code) "
    "VALUES ('ntut:building_a_1f', 'A', '1F')",
  );
  await db.customStatement(
    "INSERT INTO campus_map_rooms (id, layer_name, name_zh, name_en, number) "
    "VALUES ('ntut:building_a_1f.1', 'ntut:building_a_1f', '教室', 'Classroom', '101')",
  );
  await db.customStatement(
    "INSERT INTO campus_map_syncs (namespace) VALUES ('migration-test')",
  );
  await db.customStatement("DELETE FROM campus_map_buildings WHERE code = 'A'");

  expect(
    await db
        .customSelect('SELECT COUNT(*) AS count FROM campus_map_floors')
        .map((row) => row.read<int>('count'))
        .getSingle(),
    0,
  );
  expect(
    await db
        .customSelect('SELECT COUNT(*) AS count FROM campus_map_rooms')
        .map((row) => row.read<int>('count'))
        .getSingle(),
    0,
  );
  expect(
    await db
        .customSelect(
          "SELECT namespace FROM campus_map_syncs "
          "WHERE namespace = 'migration-test'",
        )
        .map((row) => row.read<String>('namespace'))
        .getSingle(),
    'migration-test',
  );
}
