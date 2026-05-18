import 'package:exel_category/domain/entities/dataset.dart';
import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/entities/dataset_table.dart';
import 'package:exel_category/domain/repositories/schema_repository.dart';
import 'package:exel_category/domain/usecases/dataset/open_dataset_usecase.dart';
import 'package:exel_category/domain/usecases/dataset/update_dataset_ui_state_usecase.dart';
import 'package:exel_category/domain/usecases/query/apply_filters_usecase.dart';
import 'package:exel_category/domain/usecases/query/fetch_rows_usecase.dart';
import 'package:exel_category/domain/value_objects/dataset_filter.dart';
import 'package:exel_category/domain/value_objects/dataset_sort.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'dataset_event.dart';
import 'dataset_state.dart';
import 'dataset_workspace_ui_state.dart';

class DatasetBloc extends Bloc<DatasetEvent, DatasetState> {
  static const int defaultRowLimit = 100;

  final OpenDatasetUseCase _openDataset;
  final SchemaRepository _schemaRepository;
  final FetchRowsUseCase _fetchRows;
  final ApplyFiltersUseCase _applyFilters;
  final UpdateDatasetUiStateUseCase _updateDatasetUiState;

  DatasetBloc({
    required OpenDatasetUseCase openDataset,
    required SchemaRepository schemaRepository,
    required FetchRowsUseCase fetchRows,
    required ApplyFiltersUseCase applyFilters,
    required UpdateDatasetUiStateUseCase updateDatasetUiState,
  })  : _openDataset = openDataset,
        _schemaRepository = schemaRepository,
        _fetchRows = fetchRows,
        _applyFilters = applyFilters,
        _updateDatasetUiState = updateDatasetUiState,
        super(const DatasetInitialState()) {
    on<LoadDatasetEvent>(_onLoadDataset);
    on<ChangeSheetEvent>(_onChangeSheet);
    on<RefreshResultsEvent>(_onRefreshResults);
    on<ChangeViewModeEvent>(_onChangeViewMode);
    on<AddFilterEvent>(_onAddFilter);
    on<RemoveFilterEvent>(_onRemoveFilter);
    on<ClearFiltersEvent>(_onClearFilters);
    on<ChangeSortEvent>(_onChangeSort);
    on<ToggleSortColumnEvent>(_onToggleSortColumn);
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

      final workspaceState = DatasetWorkspaceUiState.fromJsonString(
        dataset.uiStateJson,
      );
      final activeTable = _activeTableFromUiState(
        tables: tables,
        activeTableId: workspaceState.activeTableId,
      );

      emit(await _loadTableState(
        dataset: dataset,
        tables: tables,
        activeTable: activeTable,
        viewMode: workspaceState.viewMode,
        filters: const [],
        sort: null,
        workspaceState: workspaceState,
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
      final nextState = await _loadTableState(
        dataset: currentState.dataset,
        tables: currentState.tables,
        activeTable: nextTable,
        viewMode: currentState.viewMode,
        filters: const [],
        sort: null,
      );

      emit(nextState);
      await _persistWorkspaceState(nextState);
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
        filters: currentState.filters,
        sort: currentState.sort,
      ));
    } catch (_) {
      emit(const DatasetErrorState('refresh_failed'));
    }
  }

  Future<void> _onChangeViewMode(
    ChangeViewModeEvent event,
    Emitter<DatasetState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DatasetLoadedState) return;

    final nextState = currentState.copyWith(viewMode: event.viewMode);
    emit(nextState);
    await _persistWorkspaceState(nextState);
  }

  Future<void> _onAddFilter(
    AddFilterEvent event,
    Emitter<DatasetState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DatasetLoadedState) return;

    final nextFilters = [
      for (final filter in currentState.filters)
        if (filter.effectiveId != event.filter.effectiveId) filter,
      event.filter,
    ];

    await _reloadCurrentTable(
      emit: emit,
      currentState: currentState,
      filters: nextFilters,
      sort: currentState.sort,
      errorCode: 'filter_failed',
    );
  }

  Future<void> _onRemoveFilter(
    RemoveFilterEvent event,
    Emitter<DatasetState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DatasetLoadedState) return;

    final nextFilters = [
      for (final filter in currentState.filters)
        if (filter.effectiveId != event.filterId) filter,
    ];

    await _reloadCurrentTable(
      emit: emit,
      currentState: currentState,
      filters: nextFilters,
      sort: currentState.sort,
      errorCode: 'filter_failed',
    );
  }

  Future<void> _onClearFilters(
    ClearFiltersEvent event,
    Emitter<DatasetState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DatasetLoadedState || currentState.filters.isEmpty) {
      return;
    }

    await _reloadCurrentTable(
      emit: emit,
      currentState: currentState,
      filters: const [],
      sort: currentState.sort,
      errorCode: 'filter_failed',
    );
  }

  Future<void> _onChangeSort(
    ChangeSortEvent event,
    Emitter<DatasetState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DatasetLoadedState) return;

    await _reloadCurrentTable(
      emit: emit,
      currentState: currentState,
      filters: currentState.filters,
      sort: event.sort,
      errorCode: 'sort_failed',
    );
  }

  Future<void> _onToggleSortColumn(
    ToggleSortColumnEvent event,
    Emitter<DatasetState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DatasetLoadedState) return;

    await _reloadCurrentTable(
      emit: emit,
      currentState: currentState,
      filters: currentState.filters,
      sort: _nextSort(currentState.sort, event.column),
      errorCode: 'sort_failed',
    );
  }

  Future<void> _reloadCurrentTable({
    required Emitter<DatasetState> emit,
    required DatasetLoadedState currentState,
    required List<DatasetFilter> filters,
    required DatasetSort? sort,
    required String errorCode,
  }) async {
    emit(const DatasetLoadingState());

    try {
      final rows = await _loadRows(
        tableName: currentState.activeTable.sqlTableName,
        filters: filters,
        sort: sort,
      );

      final nextState = currentState.copyWith(
        rows: _stripInternalColumns(rows),
        filters: filters,
        sort: sort,
      );

      emit(nextState);
      await _persistWorkspaceState(nextState);
    } catch (_) {
      emit(DatasetErrorState(errorCode));
    }
  }

  Future<DatasetLoadedState> _loadTableState({
    required Dataset dataset,
    required List<DatasetTable> tables,
    required DatasetTable activeTable,
    required DatasetViewMode viewMode,
    required List<DatasetFilter> filters,
    required DatasetSort? sort,
    DatasetWorkspaceUiState? workspaceState,
  }) async {
    final columns = await _schemaRepository.getColumnsForTable(activeTable.id);
    final activeFilters = workspaceState?.restoreFilters(columns) ?? filters;
    final activeSort = workspaceState?.restoreSort(columns) ?? sort;
    final rows = await _loadRows(
      tableName: activeTable.sqlTableName,
      filters: activeFilters,
      sort: activeSort,
    );

    return DatasetLoadedState(
      dataset: dataset,
      tables: tables,
      activeTable: activeTable,
      columns: columns,
      rows: _stripInternalColumns(rows),
      viewMode: viewMode,
      rowLimit: defaultRowLimit,
      filters: activeFilters,
      sort: activeSort,
    );
  }

  Future<List<Map<String, dynamic>>> _loadRows({
    required String tableName,
    required List<DatasetFilter> filters,
    required DatasetSort? sort,
  }) {
    if (filters.isEmpty && sort == null) {
      return _fetchRows.call(
        tableName: tableName,
        limit: defaultRowLimit,
        offset: 0,
      );
    }

    return _applyFilters.call(
      tableName: tableName,
      filters: filters,
      sort: sort,
      limit: defaultRowLimit,
      offset: 0,
    );
  }

  DatasetSort? _nextSort(
    DatasetSort? currentSort,
    DatasetColumn column,
  ) {
    if (currentSort == null || currentSort.column.dbName != column.dbName) {
      return DatasetSort(
        column: column,
        direction: SortDirection.ascending,
      );
    }

    if (currentSort.direction == SortDirection.ascending) {
      return DatasetSort(
        column: column,
        direction: SortDirection.descending,
      );
    }

    return null;
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

  DatasetTable _activeTableFromUiState({
    required List<DatasetTable> tables,
    required int? activeTableId,
  }) {
    if (activeTableId == null) {
      return tables.first;
    }

    for (final table in tables) {
      if (table.id == activeTableId) {
        return table;
      }
    }

    return tables.first;
  }

  Future<void> _persistWorkspaceState(DatasetLoadedState state) async {
    try {
      await _updateDatasetUiState.call(
        datasetId: state.dataset.id,
        uiStateJson: DatasetWorkspaceUiState.fromLoadedState(
          state,
        ).toJsonString(),
      );
    } catch (_) {
      // Workspace state persistence should never block row browsing.
    }
  }
}
