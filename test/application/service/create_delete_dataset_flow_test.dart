import 'package:drift/native.dart';
import 'package:exel_category/application/services/create_dataset_service.dart';
import 'package:exel_category/core/database/app_database.dart'
    hide DatasetColumn, DatasetTable;
import 'package:exel_category/core/database/daos/dataset_files_dao.dart';
import 'package:exel_category/core/database/daos/datasets_dao.dart';
import 'package:exel_category/data/adapters/normalizers/boolean_normalizer.dart';
import 'package:exel_category/data/adapters/normalizers/date_normalizer.dart';
import 'package:exel_category/data/adapters/normalizers/number_normalizer.dart';
import 'package:exel_category/data/datasources/drift_datasource.dart';
import 'package:exel_category/data/repositories/dataset_file_repository_impl.dart';
import 'package:exel_category/data/repositories/dataset_repository_impl.dart';
import 'package:exel_category/data/repositories/query_repository_impl.dart';
import 'package:exel_category/data/repositories/schema_repository_impl.dart';
import 'package:exel_category/data/schema/dynamic_table_builder.dart';
import 'package:exel_category/domain/entities/parsed_sheet.dart';
import 'package:exel_category/domain/entities/source_file_reference.dart';
import 'package:exel_category/domain/usecases/dataset/create_dataset_usecase.dart';
import 'package:exel_category/domain/usecases/dataset/delete_dataset_usecase.dart';
import 'package:exel_category/domain/usecases/dataset/register_dataset_file_usecase.dart';
import 'package:exel_category/domain/usecases/schema/build_dynamic_table_usecase.dart';
import 'package:exel_category/domain/usecases/schema/create_dataset_table_usecase.dart';
import 'package:exel_category/domain/usecases/schema/infer_schema_usecase.dart';
import 'package:exel_category/domain/usecases/schema/insert_rows_usecase.dart';
import 'package:exel_category/domain/usecases/schema/register_columns_usecase.dart';
import 'package:exel_category/domain/value_objects/dataset_file_storage_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('create/delete dataset flow', () {
    late AppDatabase database;
    late DatasetsRepositoryImpl datasetsRepository;
    late SchemaRepositoryImpl schemaRepository;
    late DatasetFileRepositoryImpl datasetFileRepository;
    late QueryRepositoryImpl queryRepository;
    late CreateDatasetService createDatasetService;
    late DeleteDatasetUseCase deleteDatasetUseCase;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());

      final datasource = DriftDatasource(database);
      datasetsRepository = DatasetsRepositoryImpl(
        dao: DatasetsDao(database),
      );
      schemaRepository = SchemaRepositoryImpl(
        datasource,
        DynamicTableBuilder(),
      );
      datasetFileRepository = DatasetFileRepositoryImpl(
        dao: DatasetFilesDao(database),
      );
      queryRepository = QueryRepositoryImpl(datasource);

      createDatasetService = CreateDatasetService(
        createDatasetUseCase: CreateDatasetUseCase(
          repository: datasetsRepository,
        ),
        registerDatasetFileUseCase: RegisterDatasetFileUseCase(
          repository: datasetFileRepository,
        ),
        createDatasetTableUseCase: CreateDatasetTableUseCase(
          repository: schemaRepository,
        ),
        registerColumnsUseCase: RegisterColumnsUseCase(
          repository: schemaRepository,
        ),
        buildDynamicTableUseCase: BuildDynamicTableUseCase(
          repository: schemaRepository,
        ),
        insertRowsUseCase: InsertRowsUseCase(queryRepository),
        inferSchemaUseCase: InferSchemaUseCase(
          numberNormalizer: NumberNormalizer(),
          dateNormalizer: DateNormalizer(),
          booleanNormalizer: BooleanNormalizer(),
        ),
      );

      deleteDatasetUseCase = DeleteDatasetUseCase(
        datasetsRepository: datasetsRepository,
        schemaRepository: schemaRepository,
        datasetFileRepository: datasetFileRepository,
      );
    });

    tearDown(() async {
      await database.close();
    });

    test('persists and deletes dataset, schema, rows and file reference',
        () async {
      final sourceFileReference = SourceFileReference(
        fileName: 'sales.xlsx',
        storageMode: DatasetFileStorageMode.path,
        originalPath: '/tmp/sales.xlsx',
        importedAt: DateTime(2026, 1, 2),
        fileSize: 128,
      );

      await createDatasetService.createDataset(
        datasetName: 'Sales',
        sourceFileName: 'sales.xlsx',
        sourceFileReference: sourceFileReference,
        sheets: [
          ParsedSheet(
            name: 'Sheet 1',
            rows: [
              {'product': 'book', 'price': '10'},
              {'product': 'pen', 'price': '2'},
            ],
          ),
        ],
      );

      final dataset = (await datasetsRepository.getAllDatasets()).single;
      final fileReference = await datasetFileRepository.getByDatasetId(
        dataset.id,
      );
      final tables = await schemaRepository.getTablesForDataset(dataset.id);
      final columns = await schemaRepository.getColumnsForTable(
        tables.single.id,
      );
      final rowCount = await queryRepository.countRows(
        tables.single.sqlTableName,
      );

      expect(fileReference?.originalPath, '/tmp/sales.xlsx');
      expect(tables.single.sqlTableName, startsWith('ds_${dataset.id}_'));
      expect(columns.map((column) => column.dbName), ['product', 'price']);
      expect(rowCount, 2);

      await deleteDatasetUseCase(dataset.id);

      expect(await datasetsRepository.getDatasetById(dataset.id), isNull);
      expect(await datasetFileRepository.getByDatasetId(dataset.id), isNull);
      expect(await schemaRepository.getTablesForDataset(dataset.id), isEmpty);
      expect(
        () => queryRepository.countRows(tables.single.sqlTableName),
        throwsA(anything),
      );
    });
  });
}
