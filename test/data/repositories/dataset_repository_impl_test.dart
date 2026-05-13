import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exel_category/core/database/app_database.dart';
import 'package:exel_category/core/database/daos/datasets_dao.dart';
import 'package:exel_category/data/repositories/dataset_repository_impl.dart';
import 'package:exel_category/domain/entities/dataset.dart' as domain;

void main() {
  late AppDatabase database;
  late DatasetsRepositoryImpl repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = DatasetsRepositoryImpl(
      dao: DatasetsDao(database),
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('DatasetsRepositoryImpl', () {
    test('creates a dataset and returns the generated id', () async {
      final created = await repository.createDataset(
        const domain.Dataset(
          id: 0,
          name: '  Sales 2026  ',
          sourceFileName: '  sales.xlsx  ',
          sourceFileHash: 'abc123',
          createdAt: 1000,
        ),
      );

      expect(created.id, greaterThan(0));
      expect(created.name, 'Sales 2026');
      expect(created.sourceFileName, 'sales.xlsx');
      expect(created.sourceFileHash, 'abc123');

      final persisted = await repository.getDatasetById(created.id);

      expect(persisted?.name, 'Sales 2026');
      expect(persisted?.sourceFileName, 'sales.xlsx');
      expect(persisted?.sourceFileHash, 'abc123');
    });

    test('returns all datasets ordered by creation date descending', () async {
      await repository.createDataset(
        const domain.Dataset(
          id: 0,
          name: 'Older',
          sourceFileName: 'older.xlsx',
          createdAt: 1000,
        ),
      );
      await repository.createDataset(
        const domain.Dataset(
          id: 0,
          name: 'Newer',
          sourceFileName: 'newer.xlsx',
          createdAt: 2000,
        ),
      );

      final datasets = await repository.getAllDatasets();

      expect(datasets.map((dataset) => dataset.name), ['Newer', 'Older']);
    });

    test('returns null when a dataset does not exist', () async {
      final dataset = await repository.getDatasetById(999);

      expect(dataset, isNull);
    });

    test('updates dataset metadata', () async {
      final created = await repository.createDataset(
        const domain.Dataset(
          id: 0,
          name: 'Original',
          sourceFileName: 'original.xlsx',
          createdAt: 1000,
        ),
      );

      await repository.updateDataset(
        created.copyWith(
          name: 'Updated',
          sourceFileName: 'updated.xlsx',
          sourceFileHash: 'hash-2',
          createdAt: 2000,
          lastOpenedAt: 3000,
        ),
      );

      final updated = await repository.getDatasetById(created.id);

      expect(updated?.name, 'Updated');
      expect(updated?.sourceFileName, 'updated.xlsx');
      expect(updated?.sourceFileHash, 'hash-2');
      expect(updated?.createdAt, 2000);
      expect(updated?.lastOpenedAt, 3000);
    });

    test('deletes a dataset', () async {
      final created = await repository.createDataset(
        const domain.Dataset(
          id: 0,
          name: 'To delete',
          sourceFileName: 'delete.xlsx',
          createdAt: 1000,
        ),
      );

      await repository.deleteDataset(created.id);

      final deleted = await repository.getDatasetById(created.id);

      expect(deleted, isNull);
    });

    test('marks a dataset as opened', () async {
      final created = await repository.createDataset(
        const domain.Dataset(
          id: 0,
          name: 'To open',
          sourceFileName: 'open.xlsx',
          createdAt: 1000,
        ),
      );
      final before = DateTime.now().millisecondsSinceEpoch;

      await repository.markDatasetOpened(created.id);

      final opened = await repository.getDatasetById(created.id);

      expect(opened?.lastOpenedAt, isNotNull);
      expect(opened!.lastOpenedAt, greaterThanOrEqualTo(before));
    });

    test('throws when ids are invalid', () {
      expect(
        () => repository.getDatasetById(0),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => repository.deleteDataset(-1),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => repository.markDatasetOpened(0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws when required text fields are blank', () {
      expect(
        () => repository.createDataset(
          const domain.Dataset(
            id: 0,
            name: '   ',
            sourceFileName: 'file.xlsx',
            createdAt: 1000,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => repository.createDataset(
          const domain.Dataset(
            id: 0,
            name: 'Dataset',
            sourceFileName: '   ',
            createdAt: 1000,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws when updating a missing dataset', () {
      expect(
        () => repository.updateDataset(
          const domain.Dataset(
            id: 999,
            name: 'Missing',
            sourceFileName: 'missing.xlsx',
            createdAt: 1000,
          ),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
