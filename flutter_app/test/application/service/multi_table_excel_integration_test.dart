import 'package:drift/native.dart';
import 'package:exlser/application/dto/confirmed_import.dart';
import 'package:exlser/application/dto/import_file.dart';
import 'package:exlser/application/services/create_dataset_service.dart';
import 'package:exlser/application/services/import_data_service.dart';
import 'package:exlser/application/services/multi_sheet_analysis_service.dart';
import 'package:exlser/core/database/app_database.dart'
    hide DatasetColumn, DatasetTable, DatasetRelationship, SavedMultiSheetQuery;
import 'package:exlser/core/database/daos/dataset_files_dao.dart';
import 'package:exlser/core/database/daos/dataset_relationships_dao.dart';
import 'package:exlser/core/database/daos/datasets_dao.dart';
import 'package:exlser/core/database/daos/saved_multi_sheet_queries_dao.dart';
import 'package:exlser/core/normalizers/boolean_normalizer.dart';
import 'package:exlser/core/normalizers/date_normalizer.dart';
import 'package:exlser/core/normalizers/number_normalizer.dart';
import 'package:exlser/data/adapters/parsers/parser_factory.dart';
import 'package:exlser/data/datasources/drift_datasource.dart';
import 'package:exlser/data/repositories/dataset_file_repository_impl.dart';
import 'package:exlser/data/repositories/dataset_relationship_repository_impl.dart';
import 'package:exlser/data/repositories/dataset_repository_impl.dart';
import 'package:exlser/data/repositories/query_repository_impl.dart';
import 'package:exlser/data/repositories/saved_multi_sheet_query_repository_impl.dart';
import 'package:exlser/data/repositories/schema_repository_impl.dart';
import 'package:exlser/data/schema/dynamic_table_builder.dart';
import 'package:exlser/data/services/drift_transaction_runner.dart';
import 'package:exlser/domain/entities/dataset_relationship.dart';
import 'package:exlser/domain/usecases/dataset/create_dataset_usecase.dart';
import 'package:exlser/domain/usecases/dataset/open_dataset_usecase.dart';
import 'package:exlser/domain/usecases/dataset/register_dataset_file_usecase.dart';
import 'package:exlser/domain/usecases/dataset/update_dataset_ui_state_usecase.dart';
import 'package:exlser/domain/usecases/multisheet/execute_multi_sheet_preview_usecase.dart';
import 'package:exlser/domain/usecases/multisheet/manage_dataset_relationships_usecases.dart';
import 'package:exlser/domain/usecases/multisheet/manage_multi_sheet_queries_usecases.dart';
import 'package:exlser/domain/usecases/multisheet/save_multi_sheet_query_usecase.dart';
import 'package:exlser/domain/usecases/query/fetch_rows_usecase.dart';
import 'package:exlser/domain/usecases/schema/build_dynamic_table_usecase.dart';
import 'package:exlser/domain/usecases/schema/create_dataset_table_usecase.dart';
import 'package:exlser/domain/usecases/schema/infer_schema_usecase.dart';
import 'package:exlser/domain/usecases/schema/insert_rows_usecase.dart';
import 'package:exlser/domain/usecases/schema/register_columns_usecase.dart';
import 'package:exlser/domain/value_objects/multi_sheet_join.dart';
import 'package:exlser/domain/value_objects/multi_sheet_query_spec.dart';
import 'package:exlser/domain/value_objects/sheet_join_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Multi-Table Excel Fixtures Integration Test', () {
    late AppDatabase database;
    late SchemaRepositoryImpl schemaRepository;
    late QueryRepositoryImpl queryRepository;
    late ImportDataService importDataService;
    late CreateDatasetService createDatasetService;
    late OpenDatasetUseCase openDatasetUseCase;
    late FetchRowsUseCase fetchRowsUseCase;
    late MultiSheetAnalysisService analysisService;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      final datasource = DriftDatasource(database);
      final dynamicTableBuilder = DynamicTableBuilder();
      final datasetsRepository = DatasetsRepositoryImpl(
        dao: DatasetsDao(database),
      );
      schemaRepository = SchemaRepositoryImpl(datasource, dynamicTableBuilder);
      queryRepository = QueryRepositoryImpl(datasource);
      final datasetFileRepository = DatasetFileRepositoryImpl(
        dao: DatasetFilesDao(database),
      );
      final savedQueriesRepository = SavedMultiSheetQueryRepositoryImpl(
        SavedMultiSheetQueriesDao(database),
      );
      final relationshipRepository = DatasetRelationshipRepositoryImpl(
        DatasetRelationshipsDao(database),
      );

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
        createDatasetUseCase:
            CreateDatasetUseCase(repository: datasetsRepository),
        registerDatasetFileUseCase:
            RegisterDatasetFileUseCase(repository: datasetFileRepository),
        createDatasetTableUseCase:
            CreateDatasetTableUseCase(repository: schemaRepository),
        registerColumnsUseCase:
            RegisterColumnsUseCase(repository: schemaRepository),
        buildDynamicTableUseCase:
            BuildDynamicTableUseCase(repository: schemaRepository),
        insertRowsUseCase: InsertRowsUseCase(queryRepository),
        updateDatasetUiStateUseCase:
            UpdateDatasetUiStateUseCase(repository: datasetsRepository),
      );

      openDatasetUseCase = OpenDatasetUseCase(repository: datasetsRepository);
      fetchRowsUseCase = FetchRowsUseCase(repository: queryRepository);

      analysisService = MultiSheetAnalysisService(
        schemaRepository: schemaRepository,
        queryRepository: queryRepository,
        executePreview:
            ExecuteMultiSheetPreviewUseCase(repository: queryRepository),
        saveQueryUseCase:
            SaveMultiSheetQueryUseCase(repository: savedQueriesRepository),
        listQueriesUseCase:
            ListMultiSheetQueriesUseCase(repository: savedQueriesRepository),
        loadQueryUseCase:
            LoadMultiSheetQueryUseCase(repository: savedQueriesRepository),
        deleteQueryUseCase:
            DeleteMultiSheetQueryUseCase(repository: savedQueriesRepository),
        createRelationshipUseCase: CreateDatasetRelationshipUseCase(
          repository: relationshipRepository,
        ),
        createRelationshipsUseCase: CreateDatasetRelationshipsUseCase(
          repository: relationshipRepository,
        ),
        listRelationshipsUseCase: ListDatasetRelationshipsUseCase(
          repository: relationshipRepository,
        ),
        updateRelationshipUseCase: UpdateDatasetRelationshipUseCase(
          repository: relationshipRepository,
        ),
      );
    });

    tearDown(() async {
      await database.close();
    });

    test(
      'single sheet with multiple tables (single_sheet_multi_table.xlsx): prepares, persists, queries, and suggests intra-sheet relationships',
      () async {
        final file = ImportFile.fromPath(
          fileName: 'single_sheet_multi_table.xlsx',
          path: 'test/fixtures/excel/single_sheet_multi_table.xlsx',
        );

        // 1. Prepare import with multiple tables detection enabled
        final prepared = await importDataService.prepareImport(
          file: file,
          detectMultipleTables: true,
        );

        expect(prepared.sheets.length, 2);
        final customersPrep =
            prepared.sheets.firstWhere((s) => s.sheet.name == 'Customers');
        final ordersPrep =
            prepared.sheets.firstWhere((s) => s.sheet.name == 'Orders');

        expect(customersPrep.sheet.sourceSheetName, 'Dashboard');
        expect(customersPrep.sheet.cellRange, 'A2:C5');
        expect(customersPrep.inferredColumns.map((c) => c.originalName), [
          'id',
          'name',
          'city',
        ]);

        expect(ordersPrep.sheet.sourceSheetName, 'Dashboard');
        expect(ordersPrep.sheet.cellRange, 'A9:D12');
        expect(ordersPrep.inferredColumns.map((c) => c.originalName), [
          'order_id',
          'customer_id',
          'amount',
          'order_date',
        ]);

        // 2. Confirm and create dataset
        final created = await createDatasetService.createDataset(
          confirmedImport: ConfirmedImport.fromPreparedResult(
            datasetName: 'Dashboard Dataset',
            preparedImport: prepared,
          ),
        );

        expect(created.rowCount, 6); // 3 customers + 3 orders

        final opened = await openDatasetUseCase(created.datasetId);
        expect(opened.name, 'Dashboard Dataset');

        // 3. Inspect persisted tables
        final tables =
            await schemaRepository.getTablesForDataset(created.datasetId);
        expect(tables.length, 2);

        final customersTable =
            tables.firstWhere((t) => t.displayName == 'Customers');
        final ordersTable = tables.firstWhere((t) => t.displayName == 'Orders');

        expect(customersTable.sourceSheetName, 'Dashboard');
        expect(customersTable.effectiveSourceSheetName, 'Dashboard');
        expect(ordersTable.sourceSheetName, 'Dashboard');
        expect(ordersTable.effectiveSourceSheetName, 'Dashboard');

        // 4. Verify data rows in SQLite
        final customerRows = await fetchRowsUseCase(
          tableName: customersTable.sqlTableName,
          limit: 10,
          offset: 0,
        );
        expect(customerRows.length, 3);
        expect(customerRows[0]['name'], 'Alice');
        expect(customerRows[0]['city'], 'Rome');

        final orderRows = await fetchRowsUseCase(
          tableName: ordersTable.sqlTableName,
          limit: 10,
          offset: 0,
        );
        expect(orderRows.length, 3);
        expect(orderRows[0]['order_id'], 101);
        expect(orderRows[0]['customer_id'], 1);

        // 5. Suggest relationships: orders.customer_id -> customers.id
        final sheets = await analysisService.loadSheets(created.datasetId);
        final suggestions = await analysisService.suggestRelationships(
          sheets: sheets,
          selectedTableIds: tables.map((t) => t.id).toList(),
        );

        expect(suggestions, isNotEmpty);
        final customerOrderSuggestion = suggestions.firstWhere(
          (s) =>
              s.relationship.tableIds.contains(ordersTable.id) &&
              s.relationship.tableIds.contains(customersTable.id),
        );
        expect(customerOrderSuggestion.score, greaterThan(0.5));
      },
    );

    test(
      'multiple sheets with multiple tables (multi_sheet_multi_table.xlsx): prepares, persists, queries, and discovers both intra-sheet and cross-sheet relationships',
      () async {
        final file = ImportFile.fromPath(
          fileName: 'multi_sheet_multi_table.xlsx',
          path: 'test/fixtures/excel/multi_sheet_multi_table.xlsx',
        );

        // 1. Prepare import
        final prepared = await importDataService.prepareImport(
          file: file,
          detectMultipleTables: true,
        );

        expect(prepared.sheets.length, 4);

        final ordersPrep =
            prepared.sheets.firstWhere((s) => s.sheet.name == 'Orders');
        final returnsPrep =
            prepared.sheets.firstWhere((s) => s.sheet.name == 'Returns');
        final productsPrep =
            prepared.sheets.firstWhere((s) => s.sheet.name == 'Products');
        final suppliersPrep =
            prepared.sheets.firstWhere((s) => s.sheet.name == 'Suppliers');

        expect(ordersPrep.sheet.sourceSheetName, 'Sales');
        expect(returnsPrep.sheet.sourceSheetName, 'Sales');
        expect(productsPrep.sheet.sourceSheetName, 'Inventory');
        expect(suppliersPrep.sheet.sourceSheetName, 'Inventory');

        // 2. Create dataset
        final created = await createDatasetService.createDataset(
          confirmedImport: ConfirmedImport.fromPreparedResult(
            datasetName: 'E-Commerce Enterprise',
            preparedImport: prepared,
          ),
        );

        // 3. Inspect persisted tables
        final tables =
            await schemaRepository.getTablesForDataset(created.datasetId);
        expect(tables.length, 4);

        final uniqueSheets =
            tables.map((t) => t.effectiveSourceSheetName).toSet();
        expect(uniqueSheets, {'Sales', 'Inventory'});

        final ordersTable = tables.firstWhere((t) => t.displayName == 'Orders');
        final returnsTable =
            tables.firstWhere((t) => t.displayName == 'Returns');
        final productsTable =
            tables.firstWhere((t) => t.displayName == 'Products');
        final suppliersTable =
            tables.firstWhere((t) => t.displayName == 'Suppliers');

        // 4. Suggest relationships across the entire dataset
        final sheets = await analysisService.loadSheets(created.datasetId);
        final allSuggestions = await analysisService.suggestRelationships(
          sheets: sheets,
          selectedTableIds: tables.map((t) => t.id).toList(),
        );

        // Intra-sheet: Returns <-> Orders (order_id)
        final returnsOrders = allSuggestions.where(
          (s) =>
              s.relationship.tableIds.contains(returnsTable.id) &&
              s.relationship.tableIds.contains(ordersTable.id),
        );
        expect(returnsOrders, isNotEmpty);

        // Cross-sheet: Orders (Sales) <-> Products (Inventory) (product_id)
        final ordersProducts = allSuggestions.where(
          (s) =>
              s.relationship.tableIds.contains(ordersTable.id) &&
              s.relationship.tableIds.contains(productsTable.id),
        );
        expect(ordersProducts, isNotEmpty);

        // Intra-sheet: Products <-> Suppliers (supplier_id)
        final productsSuppliers = allSuggestions.where(
          (s) =>
              s.relationship.tableIds.contains(productsTable.id) &&
              s.relationship.tableIds.contains(suppliersTable.id),
        );
        expect(productsSuppliers, isNotEmpty);

        // 5. Execute preview join query between Orders and Products (cross-sheet)
        final rel = await analysisService.createRelationship(
          DatasetRelationship(
            datasetId: created.datasetId,
            endpointATableId: ordersTable.id,
            endpointAColumnDbName: 'product_id',
            endpointBTableId: productsTable.id,
            endpointBColumnDbName: 'product_id',
          ),
        );

        final relationships =
            await analysisService.loadRelationships(created.datasetId);
        final relMap = {for (final r in relationships) r.id!: r};

        final spec = MultiSheetQuerySpec(
          baseTableId: ordersTable.id,
          selectedTableIds: [ordersTable.id, productsTable.id],
          selectedColumnsByTableId: {
            ordersTable.id: ['order_id', 'product_id', 'amount'],
            productsTable.id: ['product_id', 'name', 'price'],
          },
          joins: [
            MultiSheetJoin(
              relationshipId: rel.id!,
              joinType: SheetJoinType.inner,
            ),
          ],
          resultLimit: 10,
        );

        final preview = await analysisService.runPreview(
          datasetId: created.datasetId,
          spec: spec,
          sheets: sheets,
          relationshipsById: relMap,
        );

        expect(preview.rows.length, 3);
        // Each order is joined with its product
        expect(preview.rows[0].keys, contains('t0__order_id'));
        expect(preview.rows[0].keys, contains('t0__product_id'));
        expect(preview.rows[0].keys, contains('t1__name'));
      },
    );
  });
}
