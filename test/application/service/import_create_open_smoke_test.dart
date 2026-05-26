import 'dart:convert';

import 'package:drift/native.dart';
import 'package:exlser/application/dto/confirmed_import.dart';
import 'package:exlser/application/dto/import_file.dart';
import 'package:exlser/application/services/create_dataset_service.dart';
import 'package:exlser/application/services/import_data_service.dart';
import 'package:exlser/core/database/app_database.dart'
    hide DatasetColumn, DatasetTable;
import 'package:exlser/core/database/daos/dataset_files_dao.dart';
import 'package:exlser/core/database/daos/datasets_dao.dart';
import 'package:exlser/data/adapters/normalizers/boolean_normalizer.dart';
import 'package:exlser/data/adapters/normalizers/date_normalizer.dart';
import 'package:exlser/data/adapters/normalizers/number_normalizer.dart';
import 'package:exlser/data/adapters/parsers/parser_factory.dart';
import 'package:exlser/data/datasources/drift_datasource.dart';
import 'package:exlser/data/repositories/dataset_file_repository_impl.dart';
import 'package:exlser/data/services/drift_transaction_runner.dart';
import 'package:exlser/data/repositories/dataset_repository_impl.dart';
import 'package:exlser/data/repositories/query_repository_impl.dart';
import 'package:exlser/data/repositories/schema_repository_impl.dart';
import 'package:exlser/data/schema/dynamic_table_builder.dart';
import 'package:exlser/domain/usecases/dataset/create_dataset_usecase.dart';
import 'package:exlser/domain/usecases/dataset/open_dataset_usecase.dart';
import 'package:exlser/domain/usecases/dataset/register_dataset_file_usecase.dart';
import 'package:exlser/domain/usecases/query/fetch_rows_usecase.dart';
import 'package:exlser/domain/usecases/schema/build_dynamic_table_usecase.dart';
import 'package:exlser/domain/usecases/schema/create_dataset_table_usecase.dart';
import 'package:exlser/domain/usecases/schema/infer_schema_usecase.dart';
import 'package:exlser/domain/usecases/schema/insert_rows_usecase.dart';
import 'package:exlser/domain/usecases/schema/register_columns_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('import/create/open smoke flow', () {
    late AppDatabase database;
    late DatasetsRepositoryImpl datasetsRepository;
    late SchemaRepositoryImpl schemaRepository;
    late QueryRepositoryImpl queryRepository;
    late ImportDataService importDataService;
    late CreateDatasetService createDatasetService;
    late OpenDatasetUseCase openDatasetUseCase;
    late FetchRowsUseCase fetchRowsUseCase;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());

      final datasource = DriftDatasource(database);
      final dynamicTableBuilder = DynamicTableBuilder();
      datasetsRepository = DatasetsRepositoryImpl(
        dao: DatasetsDao(database),
      );
      schemaRepository = SchemaRepositoryImpl(
        datasource,
        dynamicTableBuilder,
      );
      final datasetFileRepository = DatasetFileRepositoryImpl(
        dao: DatasetFilesDao(database),
      );
      queryRepository = QueryRepositoryImpl(datasource);

      importDataService = ImportDataService(
        parserFactory: ParserFactory(),
        inferSchemaUseCase: InferSchemaUseCase(
          numberNormalizer: NumberNormalizer(),
          dateNormalizer: DateNormalizer(),
          booleanNormalizer: BooleanNormalizer(),
        ),
      );
      createDatasetService = CreateDatasetService(
        transactionRunner: DriftTransactionRunner(datasource),
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
      );
      openDatasetUseCase = OpenDatasetUseCase(
        repository: datasetsRepository,
      );
      fetchRowsUseCase = FetchRowsUseCase(
        repository: queryRepository,
      );
    });

    tearDown(() async {
      await database.close();
    });

    test('prepares, creates, opens and reads an imported dataset', () async {
      final file = ImportFile.fromBytes(
        fileName: 'sales.csv',
        bytes: utf8.encode(
          'product,price\n'
          'book,10\n'
          'pen,2\n',
        ),
      );

      final preparedImport = await importDataService.prepareImport(file: file);
      final createdDataset = await createDatasetService.createDataset(
        confirmedImport: ConfirmedImport.fromPreparedResult(
          datasetName: 'Sales',
          preparedImport: preparedImport,
        ),
      );
      final openedDataset = await openDatasetUseCase(createdDataset.datasetId);
      final tables = await schemaRepository.getTablesForDataset(
        openedDataset.id,
      );
      final columns = await schemaRepository.getColumnsForTable(
        tables.single.id,
      );
      final rows = await fetchRowsUseCase(
        tableName: tables.single.sqlTableName,
        limit: 10,
        offset: 0,
      );

      expect(preparedImport.sheetCount, 1);
      expect(createdDataset.datasetName, 'Sales');
      expect(createdDataset.rowCount, 2);
      expect(openedDataset.name, 'Sales');
      expect(openedDataset.lastOpenedAt, isNotNull);
      expect(tables.single.rowCount, 2);
      expect(columns.map((column) => column.dbName), ['product', 'price']);
      expect(rows, [
        {'id': 1, 'product': 'book', 'price': 10},
        {'id': 2, 'product': 'pen', 'price': 2},
      ]);
    });
  });
}
