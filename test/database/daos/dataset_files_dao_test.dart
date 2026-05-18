import 'package:drift/native.dart';
import 'package:exel_category/core/database/app_database.dart';
import 'package:exel_category/core/database/daos/dataset_files_dao.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late DatasetFilesDao dao;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    dao = DatasetFilesDao(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('should create dataset file metadata', () async {
    final id = await dao.createDatasetFile(
      datasetId: 1,
      storageMode: 'path',
      importedAt: DateTime.now(),
      originalPath: '/file.csv',
      fileSize: 100,
    );

    expect(id, greaterThan(0));
  });

  test('should retrieve dataset file metadata', () async {
    await dao.createDatasetFile(
      datasetId: 1,
      storageMode: 'path',
      importedAt: DateTime.now(),
      originalPath: '/file.csv',
    );

    final result = await dao.getByDatasetId(1);

    expect(result, isNotNull);
    expect(result!.storageMode, 'path');
  });

  test('should delete dataset file metadata', () async {
    await dao.createDatasetFile(
      datasetId: 1,
      storageMode: 'path',
      importedAt: DateTime.now(),
    );

    await dao.deleteByDatasetId(1);

    final result = await dao.getByDatasetId(1);

    expect(result, isNull);
  });
}
