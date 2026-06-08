import 'package:drift/native.dart';
import 'package:exlser/core/database/app_database.dart' hide DatasetFile;
import 'package:exlser/core/database/daos/dataset_files_dao.dart';
import 'package:exlser/data/repositories/dataset_file_repository_impl.dart';
import 'package:exlser/domain/entities/dataset_file.dart';
import 'package:exlser/domain/value_objects/dataset_file_storage_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DatasetFileRepositoryImpl', () {
    late AppDatabase database;
    late DatasetFileRepositoryImpl repository;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      repository = DatasetFileRepositoryImpl(
        dao: DatasetFilesDao(database),
      );
    });

    tearDown(() async {
      await database.close();
    });

    test('should create and retrieve path dataset file metadata', () async {
      final importedAt = DateTime(2026, 1, 2);

      final created = await repository.createDatasetFile(
        DatasetFile(
          id: 0,
          datasetId: 1,
          storageMode: DatasetFileStorageMode.path,
          originalPath: '/tmp/data.csv',
          importedAt: importedAt,
          fileSize: 120,
        ),
      );

      final result = await repository.getByDatasetId(1);

      expect(created.id, greaterThan(0));
      expect(result, isNotNull);
      expect(result!.id, created.id);
      expect(result.datasetId, 1);
      expect(result.storageMode, DatasetFileStorageMode.path);
      expect(result.originalPath, '/tmp/data.csv');
      expect(result.storedPath, isNull);
      expect(result.importedAt, importedAt);
      expect(result.fileSize, 120);
    });

    test('should create and retrieve web temporary file metadata', () async {
      final importedAt = DateTime(2026, 1, 2);

      await repository.createDatasetFile(
        DatasetFile(
          id: 0,
          datasetId: 2,
          storageMode: DatasetFileStorageMode.webTemporary,
          importedAt: importedAt,
          fileSize: 300,
        ),
      );

      final result = await repository.getByDatasetId(2);

      expect(result, isNotNull);
      expect(result!.storageMode, DatasetFileStorageMode.webTemporary);
      expect(result.originalPath, isNull);
      expect(result.storedPath, isNull);
      expect(result.importedAt, importedAt);
      expect(result.fileSize, 300);
    });

    test('should return null when dataset file metadata does not exist',
        () async {
      final result = await repository.getByDatasetId(999);

      expect(result, isNull);
    });

    test('should delete dataset file metadata by dataset id', () async {
      await repository.createDatasetFile(
        DatasetFile(
          id: 0,
          datasetId: 3,
          storageMode: DatasetFileStorageMode.path,
          importedAt: DateTime(2026, 1, 2),
        ),
      );

      await repository.deleteByDatasetId(3);

      final result = await repository.getByDatasetId(3);

      expect(result, isNull);
    });
  });
}
