import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exel_category/core/database/app_database.dart';
import 'package:exel_category/core/database/daos/dataset_columns_dao.dart';

void main() {
  late AppDatabase database;
  late DatasetColumnsDao dao;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    dao = DatasetColumnsDao(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('should create a column metadata entry', () async {
    final columnId = await dao.createColumn(
      datasetTableId: 1,
      originalName: 'Price',
      dbName: 'price',
      declaredType: 'REAL',
      inferredType: 'REAL',
      nullable: false,
    );

    expect(columnId, greaterThan(0));
  });

  test('should retrieve columns for table', () async {
    await dao.createColumn(
      datasetTableId: 1,
      originalName: 'Price',
      dbName: 'price',
      declaredType: 'REAL',
      inferredType: 'REAL',
      nullable: false,
    );

    final columns = await dao.getColumnsForTable(1);

    expect(columns.length, 1);
    expect(columns.first.originalName, 'Price');
  });

  test('should delete columns for table', () async {
    await dao.createColumn(
      datasetTableId: 1,
      originalName: 'Price',
      dbName: 'price',
      declaredType: 'REAL',
      inferredType: 'REAL',
      nullable: false,
    );

    await dao.deleteColumnsForTable(1);

    final columns = await dao.getColumnsForTable(1);

    expect(columns.isEmpty, true);
  });
}
