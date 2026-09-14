// Real migration tests: build an old on-disk schema, reopen it as AppDatabase so
// the declared onUpgrade actually runs, and check the new tables appear, existing
// data survives, and CRUD works afterwards.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:exlser/core/database/app_database.dart'
    hide DatasetColumn, DatasetTable, DatasetRelationship, SavedMultiSheetQuery;
import 'package:exlser/core/database/daos/dataset_relationships_dao.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

const _datasetsDdl = '''
CREATE TABLE datasets (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  source_file_name TEXT NOT NULL,
  source_file_hash TEXT,
  created_at INTEGER NOT NULL,
  last_opened_at INTEGER,
  ui_state_json TEXT
);
''';

const _datasetTablesDdl = '''
CREATE TABLE dataset_tables (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  dataset_id INTEGER NOT NULL,
  sheet_name_original TEXT NOT NULL,
  sql_table_name TEXT NOT NULL,
  row_count INTEGER NOT NULL,
  col_count INTEGER NOT NULL
);
''';

const _savedQueriesDdl = '''
CREATE TABLE saved_multi_sheet_queries (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  dataset_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  base_table_id INTEGER,
  specification_json TEXT NOT NULL,
  schema_version INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
''';

const _datasetRelationshipsDdl = '''
CREATE TABLE dataset_relationships (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  dataset_id INTEGER NOT NULL,
  endpoint_a_table_id INTEGER NOT NULL,
  endpoint_a_column_db_name TEXT NOT NULL,
  endpoint_b_table_id INTEGER NOT NULL,
  endpoint_b_column_db_name TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
''';

