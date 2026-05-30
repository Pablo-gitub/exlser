import 'package:exlser/application/dto/chart_load_result.dart';
import 'package:exlser/application/services/analysis_service.dart';
import 'package:exlser/domain/entities/dataset.dart';
import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/entities/dataset_table.dart';
import 'package:exlser/domain/entities/chart_suggestion.dart';
import 'package:exlser/domain/repositories/schema_repository.dart';
import 'package:exlser/domain/usecases/dataset/open_dataset_usecase.dart';
import 'package:exlser/domain/usecases/dataset/update_dataset_ui_state_usecase.dart';
import 'package:exlser/domain/usecases/query/apply_filters_usecase.dart';
import 'package:exlser/domain/usecases/query/execute_read_only_query_usecase.dart';
import 'package:exlser/domain/usecases/query/fetch_rows_usecase.dart';
import 'package:exlser/domain/usecases/query/read_only_sql_validator.dart';
import 'package:exlser/domain/value_objects/aggregation_type.dart';
import 'package:exlser/domain/value_objects/column_type.dart';
import 'package:exlser/domain/value_objects/dataset_filter.dart';
import 'package:exlser/domain/value_objects/dataset_query_mode.dart';
import 'package:exlser/domain/value_objects/dataset_read_query.dart';
import 'package:exlser/domain/value_objects/dataset_sort.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'dataset_event.dart';
import 'dataset_state.dart';
import 'dataset_workspace_ui_state.dart';

class DatasetBloc extends Bloc<DatasetEvent, DatasetState> {
  static const int defaultRowLimit = DatasetWorkspaceUiState.defaultRowLimit;

  final OpenDatasetUseCase _openDataset;
  final SchemaRepository _schemaRepository;
  final FetchRowsUseCase _fetchRows;
  final ApplyFiltersUseCase _applyFilters;
  final ExecuteReadOnlyQueryUseCase _executeReadOnlyQuery;
  final UpdateDatasetUiStateUseCase _updateDatasetUiState;
  final AnalysisService _analysisService;

  DatasetBloc({
    required OpenDatasetUseCase openDataset,
    required SchemaRepository schemaRepository,
    required FetchRowsUseCase fetchRows,
    required ApplyFiltersUseCase applyFilters,
    required ExecuteReadOnlyQueryUseCase executeReadOnlyQuery,
    required UpdateDatasetUiStateUseCase updateDatasetUiState,
    required AnalysisService analysisService,
  })  : _openDataset = openDataset,
        _schemaRepository = schemaRepository,
        _fetchRows = fetchRows,
        _applyFilters = applyFilters,
        _executeReadOnlyQuery = executeReadOnlyQuery,
        _updateDatasetUiState = updateDatasetUiState,
        _analysisService = analysisService,
        super(const DatasetInitialState()) {
    on<LoadDatasetEvent>(_onLoadDataset);
    on<ChangeSheetEvent>(_onChangeSheet);
    on<RefreshResultsEvent>(_onRefreshResults);
    on<ChangeViewModeEvent>(_onChangeViewMode);
    on<ChangeRowLimitEvent>(_onChangeRowLimit);
    on<ChangePageEvent>(_onChangePage);
    on<SetColumnHiddenEvent>(_onSetColumnHidden);
    on<AddFilterEvent>(_onAddFilter);
    on<RemoveFilterEvent>(_onRemoveFilter);
    on<ClearFiltersEvent>(_onClearFilters);
    on<ChangeSortEvent>(_onChangeSort);
    on<ToggleSortColumnEvent>(_onToggleSortColumn);
    on<ChangeQueryModeEvent>(_onChangeQueryMode);
    on<UpdateReadOnlyQueryEvent>(_onUpdateReadOnlyQuery);
    on<ChangeReadOnlyQueryLimitEvent>(_onChangeReadOnlyQueryLimit);
    on<RunReadOnlyQueryEvent>(_onRunReadOnlyQuery);
    on<ClearReadOnlyQueryEvent>(_onClearReadOnlyQuery);
    on<ResetReadOnlyQueryEvent>(_onResetReadOnlyQuery);
    on<LoadAnalyticsEvent>(_onLoadAnalytics);
    on<AddChartEvent>(_onAddChart);
    on<RemoveChartEvent>(_onRemoveChart);
    on<UpdateChartConfigEvent>(_onUpdateChartConfig);
  }

