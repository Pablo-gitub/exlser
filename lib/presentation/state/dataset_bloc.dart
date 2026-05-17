import 'package:exel_category/domain/entities/dataset.dart';
import 'package:exel_category/domain/entities/dataset_table.dart';
import 'package:exel_category/domain/repositories/schema_repository.dart';
import 'package:exel_category/domain/usecases/dataset/open_dataset_usecase.dart';
import 'package:exel_category/domain/usecases/query/fetch_rows_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'dataset_event.dart';
import 'dataset_state.dart';

class DatasetBloc extends Bloc<DatasetEvent, DatasetState> {
  static const int defaultRowLimit = 100;

  final OpenDatasetUseCase _openDataset;
  final SchemaRepository _schemaRepository;
  final FetchRowsUseCase _fetchRows;

  DatasetBloc({
    required OpenDatasetUseCase openDataset,
    required SchemaRepository schemaRepository,
    required FetchRowsUseCase fetchRows,
  })  : _openDataset = openDataset,
        _schemaRepository = schemaRepository,
        _fetchRows = fetchRows,
        super(const DatasetInitialState()) {
    on<LoadDatasetEvent>(_onLoadDataset);
    on<ChangeSheetEvent>(_onChangeSheet);
    on<RefreshResultsEvent>(_onRefreshResults);
    on<ChangeViewModeEvent>(_onChangeViewMode);
  }

  Future<void> _onLoadDataset(
    LoadDatasetEvent event,
    Emitter<DatasetState> emit,
  ) async {
    emit(const DatasetLoadingState());

    try {
      final dataset = await _openDataset.call(event.datasetId);
      final tables = await _schemaRepository.getTablesForDataset(dataset.id);

      if (tables.isEmpty) {
        emit(DatasetEmptyState(dataset: dataset));
        return;
      }

      emit(await _loadTableState(
        dataset: dataset,
        tables: tables,
        activeTable: tables.first,
        viewMode: DatasetViewMode.table,
      ));
    } catch (_) {
      emit(const DatasetErrorState('load_failed'));
    }
  }

  Future<void> _onChangeSheet(
    ChangeSheetEvent event,
    Emitter<DatasetState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DatasetLoadedState) return;

    DatasetTable? nextTable;
    for (final table in currentState.tables) {
      if (table.id == event.tableId) {
        nextTable = table;
        break;
      }
    }
    if (nextTable == null || nextTable.id == currentState.activeTable.id) {
      return;
    }

    emit(const DatasetLoadingState());

    try {
      emit(await _loadTableState(
        dataset: currentState.dataset,
        tables: currentState.tables,
        activeTable: nextTable,
        viewMode: currentState.viewMode,
      ));
    } catch (_) {
      emit(const DatasetErrorState('sheet_failed'));
    }
  }

  Future<void> _onRefreshResults(
    RefreshResultsEvent event,
    Emitter<DatasetState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DatasetLoadedState) return;

    emit(const DatasetLoadingState());

    try {
      emit(await _loadTableState(
        dataset: currentState.dataset,
        tables: currentState.tables,
        activeTable: currentState.activeTable,
        viewMode: currentState.viewMode,
      ));
    } catch (_) {
      emit(const DatasetErrorState('refresh_failed'));
    }
  }

  void _onChangeViewMode(
    ChangeViewModeEvent event,
    Emitter<DatasetState> emit,
  ) {
    final currentState = state;
    if (currentState is! DatasetLoadedState) return;

    emit(currentState.copyWith(viewMode: event.viewMode));
  }

  Future<DatasetLoadedState> _loadTableState({
    required Dataset dataset,
    required List<DatasetTable> tables,
    required DatasetTable activeTable,
    required DatasetViewMode viewMode,
  }) async {
    final columns = await _schemaRepository.getColumnsForTable(activeTable.id);
    final rows = await _fetchRows.call(
      tableName: activeTable.sqlTableName,
      limit: defaultRowLimit,
      offset: 0,
    );

    return DatasetLoadedState(
      dataset: dataset,
      tables: tables,
      activeTable: activeTable,
      columns: columns,
      rows: _stripInternalColumns(rows),
      viewMode: viewMode,
      rowLimit: defaultRowLimit,
    );
  }

  List<Map<String, dynamic>> _stripInternalColumns(
    List<Map<String, dynamic>> rows,
  ) {
    return [
      for (final row in rows)
        {
          for (final entry in row.entries)
            if (entry.key != 'id') entry.key: entry.value,
        },
    ];
  }
}
