import 'package:exel_category/domain/entities/dataset.dart';
import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/entities/dataset_table.dart';
import 'package:exel_category/domain/repositories/schema_repository.dart';
import 'package:exel_category/domain/usecases/dataset/open_dataset_usecase.dart';
import 'package:exel_category/domain/usecases/dataset/update_dataset_ui_state_usecase.dart';
import 'package:exel_category/domain/usecases/query/apply_filters_usecase.dart';
import 'package:exel_category/domain/usecases/query/fetch_rows_usecase.dart';
import 'package:exel_category/domain/value_objects/column_type.dart';
import 'package:exel_category/domain/value_objects/dataset_filter.dart';
import 'package:exel_category/domain/value_objects/dataset_sort.dart';
import 'package:exel_category/domain/value_objects/filter_operator.dart';
import 'package:exel_category/presentation/state/dataset_bloc.dart';
import 'package:exel_category/presentation/state/dataset_event.dart';
import 'package:exel_category/presentation/state/dataset_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockOpenDatasetUseCase extends Mock implements OpenDatasetUseCase {}

class MockSchemaRepository extends Mock implements SchemaRepository {}

class MockFetchRowsUseCase extends Mock implements FetchRowsUseCase {}

class MockApplyFiltersUseCase extends Mock implements ApplyFiltersUseCase {}

class MockUpdateDatasetUiStateUseCase extends Mock
    implements UpdateDatasetUiStateUseCase {}

void main() {
  setUpAll(() {
    registerFallbackValue(<DatasetFilter>[]);
    registerFallbackValue(
      DatasetSort(
        column: _column(),
        direction: SortDirection.ascending,
      ),
    );
  });

  group('DatasetBloc', () {
    late MockOpenDatasetUseCase openDataset;
    late MockSchemaRepository schemaRepository;
    late MockFetchRowsUseCase fetchRows;
    late MockApplyFiltersUseCase applyFilters;
    late MockUpdateDatasetUiStateUseCase updateDatasetUiState;
    late DatasetBloc bloc;

    setUp(() {
      openDataset = MockOpenDatasetUseCase();
      schemaRepository = MockSchemaRepository();
      fetchRows = MockFetchRowsUseCase();
      applyFilters = MockApplyFiltersUseCase();
      updateDatasetUiState = MockUpdateDatasetUiStateUseCase();
      when(() => updateDatasetUiState.call(
            datasetId: any(named: 'datasetId'),
            uiStateJson: any(named: 'uiStateJson'),
          )).thenAnswer((_) async {});
      bloc = DatasetBloc(
        openDataset: openDataset,
        schemaRepository: schemaRepository,
        fetchRows: fetchRows,
        applyFilters: applyFilters,
        updateDatasetUiState: updateDatasetUiState,
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
  }
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
}) {
  return DatasetTable(
    id: id,
    datasetId: 1,
    sheetNameOriginal: name,
    sqlTableName: tableName,
    rowCount: 1,
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