  Future<void> _onLoadDataset(
    LoadDatasetEvent event,
    Emitter<DatasetState> emit,
  ) async {
    emit(const DatasetLoadingState());

    try {
      final dataset = await _openDataset.call(event.datasetId);
      if (emit.isDone) return;

      final tables = await _schemaRepository.getTablesForDataset(dataset.id);
      if (emit.isDone) return;

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

      final loadedState = await _loadTableState(
        dataset: dataset,
        tables: tables,
        activeTable: activeTable,
        viewMode: workspaceState.viewMode,
        rowLimit: workspaceState.rowLimit,
        pageIndex: workspaceState.pageIndex,
        filters: const [],
        sort: null,
        workspaceState: workspaceState,
      );
      if (emit.isDone) return;

      emit(loadedState);
    } catch (_) {
      if (emit.isDone) return;
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
      final workspaceState = DatasetWorkspaceUiState.fromJsonString(
        currentState.dataset.uiStateJson,
      );
      final nextState = await _loadTableState(
        dataset: currentState.dataset,
        tables: currentState.tables,
        activeTable: nextTable,
        columnsByTableId: currentState.columnsByTableId,
        viewMode: currentState.viewMode,
        rowLimit: currentState.rowLimit,
        pageIndex: 0,
        filters: const [],
        sort: null,
        workspaceState: workspaceState,
      );
      if (emit.isDone) return;

      final persistedState = _attachWorkspaceStateJson(nextState);
      emit(persistedState);
      await _persistWorkspaceState(persistedState);
    } catch (_) {
      if (emit.isDone) return;
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
      final workspaceState = DatasetWorkspaceUiState.fromJsonString(
        currentState.dataset.uiStateJson,
      );
      final loadedState = await _loadTableState(
        dataset: currentState.dataset,
        tables: currentState.tables,
        activeTable: currentState.activeTable,
        columnsByTableId: currentState.columnsByTableId,
        viewMode: currentState.viewMode,
        rowLimit: currentState.rowLimit,
        pageIndex: currentState.pageIndex,
        filters: currentState.filters,
        sort: currentState.sort,
        workspaceState: workspaceState,
      );
      if (emit.isDone) return;

      emit(loadedState);
    } catch (_) {
      if (emit.isDone) return;
      emit(const DatasetErrorState('refresh_failed'));
    }
  }

  Future<void> _onChangeViewMode(
    ChangeViewModeEvent event,
    Emitter<DatasetState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DatasetLoadedState) return;

