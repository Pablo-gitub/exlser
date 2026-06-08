import 'package:exlser/application/dto/chart_data.dart';
import 'package:exlser/domain/entities/chart_suggestion.dart';
import 'package:exlser/domain/entities/dataset.dart';
import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/entities/dataset_table.dart';
import 'package:exlser/domain/value_objects/dataset_filter.dart';
import 'package:exlser/domain/value_objects/dataset_query_mode.dart';
import 'package:exlser/domain/value_objects/dataset_read_query.dart';
import 'package:exlser/domain/value_objects/dataset_sort.dart';

enum DatasetViewMode {
  table,
  cards,
}

enum ChartLoadError {
  noNumericColumn,
  invalidAggregation,
  noRowsAfterFilter,
  chartTypeNotSupported,
  internalFailure,
}

class AnalyticsChart {
  final String id;
  final ChartSuggestion suggestion;
  final ChartData chartData;
  final bool isLoading;
  final ChartLoadError? error;

  const AnalyticsChart({
    required this.id,
    required this.suggestion,
    this.chartData = const EmptyChartData(),
    this.isLoading = false,
    this.error,
  });

  AnalyticsChart copyWith({
    ChartSuggestion? suggestion,
    ChartData? chartData,
    bool? isLoading,
    Object? error = _errorNotProvided,
  }) {
    return AnalyticsChart(
      id: id,
      suggestion: suggestion ?? this.suggestion,
      chartData: chartData ?? this.chartData,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _errorNotProvided)
          ? this.error
          : error as ChartLoadError?,
    );
  }
}

const Object _errorNotProvided = Object();

sealed class DatasetAnalyticsState {
  const DatasetAnalyticsState();
}

class DatasetAnalyticsIdleState extends DatasetAnalyticsState {
  const DatasetAnalyticsIdleState();
}

class DatasetAnalyticsLoadingState extends DatasetAnalyticsState {
  const DatasetAnalyticsLoadingState();
}

class DatasetAnalyticsLoadedState extends DatasetAnalyticsState {
  final List<AnalyticsChart> charts;

  const DatasetAnalyticsLoadedState({required this.charts});

  DatasetAnalyticsLoadedState copyWith({List<AnalyticsChart>? charts}) {
    return DatasetAnalyticsLoadedState(charts: charts ?? this.charts);
  }
}

class DatasetAnalyticsErrorState extends DatasetAnalyticsState {
  final String code;

  const DatasetAnalyticsErrorState(this.code);
}

sealed class DatasetState {
  const DatasetState();
}

class DatasetInitialState extends DatasetState {
  const DatasetInitialState();
}

class DatasetLoadingState extends DatasetState {
  const DatasetLoadingState();
}

class DatasetEmptyState extends DatasetState {
  final Dataset dataset;

  const DatasetEmptyState({
    required this.dataset,
  });
}

class DatasetLoadedState extends DatasetState {
  final Dataset dataset;
  final List<DatasetTable> tables;
  final DatasetTable activeTable;
  final List<DatasetColumn> columns;
  final Map<int, List<DatasetColumn>> columnsByTableId;
  final List<Map<String, dynamic>> rows;
  final DatasetViewMode viewMode;
  final int rowLimit;
  final int pageIndex;
  final int totalRowCount;
  final List<String> hiddenColumnDbNames;
  final List<DatasetFilter> filters;
  final DatasetSort? sort;
  final DatasetAnalyticsState analyticsState;
  final DatasetQueryMode queryMode;
  final DatasetReadQuery readOnlyQuery;
  final bool isReadOnlyQueryRunning;
  final bool hasReadOnlyQueryRun;
  final String? readOnlyQueryErrorCode;
  final List<DatasetColumn> readOnlyQueryColumns;
  final List<Map<String, dynamic>> readOnlyQueryRows;
  final int readOnlyQueryTotalRowCount;

  /// Currency symbols for numeric columns detected at import time.
  /// Key: column dbName, Value: symbol (e.g. "$", "€").
  final Map<String, String> columnCurrencySymbols;

