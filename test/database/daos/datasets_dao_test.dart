import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exel_category/core/database/app_database.dart';
import 'package:exel_category/core/database/daos/datasets_dao.dart';

void main() {
  late AppDatabase database;
  late DatasetsDao dao;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    dao = DatasetsDao(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('should create and retrieve a dataset', () async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final id = await dao.createDataset(
      name: 'Test Dataset',
      sourceFileName: 'test.xlsx',
      createdAt: now,
    );

    final result = await dao.getDatasetById(id);

    expect(result?.name, 'Test Dataset');
  });

  test('should update dataset ui state', () async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final id = await dao.createDataset(
      name: 'Dataset UI',
      sourceFileName: 'ui.xlsx',
      createdAt: now,
    );

    await dao.updateUiState(
      datasetId: id,
      uiStateJson: '{"filters":{"status":["open"]}}',
    );

    final result = await dao.getDatasetById(id);

    expect(result?.uiStateJson, '{"filters":{"status":["open"]}}');
  });

  test('should delete a dataset', () async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final id = await dao.createDataset(
      name: 'Dataset Delete',
      sourceFileName: 'delete.xlsx',
      createdAt: now,
    );

    await dao.deleteDatasetById(id);

    final result = await dao.getDatasetById(id);

    expect(result, isNull);
  });
}