    final nextState = _attachWorkspaceStateJson(
      currentState.copyWith(viewMode: event.viewMode),
    );
    emit(nextState);
    await _persistWorkspaceState(nextState);
  }

  Future<void> _onChangeRowLimit(
    ChangeRowLimitEvent event,
    Emitter<DatasetState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DatasetLoadedState || event.rowLimit <= 0) {
      return;
    }

    await _reloadCurrentTable(
      emit: emit,
      currentState: currentState,
      filters: currentState.filters,
      sort: currentState.sort,
      rowLimit: event.rowLimit,
      pageIndex: 0,
      errorCode: 'pagination_failed',
    );
  }

  Future<void> _onChangePage(
    ChangePageEvent event,
    Emitter<DatasetState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DatasetLoadedState) return;

    await _reloadCurrentTable(
      emit: emit,
      currentState: currentState,
      filters: currentState.filters,
      sort: currentState.sort,
      rowLimit: currentState.rowLimit,
      pageIndex: event.pageIndex,
      errorCode: 'pagination_failed',
    );
  }

  Future<void> _onSetColumnHidden(
    SetColumnHiddenEvent event,
    Emitter<DatasetState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DatasetLoadedState) return;

    final knownColumn = currentState.columns.any(
      (column) => column.dbName == event.columnDbName,
    );
    if (!knownColumn) return;

    final hiddenColumns = currentState.hiddenColumnDbNames.toSet();

    if (event.hidden) {
      final visibleCount = currentState.columns
          .where((column) => !hiddenColumns.contains(column.dbName))
          .length;
      if (visibleCount <= 1) {
        return;
      }
      hiddenColumns.add(event.columnDbName);
    } else {
      hiddenColumns.remove(event.columnDbName);
    }

    final nextState = _attachWorkspaceStateJson(
      currentState.copyWith(
        hiddenColumnDbNames: hiddenColumns.toList(),
      ),
    );
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
      rowLimit: currentState.rowLimit,
      pageIndex: 0,
      reloadAnalytics: true,
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
      rowLimit: currentState.rowLimit,
      pageIndex: 0,
      reloadAnalytics: true,
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
      rowLimit: currentState.rowLimit,
      pageIndex: 0,
      reloadAnalytics: true,
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
      rowLimit: currentState.rowLimit,
      pageIndex: currentState.pageIndex,
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
      rowLimit: currentState.rowLimit,
      pageIndex: currentState.pageIndex,
      errorCode: 'sort_failed',
    );
  }

  Future<void> _onChangeQueryMode(
    ChangeQueryModeEvent event,
    Emitter<DatasetState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DatasetLoadedState) return;

    final nextState = _attachWorkspaceStateJson(
      currentState.copyWith(
        queryMode: event.mode,
        readOnlyQueryErrorCode: null,
        analyticsState: const DatasetAnalyticsIdleState(),
      ),
    );
    emit(nextState);
    await _persistWorkspaceState(nextState);
  }

  Future<void> _onUpdateReadOnlyQuery(
    UpdateReadOnlyQueryEvent event,
    Emitter<DatasetState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DatasetLoadedState) return;

    emit(currentState.copyWith(
      readOnlyQuery: currentState.readOnlyQuery.copyWith(sql: event.sql),
      hasReadOnlyQueryRun: false,
      readOnlyQueryErrorCode: null,
      readOnlyQueryRows: const [],
      readOnlyQueryColumns: const [],
      readOnlyQueryTotalRowCount: 0,
      analyticsState: const DatasetAnalyticsIdleState(),
    ));
  }

  Future<void> _onChangeReadOnlyQueryLimit(
    ChangeReadOnlyQueryLimitEvent event,
    Emitter<DatasetState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DatasetLoadedState || event.limit <= 0) return;

    emit(currentState.copyWith(
      readOnlyQuery: currentState.readOnlyQuery.copyWith(limit: event.limit),
      hasReadOnlyQueryRun: false,
      readOnlyQueryErrorCode: null,
      readOnlyQueryRows: const [],
      readOnlyQueryColumns: const [],
      readOnlyQueryTotalRowCount: 0,
      analyticsState: const DatasetAnalyticsIdleState(),
    ));
  }

  Future<void> _onRunReadOnlyQuery(
    RunReadOnlyQueryEvent event,
    Emitter<DatasetState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DatasetLoadedState) return;

    emit(currentState.copyWith(
      queryMode: DatasetQueryMode.sql,
      isReadOnlyQueryRunning: true,
      readOnlyQueryErrorCode: null,
    ));

    try {
      final result = await _executeReadOnlyQuery.call(
        sql: currentState.readOnlyQuery.sql,
        activeTableName: currentState.activeTable.sqlTableName,
        allowedTableNames: {
          for (final table in currentState.tables) table.sqlTableName,
        },
        limit: currentState.readOnlyQuery.limit,
      );
      if (emit.isDone) return;

      final rows = _stripInternalColumns(result.rows);

      final latestState = state;
      if (latestState is! DatasetLoadedState) return;
      if (latestState.activeTable.id != currentState.activeTable.id) return;

      final nextState = _attachWorkspaceStateJson(
        latestState.copyWith(
          queryMode: DatasetQueryMode.sql,
          isReadOnlyQueryRunning: false,
          hasReadOnlyQueryRun: true,
          readOnlyQueryErrorCode: null,
          readOnlyQueryRows: rows,
          readOnlyQueryColumns: _queryColumnsFromRows(
            rows,
            tableId: currentState.activeTable.id,
          ),
          readOnlyQueryTotalRowCount: result.rowCount,
          analyticsState: const DatasetAnalyticsIdleState(),
        ),
      );
      emit(nextState);
      await _persistWorkspaceState(nextState);
    } on ReadOnlyQueryException catch (error) {
      if (emit.isDone) return;

      final latestState = state;
      if (latestState is! DatasetLoadedState) return;

      emit(latestState.copyWith(
        queryMode: DatasetQueryMode.sql,
        isReadOnlyQueryRunning: false,
        hasReadOnlyQueryRun: true,
        readOnlyQueryErrorCode: error.code,
        readOnlyQueryTotalRowCount: 0,
        analyticsState: const DatasetAnalyticsIdleState(),
      ));
    } catch (_) {
      if (emit.isDone) return;

      final latestState = state;
      if (latestState is! DatasetLoadedState) return;

      emit(latestState.copyWith(
        queryMode: DatasetQueryMode.sql,
        isReadOnlyQueryRunning: false,
        hasReadOnlyQueryRun: true,
        readOnlyQueryErrorCode: 'execution_failed',
        readOnlyQueryTotalRowCount: 0,
        analyticsState: const DatasetAnalyticsIdleState(),
      ));
    }
  }

  Future<void> _onClearReadOnlyQuery(
    ClearReadOnlyQueryEvent event,
    Emitter<DatasetState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DatasetLoadedState) return;

    final nextState = _attachWorkspaceStateJson(
      currentState.copyWith(
        readOnlyQuery: currentState.readOnlyQuery.copyWith(sql: ''),
        hasReadOnlyQueryRun: false,
        readOnlyQueryErrorCode: null,
        readOnlyQueryRows: const [],
        readOnlyQueryColumns: const [],
        readOnlyQueryTotalRowCount: 0,
        analyticsState: const DatasetAnalyticsIdleState(),
      ),
    );
    emit(nextState);
    await _persistWorkspaceState(nextState);
  }

  Future<void> _onResetReadOnlyQuery(
    ResetReadOnlyQueryEvent event,
    Emitter<DatasetState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DatasetLoadedState) return;

    final nextState = _attachWorkspaceStateJson(
      currentState.copyWith(
        readOnlyQuery: const DatasetReadQuery(),
        hasReadOnlyQueryRun: false,
        readOnlyQueryErrorCode: null,
        readOnlyQueryRows: const [],
        readOnlyQueryColumns: const [],
        readOnlyQueryTotalRowCount: 0,
        analyticsState: const DatasetAnalyticsIdleState(),
      ),
    );
    emit(nextState);
    await _persistWorkspaceState(nextState);
  }

  Future<void> _reloadCurrentTable({
    required Emitter<DatasetState> emit,
    required DatasetLoadedState currentState,
    required List<DatasetFilter> filters,
    required DatasetSort? sort,
    required int rowLimit,
    required int pageIndex,
    bool reloadAnalytics = false,
    required String errorCode,
  }) async {
    emit(const DatasetLoadingState());

    try {
      final totalRowCount = await _countRows(
        activeTable: currentState.activeTable,
        filters: filters,
      );
      if (emit.isDone) return;

      final safePageIndex = _safePageIndex(
        requestedPageIndex: pageIndex,
        totalRowCount: totalRowCount,
        rowLimit: rowLimit,
      );
      final rows = await _loadRows(
        tableName: currentState.activeTable.sqlTableName,
        filters: filters,
        sort: sort,
        rowLimit: rowLimit,
        pageIndex: safePageIndex,
      );
      if (emit.isDone) return;

      final loadedAnalyticsState = reloadAnalytics &&
              currentState.analyticsState is DatasetAnalyticsLoadedState
          ? currentState.analyticsState as DatasetAnalyticsLoadedState
          : null;

      final nextState = currentState.copyWith(
        rows: _stripInternalColumns(rows),
        rowLimit: rowLimit,
        pageIndex: safePageIndex,
        totalRowCount: totalRowCount,
        filters: filters,
        sort: sort,
        analyticsState: loadedAnalyticsState != null
            ? const DatasetAnalyticsLoadingState()
            : currentState.analyticsState,
      );

      if (loadedAnalyticsState == null) {
        final persistedState = _attachWorkspaceStateJson(nextState);
        emit(persistedState);
        await _persistWorkspaceState(persistedState);
        return;
      }

      emit(nextState);

      final reloadedState = await _loadAnalyticsForState(
        nextState,
        charts: loadedAnalyticsState.charts,
      );
      if (emit.isDone) return;

      final persistedState = _attachWorkspaceStateJson(reloadedState);
      emit(persistedState);
      await _persistWorkspaceState(persistedState);
    } catch (_) {
      if (emit.isDone) return;
      emit(DatasetErrorState(errorCode));
    }
  }

  Future<DatasetLoadedState> _loadTableState({
    required Dataset dataset,
    required List<DatasetTable> tables,
    required DatasetTable activeTable,
    Map<int, List<DatasetColumn>>? columnsByTableId,
    required DatasetViewMode viewMode,
    required int rowLimit,
    required int pageIndex,
    required List<DatasetFilter> filters,
    required DatasetSort? sort,
    DatasetWorkspaceUiState? workspaceState,
  }) async {
    final cachedColumnsByTableId = columnsByTableId ?? const {};
    final columns = cachedColumnsByTableId[activeTable.id] ??
        await _schemaRepository.getColumnsForTable(activeTable.id);
    final allColumnsByTableId = cachedColumnsByTableId.isEmpty
        ? await _loadColumnsByTableId(
            tables: tables,
            activeTable: activeTable,
            activeColumns: columns,
          )
        : {
            ...cachedColumnsByTableId,
            activeTable.id: columns,
          };
    final activeFilters =
        workspaceState?.restoreFilters(columns, tableId: activeTable.id) ??
            filters;
    final activeSort =
        workspaceState?.restoreSort(columns, tableId: activeTable.id) ?? sort;
    final hiddenColumnDbNames = workspaceState?.restoreHiddenColumnDbNames(
          columns,
          tableId: activeTable.id,
        ) ??
        const <String>[];
    final totalRowCount = await _countRows(
      activeTable: activeTable,
      filters: activeFilters,
    );
    final safePageIndex = _safePageIndex(
      requestedPageIndex: pageIndex,
      totalRowCount: totalRowCount,
      rowLimit: rowLimit,
    );
    final rows = await _loadRows(
      tableName: activeTable.sqlTableName,
      filters: activeFilters,
      sort: activeSort,
      rowLimit: rowLimit,
      pageIndex: safePageIndex,
    );

    final restoredQueryMode = workspaceState?.restoreQueryMode(
          tableId: activeTable.id,
        ) ??
        DatasetQueryMode.filters;
    final restoredReadOnlyQuery = workspaceState?.restoreReadOnlyQuery(
          tableId: activeTable.id,
        ) ??
        const DatasetReadQuery();

    return DatasetLoadedState(
      dataset: dataset,
      tables: tables,
      activeTable: activeTable,
      columns: columns,
      columnsByTableId: allColumnsByTableId,
      rows: _stripInternalColumns(rows),
      viewMode: viewMode,
      rowLimit: rowLimit,
      pageIndex: safePageIndex,
      totalRowCount: totalRowCount,
      hiddenColumnDbNames: hiddenColumnDbNames,
      filters: activeFilters,
      sort: activeSort,
      queryMode: restoredQueryMode,
      readOnlyQuery: restoredReadOnlyQuery,
    );
  }

  Future<Map<int, List<DatasetColumn>>> _loadColumnsByTableId({
    required List<DatasetTable> tables,
    required DatasetTable activeTable,
    required List<DatasetColumn> activeColumns,
  }) async {
    final columnsByTableId = <int, List<DatasetColumn>>{
      activeTable.id: activeColumns,
    };

    for (final table in tables) {
      if (table.id == activeTable.id) {
        continue;
      }

      try {
        columnsByTableId[table.id] =
            await _schemaRepository.getColumnsForTable(table.id);
      } catch (_) {
        columnsByTableId[table.id] = const [];
      }
    }

    return columnsByTableId;
  }

  Future<List<Map<String, dynamic>>> _loadRows({
    required String tableName,
    required List<DatasetFilter> filters,
    required DatasetSort? sort,
    required int rowLimit,
    required int pageIndex,
  }) {
    final offset = pageIndex * rowLimit;

    if (filters.isEmpty && sort == null) {
      return _fetchRows.call(
        tableName: tableName,
        limit: rowLimit,
        offset: offset,
      );
    }

    return _applyFilters.call(
      tableName: tableName,
      filters: filters,
      sort: sort,
      limit: rowLimit,
      offset: offset,
    );
  }

  Future<int> _countRows({
    required DatasetTable activeTable,
    required List<DatasetFilter> filters,
  }) {
    if (filters.isEmpty) {
      return Future.value(activeTable.rowCount);
    }

    return _applyFilters.countRows(
      tableName: activeTable.sqlTableName,
      filters: filters,
    );
  }

  int _safePageIndex({
    required int requestedPageIndex,
    required int totalRowCount,
    required int rowLimit,
  }) {
    if (requestedPageIndex <= 0 || totalRowCount <= 0) {
      return 0;
    }

    final lastPageIndex = (totalRowCount - 1) ~/ rowLimit;
    if (requestedPageIndex > lastPageIndex) {
      return lastPageIndex;
    }

    return requestedPageIndex;
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

  List<DatasetColumn> _queryColumnsFromRows(
    List<Map<String, dynamic>> rows, {
    required int tableId,
  }) {
    if (rows.isEmpty) {
      return const [];
    }

    final columnNames = rows.fold<Set<String>>(
      <String>{},
      (names, row) => names..addAll(row.keys),
    ).toList();

    return [
      for (int i = 0; i < columnNames.length; i++)
        DatasetColumn(
          id: -i - 1,
          datasetTableId: tableId,
          originalName: columnNames[i],
          dbName: columnNames[i],
          declaredType: _inferQueryColumnType(
            rows.map((row) => row[columnNames[i]]),
          ),
          inferredType: _inferQueryColumnType(
            rows.map((row) => row[columnNames[i]]),
          ),
          nullable: rows.any((row) => row[columnNames[i]] == null),
        ),
    ];
  }

  ColumnType _inferQueryColumnType(Iterable<dynamic> values) {
    for (final value in values) {
      if (value == null) continue;
      if (value is bool) return ColumnType.boolean;
      if (value is int) return ColumnType.integer;
      if (value is num) return ColumnType.real;
      if (value is DateTime) return ColumnType.date;
      if (value is String && DateTime.tryParse(value) != null) {
        return ColumnType.date;
      }
    }

    return ColumnType.text;
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

  DatasetLoadedState _attachWorkspaceStateJson(DatasetLoadedState state) {
    final uiStateJson = DatasetWorkspaceUiState.fromLoadedState(
      state,
    ).toJsonString();

    return state.copyWith(
      dataset: state.dataset.copyWith(uiStateJson: uiStateJson),
    );
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

  List<DatasetColumn> _analyticsColumns(DatasetLoadedState state) {
    return state.isReadOnlyQueryMode
        ? state.readOnlyQueryColumns
        : state.columns;
  }

  Future<ChartLoadResult> _loadChartDataForState(
    DatasetLoadedState state,
    ChartSuggestion suggestion,
  ) {
    if (state.isReadOnlyQueryMode) {
      return _analysisService.loadChartDataFromRows(
        rows: state.readOnlyQueryRows,
        suggestion: suggestion,
      );
    }

    final whereClause = _applyFilters.buildWhereClause(state.filters);
    return _analysisService.loadChartData(
      tableName: state.activeTable.sqlTableName,
      suggestion: suggestion,
      whereClause: whereClause?.sql,
      whereArguments: whereClause?.arguments,
    );
  }

  Future<DatasetLoadedState> _loadAnalyticsForState(
    DatasetLoadedState currentState, {
    List<AnalyticsChart>? charts,
  }) async {
    try {
      List<String> ids;
      List<ChartSuggestion> suggestions;

      if (charts != null) {
        ids = [for (final chart in charts) chart.id];
        suggestions = [for (final chart in charts) chart.suggestion];
      } else {
        var workspaceState = DatasetWorkspaceUiState.fromJsonString(
          currentState.dataset.uiStateJson,
        );

        // Migrate global charts to per-table if needed (backward compatibility)
        // This handles datasets created with old code that stored charts globally
        workspaceState = workspaceState.migrateGlobalChartsToPerTable(
          activeTableId: currentState.activeTable.id,
        );

        final storedCharts = currentState.isReadOnlyQueryMode
            ? workspaceState.restoreQueryCharts(
                tableId: currentState.activeTable.id,
              )
            : workspaceState.restoreCharts(
                tableId: currentState.activeTable.id,
              );

        if (storedCharts.isNotEmpty) {
          final restored = [
            for (final stored in storedCharts)
              (
                stored.id,
                stored.toChartSuggestion(_analyticsColumns(currentState))
              ),
          ].where((pair) => pair.$2 != null).toList();
          ids = [for (final p in restored) p.$1];
          suggestions = [for (final p in restored) p.$2!];
        } else {
          suggestions = _analysisService
              .suggestAllCharts(_analyticsColumns(currentState));
          ids = List.generate(suggestions.length, (i) => 'chart_$i');
        }
      }

      final chartsResults = await Future.wait([
        for (final suggestion in suggestions)
          _loadChartDataForState(currentState, suggestion),
      ]);

      final loadedCharts = [
        for (int i = 0; i < suggestions.length; i++)
          AnalyticsChart(
            id: ids[i],
            suggestion: suggestions[i],
            chartData: chartsResults[i].data,
            error: chartsResults[i].error,
          ),
      ];

      return currentState.copyWith(
        analyticsState: DatasetAnalyticsLoadedState(charts: loadedCharts),
      );
    } catch (_) {
      return currentState.copyWith(
        analyticsState: const DatasetAnalyticsErrorState('analytics_failed'),
      );
    }
  }

  Future<void> _onLoadAnalytics(
    LoadAnalyticsEvent event,
    Emitter<DatasetState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DatasetLoadedState) return;

    emit(currentState.copyWith(
      analyticsState: const DatasetAnalyticsLoadingState(),
    ));

    final loadedState = await _loadAnalyticsForState(currentState);
    if (emit.isDone) return;

    final latestState = state;
    if (latestState is! DatasetLoadedState) return;
    if (latestState.activeTable.id != currentState.activeTable.id) return;

    try {
      final nextState = _attachWorkspaceStateJson(loadedState);
      emit(nextState);
      if (nextState.analyticsState is DatasetAnalyticsLoadedState) {
        await _persistWorkspaceState(nextState);
      }
    } catch (_) {
      if (emit.isDone) return;
      emit(loadedState.copyWith(
        analyticsState: const DatasetAnalyticsErrorState('analytics_failed'),
      ));
    }
  }

  Future<void> _onAddChart(
    AddChartEvent event,
    Emitter<DatasetState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DatasetLoadedState) return;
    final analyticsState = currentState.analyticsState;
    if (analyticsState is! DatasetAnalyticsLoadedState) return;

    final analyticsColumns = _analyticsColumns(currentState);
    final validXCols = analyticsColumns
        .where(
          (c) => event.chartType.validXColumnTypes.contains(c.declaredType),
        )
        .toList();
    if (validXCols.isEmpty) return;

    final validYCols = analyticsColumns.where((c) => c.isNumeric).toList();

    final suggestion = ChartSuggestion(
      chartType: event.chartType,
      xColumn: validXCols.first,
      yColumn: validYCols.isNotEmpty ? validYCols.first : null,
      aggregationType: AggregationType.count,
    );

    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final newChart =
        AnalyticsChart(id: id, suggestion: suggestion, isLoading: true);

    emit(currentState.copyWith(
      analyticsState: analyticsState.copyWith(
        charts: [...analyticsState.charts, newChart],
      ),
    ));

    try {
      final result = await _loadChartDataForState(currentState, suggestion);
      if (emit.isDone) return;

      final latest = state;
      if (latest is! DatasetLoadedState) return;
      final latestAnalytics = latest.analyticsState;
      if (latestAnalytics is! DatasetAnalyticsLoadedState) return;

      final loadedCharts = [
        for (final c in latestAnalytics.charts)
          if (c.id == id)
            c.copyWith(
              chartData: result.data,
              isLoading: false,
              error: result.error,
            )
          else
            c,
      ];
      final nextState = latest.copyWith(
        analyticsState: latestAnalytics.copyWith(charts: loadedCharts),
      );
      final persistedState = _attachWorkspaceStateJson(nextState);
      emit(persistedState);
      await _persistWorkspaceState(persistedState);
    } catch (_) {
      if (emit.isDone) return;

      final latest = state;
      if (latest is! DatasetLoadedState) return;
      final latestAnalytics = latest.analyticsState;
      if (latestAnalytics is! DatasetAnalyticsLoadedState) return;

      final errorCharts = [
        for (final c in latestAnalytics.charts)
          if (c.id == id)
            c.copyWith(isLoading: false, error: ChartLoadError.internalFailure)
          else
            c,
      ];
      final nextState = _attachWorkspaceStateJson(latest.copyWith(
        analyticsState: latestAnalytics.copyWith(charts: errorCharts),
      ));
      emit(nextState);
      await _persistWorkspaceState(nextState);
    }
  }

  Future<void> _onRemoveChart(
    RemoveChartEvent event,
    Emitter<DatasetState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DatasetLoadedState) return;
    final analyticsState = currentState.analyticsState;
    if (analyticsState is! DatasetAnalyticsLoadedState) return;

    final remaining = [
      for (final c in analyticsState.charts)
        if (c.id != event.chartId) c,
    ];
    final nextState = currentState.copyWith(
      analyticsState: analyticsState.copyWith(charts: remaining),
    );
    final persistedState = _attachWorkspaceStateJson(nextState);
    emit(persistedState);
    await _persistWorkspaceState(persistedState);
  }

  Future<void> _onUpdateChartConfig(
    UpdateChartConfigEvent event,
    Emitter<DatasetState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DatasetLoadedState) return;
    final analyticsState = currentState.analyticsState;
    if (analyticsState is! DatasetAnalyticsLoadedState) return;

    final loadingCharts = [
      for (final c in analyticsState.charts)
        if (c.id == event.chartId)
          c.copyWith(
            suggestion: event.suggestion,
            isLoading: true,
            error: null,
          )
        else
          c,
    ];
    emit(currentState.copyWith(
      analyticsState: analyticsState.copyWith(charts: loadingCharts),
    ));

    try {
      final result =
          await _loadChartDataForState(currentState, event.suggestion);
      if (emit.isDone) return;

      final latest = state;
      if (latest is! DatasetLoadedState) return;
      final latestAnalytics = latest.analyticsState;
      if (latestAnalytics is! DatasetAnalyticsLoadedState) return;
      final latestChart = _findAnalyticsChart(
        latestAnalytics.charts,
        event.chartId,
      );
      if (latestChart == null ||
          !_isSameChartSuggestion(latestChart.suggestion, event.suggestion)) {
        return;
      }

      final loadedCharts = [
        for (final c in latestAnalytics.charts)
          if (c.id == event.chartId)
            c.copyWith(
              suggestion: event.suggestion,
              chartData: result.data,
              isLoading: false,
              error: result.error,
            )
          else
            c,
      ];
      final nextState = latest.copyWith(
        analyticsState: latestAnalytics.copyWith(charts: loadedCharts),
      );
      final persistedState = _attachWorkspaceStateJson(nextState);
      emit(persistedState);
      await _persistWorkspaceState(persistedState);
    } catch (_) {
      if (emit.isDone) return;

      final latest = state;
      if (latest is! DatasetLoadedState) return;
      final latestAnalytics = latest.analyticsState;
      if (latestAnalytics is! DatasetAnalyticsLoadedState) return;
      final latestChart = _findAnalyticsChart(
        latestAnalytics.charts,
        event.chartId,
      );
      if (latestChart == null ||
          !_isSameChartSuggestion(latestChart.suggestion, event.suggestion)) {
        return;
      }

      final errorCharts = [
        for (final c in latestAnalytics.charts)
          if (c.id == event.chartId)
            c.copyWith(isLoading: false, error: ChartLoadError.internalFailure)
          else
            c,
      ];
      final nextState = _attachWorkspaceStateJson(latest.copyWith(
        analyticsState: latestAnalytics.copyWith(charts: errorCharts),
      ));
      emit(nextState);
      await _persistWorkspaceState(nextState);
    }
  }
}

AnalyticsChart? _findAnalyticsChart(
  List<AnalyticsChart> charts,
  String chartId,
) {
  for (final chart in charts) {
    if (chart.id == chartId) return chart;
  }

  return null;
}

bool _isSameChartSuggestion(
  ChartSuggestion first,
  ChartSuggestion second,
) {
  return first.chartType == second.chartType &&
      first.aggregationType == second.aggregationType &&
      _isSameChartColumn(first.xColumn, second.xColumn) &&
      _isSameChartColumn(first.yColumn, second.yColumn) &&
      _isSameChartColumn(first.groupColumn, second.groupColumn);
}

bool _isSameChartColumn(
  DatasetColumn? first,
  DatasetColumn? second,
) {
  return first?.dbName == second?.dbName;
}
