import 'package:drift/native.dart';
import 'package:exel_category/application/dto/confirmed_import.dart';
import 'package:exel_category/application/dto/import_file.dart';
import 'package:exel_category/core/database/app_database.dart'
    hide DatasetColumn, DatasetTable;
import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/entities/parsed_sheet.dart';
import 'package:exel_category/domain/value_objects/column_type.dart';
import 'package:exel_category/domain/value_objects/dataset_file_storage_mode.dart';
import 'package:exel_category/presentation/providers/database_providers.dart';
import 'package:exel_category/presentation/providers/repository_providers.dart';
import 'package:exel_category/presentation/providers/service_providers.dart';
import 'package:exel_category/presentation/providers/usecase_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('app providers', () {
    late AppDatabase database;
    late ProviderContainer container;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await database.close();
    });

    test('should resolve import and dataset creation services', () {
      expect(container.read(importDataServiceProvider), isNotNull);
      expect(container.read(createDatasetServiceProvider), isNotNull);
      expect(container.read(saveUploadedFileUseCaseProvider), isNotNull);
      expect(container.read(openDatasetUseCaseProvider), isNotNull);
      expect(container.read(updateDatasetUiStateUseCaseProvider), isNotNull);
      expect(container.read(applyFiltersUseCaseProvider), isNotNull);
      expect(container.read(getDistinctValuesUseCaseProvider), isNotNull);
      expect(container.read(datasetsRepositoryProvider), isNotNull);
      expect(container.read(schemaRepositoryProvider), isNotNull);
      expect(container.read(queryRepositoryProvider), isNotNull);
    });

    test('should create a dataset through wired providers', () async {
      final saveUploadedFileUseCase = container.read(
        saveUploadedFileUseCaseProvider,
      );
      final createDatasetService = container.read(
        createDatasetServiceProvider,
      );
      final datasetsRepository = container.read(
        datasetsRepositoryProvider,
      );
      final datasetFileRepository = container.read(
        datasetFileRepositoryProvider,
      );

      final sourceFileReference = await saveUploadedFileUseCase(
        ImportFile.fromBytes(
          fileName: 'sales.csv',
          bytes: [1, 2, 3],
        ),
        importedAt: DateTime(2026, 1, 2),
      );

      final result = await createDatasetService.createDataset(
        confirmedImport: ConfirmedImport(
          datasetName: 'Sales',
          sourceFileName: 'sales.csv',
          sourceFileReference: sourceFileReference,
          sheets: [
            ConfirmedImportSheet(
              sheet: ParsedSheet(
                name: 'Sheet1',
                rows: [
                  {'product': 'book'},
                ],
              ),
              columns: [
                DatasetColumn(
                  id: 0,
                  datasetTableId: 0,
                  originalName: 'product',
                  dbName: 'product',
                  declaredType: ColumnType.text,
                  inferredType: ColumnType.text,
                  nullable: false,
                  statsJson: null,
                ),
              ],
            ),
          ],
        ),
      );

      final dataset = await datasetsRepository.getDatasetById(
        result.datasetId,
      );
      final datasetFile = await datasetFileRepository.getByDatasetId(
        result.datasetId,
      );

      expect(dataset?.name, 'Sales');
      expect(datasetFile?.storageMode, DatasetFileStorageMode.webTemporary);
      expect(result.tableCount, 1);
      expect(result.rowCount, 1);
    });
  });
}
