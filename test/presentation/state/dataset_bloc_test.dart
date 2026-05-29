import 'dart:async';

import 'package:exlser/application/dto/chart_data.dart';
import 'package:exlser/application/dto/chart_load_result.dart';
import 'package:exlser/application/services/analysis_service.dart';
import 'package:exlser/domain/entities/chart_suggestion.dart';
import 'package:exlser/domain/entities/dataset.dart';
import 'package:exlser/domain/value_objects/chart_type.dart';
import 'package:exlser/domain/value_objects/aggregation_type.dart';
import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/entities/dataset_table.dart';
import 'package:exlser/domain/repositories/schema_repository.dart';
import 'package:exlser/domain/usecases/dataset/open_dataset_usecase.dart';
import 'package:exlser/domain/usecases/dataset/update_dataset_ui_state_usecase.dart';
import 'package:exlser/domain/usecases/query/apply_filters_usecase.dart';
import 'package:exlser/domain/usecases/query/execute_read_only_query_usecase.dart';
import 'package:exlser/domain/usecases/query/fetch_rows_usecase.dart';
import 'package:exlser/domain/usecases/query/read_only_sql_validator.dart';
import 'package:exlser/domain/value_objects/column_type.dart';
import 'package:exlser/domain/value_objects/dataset_filter.dart';
import 'package:exlser/domain/value_objects/dataset_query_mode.dart';
import 'package:exlser/domain/value_objects/dataset_sort.dart';
import 'package:exlser/domain/value_objects/filter_operator.dart';
import 'package:exlser/presentation/state/dataset_bloc.dart';
import 'package:exlser/presentation/state/dataset_event.dart';
import 'package:exlser/presentation/state/dataset_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockOpenDatasetUseCase extends Mock implements OpenDatasetUseCase {}

class MockSchemaRepository extends Mock implements SchemaRepository {}

class MockFetchRowsUseCase extends Mock implements FetchRowsUseCase {}

class MockApplyFiltersUseCase extends Mock implements ApplyFiltersUseCase {}

class MockExecuteReadOnlyQueryUseCase extends Mock
    implements ExecuteReadOnlyQueryUseCase {}

class MockUpdateDatasetUiStateUseCase extends Mock
    implements UpdateDatasetUiStateUseCase {}

class MockAnalysisService extends Mock implements AnalysisService {}

