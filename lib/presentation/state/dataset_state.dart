import 'package:exel_category/application/dto/chart_data.dart';
import 'package:exel_category/domain/entities/chart_suggestion.dart';
import 'package:exel_category/domain/entities/dataset.dart';
import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/entities/dataset_table.dart';
import 'package:exel_category/domain/value_objects/dataset_filter.dart';
import 'package:exel_category/domain/value_objects/dataset_sort.dart';

enum DatasetViewMode {
  table,
  cards,
}

class AnalyticsChart {
  final String id;
  final ChartSuggestion suggestion;
  final ChartData chartData;
  final bool isLoading;

  const AnalyticsChart({
    required this.id,
    required this.suggestion,
    this.chartData = const EmptyChartData(),
    this.isLoading = false,
  });

  AnalyticsChart copyWith({
    ChartSuggestion? suggestion,
    ChartData? chartData,
    bool? isLoading,
  }) {
    return AnalyticsChart(
      id: id,
      suggestion: suggestion ?? this.suggestion,
      chartData: chartData ?? this.chartData,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

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
  final List<Map<String, dynamic>> rows;
  final DatasetViewMode viewMode;
  final int rowLimit;
  final List<DatasetFilter> filters;
  final DatasetSort? sort;
  final DatasetAnalyticsState analyticsState;

  const DatasetLoadedState({
    required this.dataset,
    required this.tables,
    required this.activeTable,
    required this.columns,
    required this.rows,
    required this.viewMode,
    required this.rowLimit,
    this.filters = const [],
    this.sort,
    this.analyticsState = const DatasetAnalyticsIdleState(),
  });

  DatasetLoadedState copyWith({
    Dataset? dataset,
    List<DatasetTable>? tables,
    DatasetTable? activeTable,
    List<DatasetColumn>? columns,
    List<Map<String, dynamic>>? rows,
    DatasetViewMode? viewMode,
    int? rowLimit,
    List<DatasetFilter>? filters,
    Object? sort = _sortNotProvided,
    DatasetAnalyticsState? analyticsState,
  }) {
    return DatasetLoadedState(
      dataset: dataset ?? this.dataset,
      tables: tables ?? this.tables,
      activeTable: activeTable ?? this.activeTable,
      columns: columns ?? this.columns,
      rows: rows ?? this.rows,
      viewMode: viewMode ?? this.viewMode,
      rowLimit: rowLimit ?? this.rowLimit,
      filters: filters ?? this.filters,
      sort:
          identical(sort, _sortNotProvided) ? this.sort : sort as DatasetSort?,
      analyticsState: analyticsState ?? this.analyticsState,
    );
  }
}

const Object _sortNotProvided = Object();

class DatasetErrorState extends DatasetState {
  final String code;

  const DatasetErrorState(this.code);
}
