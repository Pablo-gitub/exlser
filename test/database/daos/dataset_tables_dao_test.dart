import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exlser/core/database/app_database.dart';
import 'package:exlser/core/database/daos/dataset_tables_dao.dart';

void main() {
  late AppDatabase database;
  late DatasetTablesDao dao;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    dao = DatasetTablesDao(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('should create a dataset table', () async {
    final tableId = await dao.createDatasetTable(
      datasetId: 1,
      sheetNameOriginal: 'Sheet1',
      sqlTableName: 'ds_1_sheet_1',
      rowCount: 100,
      colCount: 5,
    );

    expect(tableId, greaterThan(0));
  });

  test('should retrieve tables for dataset', () async {
    await dao.createDatasetTable(
      datasetId: 1,
      sheetNameOriginal: 'Sheet1',
      sqlTableName: 'ds_1_sheet_1',
      rowCount: 100,
      colCount: 5,
    );

    final tables = await dao.getTablesForDataset(1);

    expect(tables.length, 1);
    expect(tables.first.sheetNameOriginal, 'Sheet1');
  });

  test('should delete tables for dataset', () async {
    await dao.createDatasetTable(
      datasetId: 1,
      sheetNameOriginal: 'Sheet1',
      sqlTableName: 'ds_1_sheet_1',
      rowCount: 100,
      colCount: 5,
    );

    await dao.deleteTablesForDataset(1);

    final tables = await dao.getTablesForDataset(1);

    expect(tables.isEmpty, true);
  });
}