void main() {
  setUpAll(() {
    registerFallbackValue(<DatasetFilter>[]);
    registerFallbackValue(<String>{});
    registerFallbackValue(
      DatasetSort(
        column: _column(),
        direction: SortDirection.ascending,
      ),
    );
    registerFallbackValue(const ChartSuggestion.none());
  });

  group('DatasetBloc', () {
    late MockOpenDatasetUseCase openDataset;
    late MockSchemaRepository schemaRepository;
    late MockFetchRowsUseCase fetchRows;
    late MockApplyFiltersUseCase applyFilters;
    late MockExecuteReadOnlyQueryUseCase executeReadOnlyQuery;
    late MockUpdateDatasetUiStateUseCase updateDatasetUiState;
    late MockAnalysisService analysisService;
    late DatasetBloc bloc;

    setUp(() {
      openDataset = MockOpenDatasetUseCase();
      schemaRepository = MockSchemaRepository();
      fetchRows = MockFetchRowsUseCase();
      applyFilters = MockApplyFiltersUseCase();
      executeReadOnlyQuery = MockExecuteReadOnlyQueryUseCase();
      updateDatasetUiState = MockUpdateDatasetUiStateUseCase();
      analysisService = MockAnalysisService();
      when(() => updateDatasetUiState.call(
            datasetId: any(named: 'datasetId'),
            uiStateJson: any(named: 'uiStateJson'),
          )).thenAnswer((_) async {});
      when(() => applyFilters.countRows(
            tableName: any(named: 'tableName'),
            filters: any(named: 'filters'),
          )).thenAnswer((_) async => 1);
      bloc = DatasetBloc(
        openDataset: openDataset,
        schemaRepository: schemaRepository,
        fetchRows: fetchRows,
        applyFilters: applyFilters,
        executeReadOnlyQuery: executeReadOnlyQuery,
        updateDatasetUiState: updateDatasetUiState,
        analysisService: analysisService,
      );
    });

    tearDown(() async {
      await bloc.close();
    });

    test('should load dataset workspace', () async {
      final dataset = _dataset();
      final tables = [_table(id: 10)];
      final columns = [_column()];
      final rows = [
        {'id': 1, 'product': 'book'},
      ];

      _mockWorkspaceLoad(
        openDataset: openDataset,
        schemaRepository: schemaRepository,
        fetchRows: fetchRows,
        dataset: dataset,
        tables: tables,
        columns: columns,
        rows: rows,
      );

      final loadedState = bloc.stream.firstWhere(
        (state) => state is DatasetLoadedState,
      );

      bloc.add(const LoadDatasetEvent(1));

      final state = await loadedState as DatasetLoadedState;

      expect(state.dataset, dataset);
      expect(state.tables, tables);
      expect(state.activeTable.id, 10);
      expect(state.columns, columns);
      expect(state.rows, [
        {'product': 'book'},
      ]);
      expect(state.viewMode, DatasetViewMode.table);
    });

    test('should restore persisted workspace state', () async {
      final firstTable = _table(id: 10, name: 'Sheet1', tableName: 'tbl_1');
      final secondTable = _table(id: 11, name: 'Sheet2', tableName: 'tbl_2');
      final brandColumn = _column(tableId: 11, dbName: 'brand');
      final dataset = _dataset(
        uiStateJson: '''
{
  "activeTableId": 11,
  "viewMode": "cards",
  "filters": [
    {
      "columnDbName": "brand",
      "operator": "contains",
      "value": "van"
    }
  ],
  "sort": {
    "columnDbName": "brand",
    "direction": "descending"
  },
  "hiddenColumnDbNames": ["brand"]
}
''',
      );

      when(() => openDataset.call(1)).thenAnswer((_) async => dataset);
      when(() => schemaRepository.getTablesForDataset(1)).thenAnswer(
        (_) async => [firstTable, secondTable],
      );
      when(() => schemaRepository.getColumnsForTable(11)).thenAnswer(
        (_) async => [brandColumn],
      );
      when(() => applyFilters.call(
            tableName: 'tbl_2',
            filters: any(named: 'filters'),
            sort: any(named: 'sort'),
            limit: DatasetBloc.defaultRowLimit,
            offset: 0,
          )).thenAnswer(
        (_) async => [
          {'id': 1, 'brand': 'Vans'},
        ],
      );

      final loadedState = bloc.stream.firstWhere(
        (state) => state is DatasetLoadedState,
      );

      bloc.add(const LoadDatasetEvent(1));

      final state = await loadedState as DatasetLoadedState;

      expect(state.activeTable.id, 11);
      expect(state.viewMode, DatasetViewMode.cards);
      expect(state.filters.single.column.dbName, 'brand');
      expect(state.filters.single.operator, FilterOperator.contains);
      expect(state.filters.single.value, 'van');
      expect(state.sort?.column.dbName, 'brand');
      expect(state.sort?.direction, SortDirection.descending);
      expect(state.hiddenColumnDbNames, isEmpty);
      expect(state.visibleColumns.map((column) => column.dbName), ['brand']);
      expect(state.rows, [
        {'brand': 'Vans'},
      ]);
    });

    test('should expose empty state when dataset has no tables', () async {
      final dataset = _dataset();

      when(() => openDataset.call(1)).thenAnswer((_) async => dataset);
      when(() => schemaRepository.getTablesForDataset(1))
          .thenAnswer((_) async => []);

      final emptyState = bloc.stream.firstWhere(
        (state) => state is DatasetEmptyState,
      );

      bloc.add(const LoadDatasetEvent(1));

      final state = await emptyState as DatasetEmptyState;

      expect(state.dataset, dataset);
    });

    test('should expose error state when loading fails', () async {
      when(() => openDataset.call(1)).thenThrow(Exception('load failed'));

      final errorState = bloc.stream.firstWhere(
        (state) => state is DatasetErrorState,
      );

      bloc.add(const LoadDatasetEvent(1));

      final state = await errorState as DatasetErrorState;

      expect(state.code, 'load_failed');
    });

    test('should change active sheet and reload columns and rows', () async {
      final dataset = _dataset();
      final firstTable = _table(id: 10, name: 'Sheet1', tableName: 'tbl_1');
      final secondTable = _table(id: 11, name: 'Sheet2', tableName: 'tbl_2');

      _mockWorkspaceLoad(
        openDataset: openDataset,
        schemaRepository: schemaRepository,
        fetchRows: fetchRows,
        dataset: dataset,
        tables: [firstTable, secondTable],
        columns: [_column(tableId: 10)],
        rows: [
          {'id': 1, 'product': 'book'},
        ],
      );
      when(() => schemaRepository.getColumnsForTable(11)).thenAnswer(
        (_) async => [_column(tableId: 11, dbName: 'price')],
      );
      when(() => fetchRows.call(
            tableName: 'tbl_2',
            limit: DatasetBloc.defaultRowLimit,
            offset: 0,
          )).thenAnswer(
        (_) async => [
          {'id': 1, 'price': 10},
        ],
      );

      bloc.add(const LoadDatasetEvent(1));
      await bloc.stream.firstWhere((state) => state is DatasetLoadedState);

      final changedState = bloc.stream.firstWhere(
        (state) => state is DatasetLoadedState && state.activeTable.id == 11,
      );

      bloc.add(const ChangeSheetEvent(11));

      final state = await changedState as DatasetLoadedState;

      expect(state.activeTable.id, 11);
      expect(state.columns.single.dbName, 'price');
      expect(state.rows, [
        {'price': 10},
      ]);
    });

    test('should restore filters stored for the selected sheet', () async {
      final dataset = _dataset(
        uiStateJson: '''
{
  "activeTableId": 10,
  "tableStates": {
    "11": {
      "filters": [
        {
          "columnDbName": "brand",
          "operator": "contains",
          "value": "van"
        }
      ]
    }
  }
}
''',
      );
      final firstTable = _table(id: 10, name: 'Sheet1', tableName: 'tbl_1');
      final secondTable = _table(id: 11, name: 'Sheet2', tableName: 'tbl_2');
      final brandColumn = _column(tableId: 11, dbName: 'brand');

      _mockWorkspaceLoad(
        openDataset: openDataset,
        schemaRepository: schemaRepository,
        fetchRows: fetchRows,
        dataset: dataset,
        tables: [firstTable, secondTable],
        columns: [_column(tableId: 10)],
        rows: [
          {'id': 1, 'product': 'book'},
        ],
      );
      when(() => schemaRepository.getColumnsForTable(11)).thenAnswer(
        (_) async => [brandColumn],
      );
      when(() => applyFilters.call(
            tableName: 'tbl_2',
            filters: any(named: 'filters'),
            sort: any(named: 'sort'),
            limit: DatasetBloc.defaultRowLimit,
            offset: 0,
          )).thenAnswer(
        (_) async => [
          {'id': 2, 'brand': 'Vans'},
        ],
      );

      bloc.add(const LoadDatasetEvent(1));
      await bloc.stream.firstWhere((state) => state is DatasetLoadedState);

      final changedState = bloc.stream.firstWhere(
        (state) => state is DatasetLoadedState && state.activeTable.id == 11,
      );

      bloc.add(const ChangeSheetEvent(11));

      final state = await changedState as DatasetLoadedState;

      expect(state.filters.single.column.dbName, 'brand');
      expect(state.filters.single.value, 'van');
      expect(state.rows, [
        {'brand': 'Vans'},
      ]);
      final captured = verify(() => applyFilters.call(
            tableName: 'tbl_2',
            filters: captureAny(named: 'filters'),
            sort: null,
            limit: DatasetBloc.defaultRowLimit,
            offset: 0,
          )).captured;
      expect(captured.single, isA<List<DatasetFilter>>());
      expect(
        state.dataset.uiStateJson,
        contains('"tableStates"'),
      );
    });

    test('should change view mode without reloading rows', () async {
      final dataset = _dataset();

      _mockWorkspaceLoad(
        openDataset: openDataset,
        schemaRepository: schemaRepository,
        fetchRows: fetchRows,
        dataset: dataset,
        tables: [_table(id: 10)],
        columns: [_column()],
        rows: [
          {'id': 1, 'product': 'book'},
        ],
      );

      bloc.add(const LoadDatasetEvent(1));
      await bloc.stream.firstWhere((state) => state is DatasetLoadedState);
      verify(() => fetchRows.call(
            tableName: 'tbl_1',
            limit: DatasetBloc.defaultRowLimit,
            offset: 0,
          )).called(1);

      final changedState = bloc.stream.firstWhere(
        (state) =>
            state is DatasetLoadedState &&
            state.viewMode == DatasetViewMode.cards,
      );

      bloc.add(const ChangeViewModeEvent(DatasetViewMode.cards));

      final state = await changedState as DatasetLoadedState;

      expect(state.viewMode, DatasetViewMode.cards);
      expect(state.dataset.uiStateJson, contains('"viewMode":"cards"'));
      verify(() => updateDatasetUiState.call(
            datasetId: 1,
            uiStateJson: any(named: 'uiStateJson'),
          )).called(1);
      verifyNever(() => fetchRows.call(
            tableName: 'tbl_1',
            limit: DatasetBloc.defaultRowLimit,
            offset: 0,
          ));
    });

    test('should hide and show columns without reloading rows', () async {
      final dataset = _dataset();
      final productColumn = _column(dbName: 'product');
      final brandColumn = _column(dbName: 'brand');

      _mockWorkspaceLoad(
        openDataset: openDataset,
        schemaRepository: schemaRepository,
        fetchRows: fetchRows,
        dataset: dataset,
        tables: [_table(id: 10)],
        columns: [productColumn, brandColumn],
        rows: [
          {'id': 1, 'product': 'Sk8-Hi', 'brand': 'Vans'},
        ],
      );

      bloc.add(const LoadDatasetEvent(1));
      await bloc.stream.firstWhere((state) => state is DatasetLoadedState);
      clearInteractions(fetchRows);

      final hiddenState = bloc.stream.firstWhere(
        (state) =>
            state is DatasetLoadedState &&
            state.hiddenColumnDbNames.contains('product'),
      );

      bloc.add(
        const SetColumnHiddenEvent(
          columnDbName: 'product',
          hidden: true,
        ),
      );

      final state = await hiddenState as DatasetLoadedState;

      expect(state.visibleColumns.map((column) => column.dbName), ['brand']);
      expect(state.dataset.uiStateJson, contains('hiddenColumnDbNames'));

      final shownState = bloc.stream.firstWhere(
        (state) =>
            state is DatasetLoadedState && state.hiddenColumnDbNames.isEmpty,
      );

      bloc.add(
        const SetColumnHiddenEvent(
          columnDbName: 'product',
          hidden: false,
        ),
      );

      final restoredState = await shownState as DatasetLoadedState;

      expect(
        restoredState.visibleColumns.map((column) => column.dbName),
        ['product', 'brand'],
      );
      verify(() => updateDatasetUiState.call(
            datasetId: 1,
            uiStateJson: any(named: 'uiStateJson'),
          )).called(2);
      verifyNever(() => fetchRows.call(
            tableName: 'tbl_1',
            limit: DatasetBloc.defaultRowLimit,
            offset: 0,
          ));
    });

    test('should apply filters through query use case', () async {
      final dataset = _dataset();
      final column = _column();
      final filter = DatasetFilter(
        column: column,
        operator: FilterOperator.contains,
        value: 'pen',
      );

      _mockWorkspaceLoad(
        openDataset: openDataset,
        schemaRepository: schemaRepository,
        fetchRows: fetchRows,
        dataset: dataset,
        tables: [_table(id: 10)],
        columns: [column],
        rows: [
          {'id': 1, 'product': 'book'},
        ],
      );
      when(() => applyFilters.call(
            tableName: 'tbl_1',
            filters: any(named: 'filters'),
            sort: any(named: 'sort'),
            limit: DatasetBloc.defaultRowLimit,
            offset: 0,
          )).thenAnswer(
        (_) async => [
          {'id': 2, 'product': 'pen'},
        ],
      );

      bloc.add(const LoadDatasetEvent(1));
      await bloc.stream.firstWhere((state) => state is DatasetLoadedState);

      final filteredState = bloc.stream.firstWhere(
        (state) =>
            state is DatasetLoadedState &&
            state.filters.isNotEmpty &&
            state.rows.single['product'] == 'pen',
      );

      bloc.add(AddFilterEvent(filter));

      final state = await filteredState as DatasetLoadedState;

      expect(state.filters.single, filter);
      expect(state.rows, [
        {'product': 'pen'},
      ]);
      expect(state.pageIndex, 0);

      final captured = verify(() => applyFilters.call(
            tableName: 'tbl_1',
            filters: captureAny(named: 'filters'),
            sort: null,
            limit: DatasetBloc.defaultRowLimit,
            offset: 0,
          )).captured;

      expect(captured.single, [filter]);
      verify(() => updateDatasetUiState.call(
            datasetId: 1,
            uiStateJson: any(named: 'uiStateJson'),
          )).called(1);
    });

    test('should reload loaded analytics when filters change', () async {
      final dataset = _dataset();
      final column = _column();
      final filter = DatasetFilter(
        column: column,
        operator: FilterOperator.contains,
        value: 'pen',
      );
      final suggestion = ChartSuggestion(
        chartType: ChartType.bar,
        xColumn: column,
      );
      const initialChartData = CategoryChartData(
        chartType: ChartType.bar,
        xLabel: 'product',
        yLabel: 'COUNT',
        points: [CategoryPoint(label: 'book', value: 1)],
        aggregationType: AggregationType.count,
      );
      const filteredChartData = CategoryChartData(
        chartType: ChartType.bar,
        xLabel: 'product',
        yLabel: 'COUNT',
        points: [CategoryPoint(label: 'pen', value: 1)],
        aggregationType: AggregationType.count,
      );
      var chartLoadCount = 0;

      _mockWorkspaceLoad(
        openDataset: openDataset,
        schemaRepository: schemaRepository,
        fetchRows: fetchRows,
        dataset: dataset,
        tables: [_table(id: 10)],
        columns: [column],
        rows: [
          {'id': 1, 'product': 'book'},
        ],
      );
      when(() => analysisService.suggestAllCharts(any()))
          .thenReturn([suggestion]);
      when(() => applyFilters.buildWhereClause(any())).thenAnswer(
        (invocation) {
          final filters =
              invocation.positionalArguments.first as List<DatasetFilter>;
          if (filters.isEmpty) return null;
          return (sql: 'product LIKE ?', arguments: ['%pen%']);
        },
      );
      when(() => analysisService.loadChartData(
            tableName: any(named: 'tableName'),
            suggestion: any(named: 'suggestion'),
            whereClause: any(named: 'whereClause'),
            whereArguments: any(named: 'whereArguments'),
          )).thenAnswer((_) async {
        chartLoadCount += 1;
        final data = chartLoadCount == 1 ? initialChartData : filteredChartData;
        return ChartLoadResult.success(data);
      });
      when(() => applyFilters.call(
            tableName: 'tbl_1',
            filters: any(named: 'filters'),
            sort: any(named: 'sort'),
            limit: DatasetBloc.defaultRowLimit,
            offset: 0,
          )).thenAnswer(
        (_) async => [
          {'id': 2, 'product': 'pen'},
        ],
      );

      bloc.add(const LoadDatasetEvent(1));
      await bloc.stream.firstWhere((state) => state is DatasetLoadedState);
      bloc.add(const LoadAnalyticsEvent());
      await bloc.stream.firstWhere(
        (state) =>
            state is DatasetLoadedState &&
            state.analyticsState is DatasetAnalyticsLoadedState,
      );

      bloc.add(AddFilterEvent(filter));

      final filteredAnalyticsState = await bloc.stream.firstWhere((state) {
        if (state is! DatasetLoadedState || state.filters.isEmpty) {
          return false;
        }
        final analytics = state.analyticsState;
        if (analytics is! DatasetAnalyticsLoadedState) {
          return false;
        }
        return analytics.charts.single.chartData == filteredChartData;
      }) as DatasetLoadedState;

      final analytics =
          filteredAnalyticsState.analyticsState as DatasetAnalyticsLoadedState;
      expect(filteredAnalyticsState.rows, [
        {'product': 'pen'},
      ]);
      expect(analytics.charts.single.chartData, filteredChartData);
      expect(
        filteredAnalyticsState.dataset.uiStateJson,
        contains('"filters"'),
      );
      expect(chartLoadCount, 2);
    });

    test('should change row limit and reload the first page', () async {
      final dataset = _dataset();
      final table = _table(id: 10, rowCount: 920);
      final column = _column();

      _mockWorkspaceLoad(
        openDataset: openDataset,
        schemaRepository: schemaRepository,
        fetchRows: fetchRows,
        dataset: dataset,
        tables: [table],
        columns: [column],
        rows: [
          {'id': 1, 'product': 'book'},
        ],
      );
      when(() => fetchRows.call(
            tableName: 'tbl_1',
            limit: 250,
            offset: 0,
          )).thenAnswer(
        (_) async => [
          {'id': 2, 'product': 'pen'},
        ],
      );

      bloc.add(const LoadDatasetEvent(1));
      await bloc.stream.firstWhere((state) => state is DatasetLoadedState);

      final limitedState = bloc.stream.firstWhere(
        (state) =>
            state is DatasetLoadedState &&
            state.rowLimit == 250 &&
            state.pageIndex == 0,
      );

      bloc.add(const ChangeRowLimitEvent(250));

      final state = await limitedState as DatasetLoadedState;

      expect(state.totalRowCount, 920);
      expect(state.pageCount, 4);
      expect(state.rows, [
        {'product': 'pen'},
      ]);
      verify(() => fetchRows.call(
            tableName: 'tbl_1',
            limit: 250,
            offset: 0,
          )).called(1);
      verify(() => updateDatasetUiState.call(
            datasetId: 1,
            uiStateJson: any(named: 'uiStateJson'),
          )).called(1);
    });

    test('should load requested page using limit and offset', () async {
      final dataset = _dataset();
      final table = _table(id: 10, rowCount: 920);
      final column = _column();

      _mockWorkspaceLoad(
        openDataset: openDataset,
        schemaRepository: schemaRepository,
        fetchRows: fetchRows,
        dataset: dataset,
        tables: [table],
        columns: [column],
        rows: [
          {'id': 1, 'product': 'book'},
        ],
      );
      when(() => fetchRows.call(
            tableName: 'tbl_1',
            limit: DatasetBloc.defaultRowLimit,
            offset: 100,
          )).thenAnswer(
        (_) async => [
          {'id': 101, 'product': 'page two'},
        ],
      );

      bloc.add(const LoadDatasetEvent(1));
      await bloc.stream.firstWhere((state) => state is DatasetLoadedState);

      final pageState = bloc.stream.firstWhere(
        (state) =>
            state is DatasetLoadedState &&
            state.pageIndex == 1 &&
            state.rows.single['product'] == 'page two',
      );

      bloc.add(const ChangePageEvent(1));

      final state = await pageState as DatasetLoadedState;

      expect(state.pageNumber, 2);
      expect(state.pageCount, 10);
      expect(state.canGoToPreviousPage, isTrue);
      expect(state.canGoToNextPage, isTrue);
      verify(() => fetchRows.call(
            tableName: 'tbl_1',
            limit: DatasetBloc.defaultRowLimit,
            offset: 100,
          )).called(1);
    });

    test('should toggle sorting by column', () async {
      final dataset = _dataset();
      final column = _column();

      _mockWorkspaceLoad(
        openDataset: openDataset,
        schemaRepository: schemaRepository,
        fetchRows: fetchRows,
        dataset: dataset,
        tables: [_table(id: 10)],
        columns: [column],
        rows: [
          {'id': 1, 'product': 'book'},
        ],
      );
      when(() => applyFilters.call(
            tableName: 'tbl_1',
            filters: any(named: 'filters'),
            sort: any(named: 'sort'),
            limit: DatasetBloc.defaultRowLimit,
            offset: 0,
          )).thenAnswer(
        (_) async => [
          {'id': 2, 'product': 'pen'},
        ],
      );

      bloc.add(const LoadDatasetEvent(1));
      await bloc.stream.firstWhere((state) => state is DatasetLoadedState);

      final sortedState = bloc.stream.firstWhere(
        (state) =>
            state is DatasetLoadedState &&
            state.sort?.direction == SortDirection.ascending,
      );

      bloc.add(ToggleSortColumnEvent(column));

      final state = await sortedState as DatasetLoadedState;

      expect(state.sort?.column.dbName, column.dbName);
      expect(state.sort?.direction, SortDirection.ascending);
      expect(state.rows, [
        {'product': 'pen'},
      ]);

      final captured = verify(() => applyFilters.call(
            tableName: 'tbl_1',
            filters: const [],
            sort: captureAny(named: 'sort'),
            limit: DatasetBloc.defaultRowLimit,
            offset: 0,
          )).captured;

      final sort = captured.single as DatasetSort;
      expect(sort.column.dbName, column.dbName);
      expect(sort.direction, SortDirection.ascending);
      verify(() => updateDatasetUiState.call(
            datasetId: 1,
            uiStateJson: any(named: 'uiStateJson'),
          )).called(1);
    });

    test('should switch to read-only query mode and run a SELECT query',
        () async {
      final dataset = _dataset();

      _mockWorkspaceLoad(
        openDataset: openDataset,
        schemaRepository: schemaRepository,
        fetchRows: fetchRows,
        dataset: dataset,
        tables: [_table(id: 10)],
        columns: [_column()],
        rows: [
          {'id': 1, 'product': 'book'},
        ],
      );
      when(() => executeReadOnlyQuery.call(
            sql: any(named: 'sql'),
            activeTableName: any(named: 'activeTableName'),
            allowedTableNames: any(named: 'allowedTableNames'),
            limit: any(named: 'limit'),
          )).thenAnswer(
        (_) async => const ReadOnlyQueryResult(
          rows: [
            {'product': 'Vans', 'count': 2},
          ],
          executedSql: 'SELECT * FROM (SELECT product, COUNT(*) AS count '
              'FROM tbl_1) LIMIT 100',
          rowCount: 8,
        ),
      );

      bloc.add(const LoadDatasetEvent(1));
      await bloc.stream.firstWhere((state) => state is DatasetLoadedState);

      bloc
        ..add(const ChangeQueryModeEvent(DatasetQueryMode.sql))
        ..add(const UpdateReadOnlyQueryEvent(
          'SELECT product, COUNT(*) AS count FROM sheet',
        ))
        ..add(const RunReadOnlyQueryEvent());

      final queryState = await bloc.stream.firstWhere(
        (state) =>
            state is DatasetLoadedState &&
            state.queryMode == DatasetQueryMode.sql &&
            state.readOnlyQueryRows.isNotEmpty,
      ) as DatasetLoadedState;

      expect(queryState.readOnlyQueryRows, [
        {'product': 'Vans', 'count': 2},
      ]);
      expect(
        queryState.readOnlyQueryColumns.map((column) => column.dbName),
        ['product', 'count'],
      );
      expect(queryState.readOnlyQueryErrorCode, isNull);
      expect(queryState.readOnlyQueryTotalRowCount, 8);
      verify(() => executeReadOnlyQuery.call(
            sql: 'SELECT product, COUNT(*) AS count FROM sheet',
            activeTableName: 'tbl_1',
            allowedTableNames: {'tbl_1'},
            limit: 100,
          )).called(1);
    });

    test('should expose read-only query validation errors', () async {
      final dataset = _dataset();

      _mockWorkspaceLoad(
        openDataset: openDataset,
        schemaRepository: schemaRepository,
        fetchRows: fetchRows,
        dataset: dataset,
        tables: [_table(id: 10)],
        columns: [_column()],
        rows: [
          {'id': 1, 'product': 'book'},
        ],
      );
      when(() => executeReadOnlyQuery.call(
            sql: any(named: 'sql'),
            activeTableName: any(named: 'activeTableName'),
            allowedTableNames: any(named: 'allowedTableNames'),
            limit: any(named: 'limit'),
          )).thenThrow(
        const ReadOnlyQueryException(
          ReadOnlySqlValidator.unsafeStatementCode,
        ),
      );

      bloc.add(const LoadDatasetEvent(1));
      await bloc.stream.firstWhere((state) => state is DatasetLoadedState);

      bloc
        ..add(const ChangeQueryModeEvent(DatasetQueryMode.sql))
        ..add(const UpdateReadOnlyQueryEvent('DROP TABLE tbl_1'))
        ..add(const RunReadOnlyQueryEvent());

      final queryState = await bloc.stream.firstWhere(
        (state) =>
            state is DatasetLoadedState &&
            state.readOnlyQueryErrorCode ==
                ReadOnlySqlValidator.unsafeStatementCode,
      ) as DatasetLoadedState;

      expect(queryState.queryMode, DatasetQueryMode.sql);
      expect(queryState.isReadOnlyQueryRunning, isFalse);
      expect(queryState.readOnlyQueryRows, isEmpty);
    });

    test('LoadAnalyticsEvent transitions to DatasetAnalyticsLoadedState',
        () async {
      final dataset = _dataset();
      final column = _column();
      final suggestion = ChartSuggestion.none();
      const chartData = EmptyChartData();

      _mockWorkspaceLoad(
        openDataset: openDataset,
        schemaRepository: schemaRepository,
        fetchRows: fetchRows,
        dataset: dataset,
        tables: [_table(id: 10)],
        columns: [column],
        rows: [
          {'id': 1, 'product': 'book'},
        ],
      );
      when(() => analysisService.suggestAllCharts(any()))
          .thenReturn([suggestion]);
      when(() => applyFilters.buildWhereClause(any())).thenReturn(null);
      when(() => analysisService.loadChartData(
            tableName: any(named: 'tableName'),
            suggestion: any(named: 'suggestion'),
            whereClause: any(named: 'whereClause'),
            whereArguments: any(named: 'whereArguments'),
          )).thenAnswer((_) async => ChartLoadResult.success(chartData));

      bloc.add(const LoadDatasetEvent(1));
      await bloc.stream.firstWhere((s) => s is DatasetLoadedState);

      bloc.add(const LoadAnalyticsEvent());

      final analyticsLoaded = await bloc.stream.firstWhere(
        (s) =>
            s is DatasetLoadedState &&
            s.analyticsState is DatasetAnalyticsLoadedState,
      ) as DatasetLoadedState;

      final analytics =
          analyticsLoaded.analyticsState as DatasetAnalyticsLoadedState;
      expect(analytics.charts.length, 1);
      expect(analytics.charts.first.id, 'chart_0');
      expect(analytics.charts.first.suggestion, suggestion);
      expect(analytics.charts.first.chartData, chartData);
    });

    test('LoadAnalyticsEvent restores charts for the active sheet', () async {
      final dataset = _dataset(
        uiStateJson: '''
{
  "activeTableId": 10,
  "tableStates": {
    "10": {
      "charts": [
        {
          "id": "sheet_chart",
          "chartType": "bar",
          "xColumn": "product",
          "aggregation": "count"
        }
      ]
    }
  }
}
''',
      );
      final column = _column();
      const chartData = EmptyChartData();

      _mockWorkspaceLoad(
        openDataset: openDataset,
        schemaRepository: schemaRepository,
        fetchRows: fetchRows,
        dataset: dataset,
        tables: [_table(id: 10)],
        columns: [column],
        rows: [
          {'id': 1, 'product': 'book'},
        ],
      );
      when(() => applyFilters.buildWhereClause(any())).thenReturn(null);
      when(() => analysisService.loadChartData(
            tableName: any(named: 'tableName'),
            suggestion: any(named: 'suggestion'),
            whereClause: any(named: 'whereClause'),
            whereArguments: any(named: 'whereArguments'),
          )).thenAnswer((_) async => ChartLoadResult.success(chartData));

      bloc.add(const LoadDatasetEvent(1));
      await bloc.stream.firstWhere((s) => s is DatasetLoadedState);

      bloc.add(const LoadAnalyticsEvent());

      final analyticsLoaded = await bloc.stream.firstWhere(
        (s) =>
            s is DatasetLoadedState &&
            s.analyticsState is DatasetAnalyticsLoadedState,
      ) as DatasetLoadedState;

      final analytics =
          analyticsLoaded.analyticsState as DatasetAnalyticsLoadedState;
      expect(analytics.charts.single.id, 'sheet_chart');
      expect(analytics.charts.single.suggestion.chartType, ChartType.bar);
      expect(analytics.charts.single.suggestion.xColumn?.dbName, 'product');
      verifyNever(() => analysisService.suggestAllCharts(any()));
    });

    test('LoadAnalyticsEvent emits error state on failure', () async {
      final dataset = _dataset();
      final column = _column();

      _mockWorkspaceLoad(
        openDataset: openDataset,
        schemaRepository: schemaRepository,
        fetchRows: fetchRows,
        dataset: dataset,
        tables: [_table(id: 10)],
        columns: [column],
        rows: [
          {'id': 1, 'product': 'book'},
        ],
      );
      when(() => analysisService.suggestAllCharts(any()))
          .thenThrow(Exception('boom'));

      bloc.add(const LoadDatasetEvent(1));
      await bloc.stream.firstWhere((s) => s is DatasetLoadedState);

      bloc.add(const LoadAnalyticsEvent());

      final errorState = await bloc.stream.firstWhere(
        (s) =>
            s is DatasetLoadedState &&
            s.analyticsState is DatasetAnalyticsErrorState,
      ) as DatasetLoadedState;

      final analytics = errorState.analyticsState as DatasetAnalyticsErrorState;
      expect(analytics.code, 'analytics_failed');
    });

    test('UpdateChartConfigEvent reloads chart with new suggestion', () async {
      final dataset = _dataset();
      final column = _column();
      final initialSuggestion = ChartSuggestion.none();
      final newSuggestion = ChartSuggestion(
        chartType: ChartType.bar,
        xColumn: column,
      );
      const updatedChartData = EmptyChartData();

      _mockWorkspaceLoad(
        openDataset: openDataset,
        schemaRepository: schemaRepository,
        fetchRows: fetchRows,
        dataset: dataset,
        tables: [_table(id: 10)],
        columns: [column],
        rows: [
          {'id': 1, 'product': 'book'},
        ],
      );
      when(() => analysisService.suggestAllCharts(any()))
          .thenReturn([initialSuggestion]);
      when(() => applyFilters.buildWhereClause(any())).thenReturn(null);
      when(() => analysisService.loadChartData(
            tableName: any(named: 'tableName'),
            suggestion: any(named: 'suggestion'),
            whereClause: any(named: 'whereClause'),
            whereArguments: any(named: 'whereArguments'),
          )).thenAnswer((_) async => ChartLoadResult.success(updatedChartData));

      bloc.add(const LoadDatasetEvent(1));
      await bloc.stream.firstWhere((s) => s is DatasetLoadedState);

      bloc.add(const LoadAnalyticsEvent());
      await bloc.stream.firstWhere(
        (s) =>
            s is DatasetLoadedState &&
            s.analyticsState is DatasetAnalyticsLoadedState,
      );

      bloc.add(UpdateChartConfigEvent(
        chartId: 'chart_0',
        suggestion: newSuggestion,
      ));

      final updatedState = await bloc.stream.firstWhere(
        (s) {
          if (s is! DatasetLoadedState) return false;
          final a = s.analyticsState;
          if (a is! DatasetAnalyticsLoadedState) return false;
          return a.charts.any(
            (c) =>
                c.id == 'chart_0' &&
                c.suggestion == newSuggestion &&
                !c.isLoading,
          );
        },
      ) as DatasetLoadedState;

      final analytics =
          updatedState.analyticsState as DatasetAnalyticsLoadedState;
      final chart = analytics.charts.firstWhere((c) => c.id == 'chart_0');
      expect(chart.suggestion, newSuggestion);
      expect(chart.chartData, updatedChartData);
    });

    test('UpdateChartConfigEvent keeps previous chart visible while loading',
        () async {
      final dataset = _dataset();
      final column = _column();
      final initialSuggestion = ChartSuggestion(
        chartType: ChartType.bar,
        xColumn: column,
      );
      final newSuggestion = ChartSuggestion(
        chartType: ChartType.pie,
        xColumn: column,
      );
      const initialChartData = CategoryChartData(
        chartType: ChartType.bar,
        xLabel: 'product',
        yLabel: 'COUNT',
        points: [CategoryPoint(label: 'book', value: 1)],
        aggregationType: AggregationType.count,
      );
      const updatedChartData = CategoryChartData(
        chartType: ChartType.pie,
        xLabel: 'product',
        yLabel: 'COUNT',
        points: [CategoryPoint(label: 'pen', value: 1)],
        aggregationType: AggregationType.count,
      );
      final updateCompleter = Completer<ChartLoadResult>();
      var loadCount = 0;

      _mockWorkspaceLoad(
        openDataset: openDataset,
        schemaRepository: schemaRepository,
        fetchRows: fetchRows,
        dataset: dataset,
        tables: [_table(id: 10)],
        columns: [column],
        rows: [
          {'id': 1, 'product': 'book'},
        ],
      );
      when(() => analysisService.suggestAllCharts(any()))
          .thenReturn([initialSuggestion]);
      when(() => applyFilters.buildWhereClause(any())).thenReturn(null);
      when(() => analysisService.loadChartData(
            tableName: any(named: 'tableName'),
            suggestion: any(named: 'suggestion'),
            whereClause: any(named: 'whereClause'),
            whereArguments: any(named: 'whereArguments'),
          )).thenAnswer((_) {
        loadCount += 1;
        if (loadCount == 1) {
          return Future.value(ChartLoadResult.success(initialChartData));
        }
        return updateCompleter.future;
      });

      bloc.add(const LoadDatasetEvent(1));
      await bloc.stream.firstWhere((s) => s is DatasetLoadedState);

      bloc.add(const LoadAnalyticsEvent());
      await bloc.stream.firstWhere((s) {
        if (s is! DatasetLoadedState) return false;
        final analytics = s.analyticsState;
        if (analytics is! DatasetAnalyticsLoadedState) return false;
        return analytics.charts.single.chartData == initialChartData;
      });

      bloc.add(UpdateChartConfigEvent(
        chartId: 'chart_0',
        suggestion: newSuggestion,
      ));

      final loadingState = await bloc.stream.firstWhere((s) {
        if (s is! DatasetLoadedState) return false;
        final analytics = s.analyticsState;
        if (analytics is! DatasetAnalyticsLoadedState) return false;
        final chart = analytics.charts.single;
        return chart.suggestion == newSuggestion && chart.isLoading;
      }) as DatasetLoadedState;

      final loadingAnalytics =
          loadingState.analyticsState as DatasetAnalyticsLoadedState;
      final loadingChart = loadingAnalytics.charts.single;
      expect(loadingChart.chartData, initialChartData);
      expect(loadingChart.error, isNull);

      updateCompleter.complete(ChartLoadResult.success(updatedChartData));

      final updatedState = await bloc.stream.firstWhere((s) {
        if (s is! DatasetLoadedState) return false;
        final analytics = s.analyticsState;
        if (analytics is! DatasetAnalyticsLoadedState) return false;
        final chart = analytics.charts.single;
        return !chart.isLoading && chart.chartData == updatedChartData;
      }) as DatasetLoadedState;

      final updatedAnalytics =
          updatedState.analyticsState as DatasetAnalyticsLoadedState;
      expect(updatedAnalytics.charts.single.suggestion, newSuggestion);
    });

    test('UpdateChartConfigEvent ignores stale chart reload results', () async {
      final dataset = _dataset();
      final column = _column();
      final initialSuggestion = ChartSuggestion(
        chartType: ChartType.bar,
        xColumn: column,
      );
      final firstSuggestion = ChartSuggestion(
        chartType: ChartType.pie,
        xColumn: column,
      );
      final secondSuggestion = ChartSuggestion(
        chartType: ChartType.bar,
        xColumn: column,
        aggregationType: AggregationType.count,
      );
      const initialChartData = CategoryChartData(
        chartType: ChartType.bar,
        xLabel: 'product',
        yLabel: 'COUNT',
        points: [CategoryPoint(label: 'book', value: 1)],
        aggregationType: AggregationType.count,
      );
      const staleChartData = CategoryChartData(
        chartType: ChartType.pie,
        xLabel: 'product',
        yLabel: 'COUNT',
        points: [CategoryPoint(label: 'stale', value: 1)],
        aggregationType: AggregationType.count,
      );
      const currentChartData = CategoryChartData(
        chartType: ChartType.bar,
        xLabel: 'product',
        yLabel: 'COUNT',
        points: [CategoryPoint(label: 'current', value: 1)],
        aggregationType: AggregationType.count,
      );
      final firstUpdateCompleter = Completer<ChartLoadResult>();
      final secondUpdateCompleter = Completer<ChartLoadResult>();
      var loadCount = 0;

      _mockWorkspaceLoad(
        openDataset: openDataset,
        schemaRepository: schemaRepository,
        fetchRows: fetchRows,
        dataset: dataset,
        tables: [_table(id: 10)],
        columns: [column],
        rows: [
          {'id': 1, 'product': 'book'},
        ],
      );
      when(() => analysisService.suggestAllCharts(any()))
          .thenReturn([initialSuggestion]);
      when(() => applyFilters.buildWhereClause(any())).thenReturn(null);
      when(() => analysisService.loadChartData(
            tableName: any(named: 'tableName'),
            suggestion: any(named: 'suggestion'),
            whereClause: any(named: 'whereClause'),
            whereArguments: any(named: 'whereArguments'),
          )).thenAnswer((_) {
        loadCount += 1;
        return switch (loadCount) {
          1 => Future.value(ChartLoadResult.success(initialChartData)),
          2 => firstUpdateCompleter.future,
          _ => secondUpdateCompleter.future,
        };
      });

      bloc.add(const LoadDatasetEvent(1));
      await bloc.stream.firstWhere((s) => s is DatasetLoadedState);

      bloc.add(const LoadAnalyticsEvent());
      await bloc.stream.firstWhere((s) {
        if (s is! DatasetLoadedState) return false;
        final analytics = s.analyticsState;
        if (analytics is! DatasetAnalyticsLoadedState) return false;
        return analytics.charts.single.chartData == initialChartData;
      });

      bloc.add(UpdateChartConfigEvent(
        chartId: 'chart_0',
        suggestion: firstSuggestion,
      ));
      await bloc.stream.firstWhere((s) {
        if (s is! DatasetLoadedState) return false;
        final analytics = s.analyticsState;
        if (analytics is! DatasetAnalyticsLoadedState) return false;
        final chart = analytics.charts.single;
        return chart.suggestion == firstSuggestion && chart.isLoading;
      });

      bloc.add(UpdateChartConfigEvent(
        chartId: 'chart_0',
        suggestion: secondSuggestion,
      ));
      await bloc.stream.firstWhere((s) {
        if (s is! DatasetLoadedState) return false;
        final analytics = s.analyticsState;
        if (analytics is! DatasetAnalyticsLoadedState) return false;
        final chart = analytics.charts.single;
        return chart.suggestion == secondSuggestion && chart.isLoading;
      });

      secondUpdateCompleter.complete(ChartLoadResult.success(currentChartData));
      await bloc.stream.firstWhere((s) {
        if (s is! DatasetLoadedState) return false;
        final analytics = s.analyticsState;
        if (analytics is! DatasetAnalyticsLoadedState) return false;
        final chart = analytics.charts.single;
        return chart.suggestion == secondSuggestion &&
            chart.chartData == currentChartData &&
            !chart.isLoading;
      });

      firstUpdateCompleter.complete(ChartLoadResult.success(staleChartData));
      await Future<void>.delayed(Duration.zero);

      final latestState = bloc.state as DatasetLoadedState;
      final latestAnalytics =
          latestState.analyticsState as DatasetAnalyticsLoadedState;
      final latestChart = latestAnalytics.charts.single;
      expect(latestChart.suggestion, secondSuggestion);
      expect(latestChart.chartData, currentChartData);
      expect(latestChart.chartData, isNot(staleChartData));
    });

    test('RemoveChartEvent removes chart from loaded state', () async {
      final dataset = _dataset();
      final column = _column();
      final suggestion = ChartSuggestion.none();

      _mockWorkspaceLoad(
        openDataset: openDataset,
        schemaRepository: schemaRepository,
        fetchRows: fetchRows,
        dataset: dataset,
        tables: [_table(id: 10)],
        columns: [column],
        rows: [
          {'id': 1, 'product': 'book'},
        ],
      );
      when(() => analysisService.suggestAllCharts(any()))
          .thenReturn([suggestion]);
      when(() => applyFilters.buildWhereClause(any())).thenReturn(null);
      when(() => analysisService.loadChartData(
                tableName: any(named: 'tableName'),
                suggestion: any(named: 'suggestion'),
                whereClause: any(named: 'whereClause'),
                whereArguments: any(named: 'whereArguments'),
              ))
          .thenAnswer(
              (_) async => ChartLoadResult.success(const EmptyChartData()));

      bloc.add(const LoadDatasetEvent(1));
      await bloc.stream.firstWhere((s) => s is DatasetLoadedState);

      bloc.add(const LoadAnalyticsEvent());
      await bloc.stream.firstWhere(
        (s) =>
            s is DatasetLoadedState &&
            s.analyticsState is DatasetAnalyticsLoadedState,
      );

      bloc.add(const RemoveChartEvent('chart_0'));

      final afterRemove = await bloc.stream.firstWhere(
        (s) {
          if (s is! DatasetLoadedState) return false;
          final a = s.analyticsState;
          if (a is! DatasetAnalyticsLoadedState) return false;
          return a.charts.isEmpty;
        },
      ) as DatasetLoadedState;

      final analytics =
          afterRemove.analyticsState as DatasetAnalyticsLoadedState;
      expect(analytics.charts, isEmpty);
    });
  });
}