void main() {
  late File file;

  setUp(() {
    file = File(
      '${Directory.systemTemp.path}/exlser_mig_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    if (file.existsSync()) file.deleteSync();
  });

  tearDown(() {
    if (file.existsSync()) file.deleteSync();
  });

  /// Creates a v1 database (original tables only) with one dataset and one table.
  void seedV1() {
    final raw = sqlite.sqlite3.open(file.path);
    raw.execute(_datasetsDdl);
    raw.execute(_datasetTablesDdl);
    raw.execute(
      "INSERT INTO datasets (id, name, source_file_name, created_at) "
      "VALUES (1, 'keep-me', 'f.xlsx', 111);",
    );
    raw.execute(
      "INSERT INTO dataset_tables (id, dataset_id, sheet_name_original, sql_table_name, row_count, col_count) "
      "VALUES (10, 1, 'Sheet1', 'ds_1_sheet_1', 5, 3);",
    );
    raw.execute('PRAGMA user_version = 1;');
    raw.close();
  }

  /// Creates a v2 database (adds saved queries) with a dataset, table, and saved query.
  void seedV2() {
    final raw = sqlite.sqlite3.open(file.path);
    raw.execute(_datasetsDdl);
    raw.execute(_datasetTablesDdl);
    raw.execute(_savedQueriesDdl);
    raw.execute(
      "INSERT INTO datasets (id, name, source_file_name, created_at) "
      "VALUES (7, 'keep-me', 'f.xlsx', 111);",
    );
    raw.execute(
      "INSERT INTO dataset_tables (id, dataset_id, sheet_name_original, sql_table_name, row_count, col_count) "
      "VALUES (10, 7, 'Sheet1', 'ds_7_sheet_1', 5, 3);",
    );
    raw.execute(
      "INSERT INTO saved_multi_sheet_queries "
      "(dataset_id, name, specification_json, created_at, updated_at) "
      "VALUES (7, 'my join', '{}', 1, 1);",
    );
    raw.execute('PRAGMA user_version = 2;');
    raw.close();
  }

  /// Creates a v3 database (adds relationships) with dataset, table, saved query, and relationship.
  void seedV3() {
    final raw = sqlite.sqlite3.open(file.path);
    raw.execute(_datasetsDdl);
    raw.execute(_datasetTablesDdl);
    raw.execute(_savedQueriesDdl);
    raw.execute(_datasetRelationshipsDdl);
    raw.execute(
      "INSERT INTO datasets (id, name, source_file_name, created_at) "
      "VALUES (9, 'keep-me', 'f.xlsx', 111);",
    );
    raw.execute(
      "INSERT INTO dataset_tables (id, dataset_id, sheet_name_original, sql_table_name, row_count, col_count) "
      "VALUES (20, 9, 'Orders', 'ds_9_sheet_1', 10, 4);",
    );
    raw.execute(
      "INSERT INTO saved_multi_sheet_queries "
      "(dataset_id, name, specification_json, created_at, updated_at) "
      "VALUES (9, 'my join', '{}', 1, 1);",
    );
    raw.execute(
      "INSERT INTO dataset_relationships "
      "(dataset_id, endpoint_a_table_id, endpoint_a_column_db_name, endpoint_b_table_id, endpoint_b_column_db_name, created_at, updated_at) "
      "VALUES (9, 20, 'id', 21, 'order_id', 1, 1);",
    );
    raw.execute('PRAGMA user_version = 3;');
    raw.close();
  }

  Future<int> tableCount(AppDatabase db, String table) async {
    final row =
        await db.customSelect('SELECT COUNT(*) AS c FROM $table').getSingle();
    return row.read<int>('c');
  }

  Future<void> assertUpgradedAndUsable(AppDatabase db) async {
    // Existing dataset preserved.
    final datasets = await db.customSelect('SELECT name FROM datasets').get();
    expect(datasets.map((r) => r.read<String>('name')), contains('keep-me'));

    // Both new tables exist and are empty/usable.
    expect(await tableCount(db, 'dataset_relationships'), isNonNegative);
    expect(await tableCount(db, 'saved_multi_sheet_queries'), isNonNegative);

    // Existing table in dataset_tables has null source_sheet_name.
    final tables = await db
        .customSelect(
            'SELECT sheet_name_original, source_sheet_name FROM dataset_tables')
        .get();
    expect(tables, isNotEmpty);
    expect(tables.first.read<String?>('source_sheet_name'), isNull);

    // Can insert with source_sheet_name into dataset_tables.
    await db.customStatement(
      "INSERT INTO dataset_tables (dataset_id, sheet_name_original, sql_table_name, row_count, col_count, source_sheet_name) "
      "VALUES (1, 'NewTable', 'ds_1_new', 1, 1, 'MySheet');",
    );
    final newRow = await db
        .customSelect(
            "SELECT source_sheet_name FROM dataset_tables WHERE sheet_name_original = 'NewTable'")
        .getSingle();
    expect(newRow.read<String?>('source_sheet_name'), 'MySheet');

    // CRUD works on the freshly migrated relationships table.
    final dao = DatasetRelationshipsDao(db);
    final datasetId =
        (await db.customSelect('SELECT id FROM datasets LIMIT 1').getSingle())
            .read<int>('id');
    await dao.createRelationship(
      DatasetRelationshipsCompanion.insert(
        datasetId: datasetId,
        endpointATableId: 1,
        endpointAColumnDbName: 'a',
        endpointBTableId: 2,
        endpointBColumnDbName: 'b',
        createdAt: 1,
        updatedAt: 1,
      ),
    );
    expect(await tableCount(db, 'dataset_relationships'), greaterThan(0));
  }

  test(
      'v1 -> v4 creates all new tables and adds source_sheet_name column in a single upgrade',
      () async {
    seedV1();

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);

    await assertUpgradedAndUsable(db);
    // v2 table also created on the way from v1.
    expect(await tableCount(db, 'saved_multi_sheet_queries'), 0);
  });

  test(
      'v2 -> v4 adds relationships, adds source_sheet_name, and keeps saved queries',
      () async {
    seedV2();

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);

    await assertUpgradedAndUsable(db);
    // The pre-existing saved query survived the v2 -> v4 step.
    final saved = await db
        .customSelect('SELECT name FROM saved_multi_sheet_queries')
        .get();
    expect(saved.map((r) => r.read<String>('name')), contains('my join'));
  });

  test('v3 -> v4 adds source_sheet_name column and preserves relationships',
      () async {
    seedV3();

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);

    await assertUpgradedAndUsable(db);
    // Pre-existing relationship survived the v3 -> v4 step.
    expect(await tableCount(db, 'dataset_relationships'),
        2); // 1 seeded + 1 created in assert
  });
}
