import 'dart:io';

import 'package:drift/native.dart';
import 'package:exel_category/core/database/app_database.dart';
import 'package:exel_category/core/database/daos/datasets_dao.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppDatabase persistence', () {
    test('keeps dataset metadata after database reopen', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'exlser_database_test_',
      );
      final dbFile = File('${tempDir.path}/app.sqlite');

      var database = AppDatabase(NativeDatabase(dbFile));
      var datasetsDao = DatasetsDao(database);

      final datasetId = await datasetsDao.createDataset(
        name: 'Sales',
        sourceFileName: 'sales.csv',
        createdAt: DateTime(2026, 1, 1).millisecondsSinceEpoch,
        uiStateJson: '{"viewMode":"table"}',
      );

      await database.close();

      database = AppDatabase(NativeDatabase(dbFile));
      datasetsDao = DatasetsDao(database);

      final dataset = await datasetsDao.getDatasetById(datasetId);

      expect(dataset?.name, 'Sales');
      expect(dataset?.sourceFileName, 'sales.csv');
      expect(dataset?.uiStateJson, '{"viewMode":"table"}');

      await database.close();
      await tempDir.delete(recursive: true);
    });
  });
}