void _mockWorkspaceLoad({
  required MockOpenDatasetUseCase openDataset,
  required MockSchemaRepository schemaRepository,
  required MockFetchRowsUseCase fetchRows,
  required Dataset dataset,
  required List<DatasetTable> tables,
  required List<DatasetColumn> columns,
  required List<Map<String, dynamic>> rows,
}) {
  when(() => openDataset.call(dataset.id)).thenAnswer((_) async => dataset);
  when(() => schemaRepository.getTablesForDataset(dataset.id))
      .thenAnswer((_) async => tables);
  when(() => schemaRepository.getColumnsForTable(tables.first.id))
      .thenAnswer((_) async => columns);
  when(() => fetchRows.call(
        tableName: tables.first.sqlTableName,
        limit: DatasetBloc.defaultRowLimit,
        offset: 0,
      )).thenAnswer((_) async => rows);
}

Dataset _dataset({
  String? uiStateJson,
}) {
  return Dataset(
    id: 1,
    name: 'Sales',
    sourceFileName: 'sales.csv',
    createdAt: 1000,
    lastOpenedAt: 2000,
    uiStateJson: uiStateJson,
  );
}

DatasetTable _table({
  required int id,
  String name = 'Sheet1',
  String tableName = 'tbl_1',
  int rowCount = 1,
}) {
  return DatasetTable(
    id: id,
    datasetId: 1,
    sheetNameOriginal: name,
    sqlTableName: tableName,
    rowCount: rowCount,
    colCount: 1,
  );
}

DatasetColumn _column({
  int tableId = 10,
  String dbName = 'product',
}) {
  return DatasetColumn(
    id: 1,
    datasetTableId: tableId,
    originalName: dbName,
    dbName: dbName,
    declaredType: ColumnType.text,
    inferredType: ColumnType.text,
    nullable: true,
  );
}
