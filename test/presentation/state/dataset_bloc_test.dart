import 'package:exel_category/domain/entities/dataset.dart';
import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/entities/dataset_table.dart';
import 'package:exel_category/domain/repositories/schema_repository.dart';
import 'package:exel_category/domain/usecases/dataset/open_dataset_usecase.dart';
import 'package:exel_category/domain/usecases/query/fetch_rows_usecase.dart';
import 'package:exel_category/domain/value_objects/column_type.dart';
import 'package:exel_category/presentation/state/dataset_bloc.dart';
import 'package:exel_category/presentation/state/dataset_event.dart';
import 'package:exel_category/presentation/state/dataset_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockOpenDatasetUseCase extends Mock implements OpenDatasetUseCase {}

class MockSchemaRepository extends Mock implements SchemaRepository {}

class MockFetchRowsUseCase extends Mock implements FetchRowsUseCase {}

void main() {
  group('DatasetBloc', () {
    late MockOpenDatasetUseCase openDataset;
    late MockSchemaRepository schemaRepository;
    late MockFetchRowsUseCase fetchRows;
    late DatasetBloc bloc;

    setUp(() {
      openDataset = MockOpenDatasetUseCase();
      schemaRepository = MockSchemaRepository();
      fetchRows = MockFetchRowsUseCase();
      bloc = DatasetBloc(
        openDataset: openDataset,
        schemaRepository: schemaRepository,
        fetchRows: fetchRows,
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
      verifyNever(() => fetchRows.call(
            tableName: 'tbl_1',
            limit: DatasetBloc.defaultRowLimit,
            offset: 0,
          ));
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

Dataset _dataset() {
  return const Dataset(
    id: 1,
    name: 'Sales',
    sourceFileName: 'sales.csv',
    createdAt: 1000,
    lastOpenedAt: 2000,
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