  const DatasetLoadedState({
    required this.dataset,
    required this.tables,
    required this.activeTable,
    required this.columns,
    this.columnsByTableId = const {},
    required this.rows,
    required this.viewMode,
    required this.rowLimit,
    required this.pageIndex,
    required this.totalRowCount,
    this.hiddenColumnDbNames = const [],
    this.filters = const [],
    this.sort,
    this.analyticsState = const DatasetAnalyticsIdleState(),
    this.queryMode = DatasetQueryMode.filters,
    this.readOnlyQuery = const DatasetReadQuery(),
    this.isReadOnlyQueryRunning = false,
    this.hasReadOnlyQueryRun = false,
    this.readOnlyQueryErrorCode,
    this.readOnlyQueryColumns = const [],
    this.readOnlyQueryRows = const [],
    this.readOnlyQueryTotalRowCount = 0,
    this.columnCurrencySymbols = const {},
  });

  List<DatasetColumn> get visibleColumns => [
        for (final column in columns)
          if (!hiddenColumnDbNames.contains(column.dbName)) column,
      ];

  int get pageCount {
    if (totalRowCount <= 0) {
      return 0;
    }

    return ((totalRowCount - 1) ~/ rowLimit) + 1;
  }

  int get pageNumber => pageCount == 0 ? 0 : pageIndex + 1;

  bool get canGoToPreviousPage => pageIndex > 0;

  bool get canGoToNextPage => pageIndex + 1 < pageCount;

  bool get isReadOnlyQueryMode => queryMode == DatasetQueryMode.sql;

  DatasetLoadedState copyWith({
    Dataset? dataset,
    List<DatasetTable>? tables,
    DatasetTable? activeTable,
    List<DatasetColumn>? columns,
    Map<int, List<DatasetColumn>>? columnsByTableId,
    List<Map<String, dynamic>>? rows,
    DatasetViewMode? viewMode,
    int? rowLimit,
    int? pageIndex,
    int? totalRowCount,
    List<String>? hiddenColumnDbNames,
    List<DatasetFilter>? filters,
    Object? sort = _sortNotProvided,
    DatasetAnalyticsState? analyticsState,
    DatasetQueryMode? queryMode,
    DatasetReadQuery? readOnlyQuery,
    bool? isReadOnlyQueryRunning,
    bool? hasReadOnlyQueryRun,
    Object? readOnlyQueryErrorCode = _readOnlyQueryErrorNotProvided,
    List<DatasetColumn>? readOnlyQueryColumns,
    List<Map<String, dynamic>>? readOnlyQueryRows,
    int? readOnlyQueryTotalRowCount,
    Map<String, String>? columnCurrencySymbols,
  }) {
    return DatasetLoadedState(
      dataset: dataset ?? this.dataset,
      tables: tables ?? this.tables,
      activeTable: activeTable ?? this.activeTable,
      columns: columns ?? this.columns,
      columnsByTableId: columnsByTableId ?? this.columnsByTableId,
      rows: rows ?? this.rows,
      viewMode: viewMode ?? this.viewMode,
      rowLimit: rowLimit ?? this.rowLimit,
      pageIndex: pageIndex ?? this.pageIndex,
      totalRowCount: totalRowCount ?? this.totalRowCount,
      hiddenColumnDbNames: hiddenColumnDbNames ?? this.hiddenColumnDbNames,
      filters: filters ?? this.filters,
      sort:
          identical(sort, _sortNotProvided) ? this.sort : sort as DatasetSort?,
      analyticsState: analyticsState ?? this.analyticsState,
      queryMode: queryMode ?? this.queryMode,
      readOnlyQuery: readOnlyQuery ?? this.readOnlyQuery,
      isReadOnlyQueryRunning:
          isReadOnlyQueryRunning ?? this.isReadOnlyQueryRunning,
      hasReadOnlyQueryRun: hasReadOnlyQueryRun ?? this.hasReadOnlyQueryRun,
      readOnlyQueryErrorCode:
          identical(readOnlyQueryErrorCode, _readOnlyQueryErrorNotProvided)
              ? this.readOnlyQueryErrorCode
              : readOnlyQueryErrorCode as String?,
      readOnlyQueryColumns: readOnlyQueryColumns ?? this.readOnlyQueryColumns,
      readOnlyQueryRows: readOnlyQueryRows ?? this.readOnlyQueryRows,
      readOnlyQueryTotalRowCount:
          readOnlyQueryTotalRowCount ?? this.readOnlyQueryTotalRowCount,
      columnCurrencySymbols:
          columnCurrencySymbols ?? this.columnCurrencySymbols,
    );
  }
}

const Object _sortNotProvided = Object();
const Object _readOnlyQueryErrorNotProvided = Object();

class DatasetErrorState extends DatasetState {
  final String code;

  const DatasetErrorState(this.code);
}
