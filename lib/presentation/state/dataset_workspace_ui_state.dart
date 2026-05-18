import 'dart:convert';

import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/entities/chart_suggestion.dart';
import 'package:exel_category/domain/value_objects/aggregation_type.dart';
import 'package:exel_category/domain/value_objects/chart_type.dart';
import 'package:exel_category/domain/value_objects/dataset_filter.dart';
import 'package:exel_category/domain/value_objects/dataset_sort.dart';
import 'package:exel_category/domain/value_objects/filter_operator.dart';

import 'dataset_state.dart';

class DatasetWorkspaceUiState {
  static const int defaultRowLimit = 100;

  final int? activeTableId;
  final DatasetViewMode viewMode;
  final int rowLimit;
  final int pageIndex;
  final List<StoredDatasetFilter> filters;
  final StoredDatasetSort? sort;
  final List<StoredAnalyticsChart> charts;

  const DatasetWorkspaceUiState({
    this.activeTableId,
    this.viewMode = DatasetViewMode.table,
    this.rowLimit = defaultRowLimit,
    this.pageIndex = 0,
    this.filters = const [],
    this.sort,
    this.charts = const [],
  });

  factory DatasetWorkspaceUiState.fromLoadedState(
    DatasetLoadedState state,
  ) {
    final analyticsState = state.analyticsState;
    final charts = analyticsState is DatasetAnalyticsLoadedState
        ? [
            for (final chart in analyticsState.charts)
              StoredAnalyticsChart.fromAnalyticsChart(chart),
          ]
        : <StoredAnalyticsChart>[];

    return DatasetWorkspaceUiState(
      activeTableId: state.activeTable.id,
      viewMode: state.viewMode,
      rowLimit: state.rowLimit,
      pageIndex: state.pageIndex,
      filters: [
        for (final filter in state.filters)
          StoredDatasetFilter.fromDatasetFilter(filter),
      ],
      sort: state.sort == null
          ? null
          : StoredDatasetSort.fromDatasetSort(state.sort!),
      charts: charts,
    );
  }

  factory DatasetWorkspaceUiState.fromJsonString(String? rawJson) {
    if (rawJson == null || rawJson.trim().isEmpty) {
      return const DatasetWorkspaceUiState();
    }

    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) {
        return const DatasetWorkspaceUiState();
      }

      return DatasetWorkspaceUiState.fromJson(decoded);
    } catch (_) {
      return const DatasetWorkspaceUiState();
    }
  }

  factory DatasetWorkspaceUiState.fromJson(Map<String, dynamic> json) {
    final filtersJson = json['filters'];
    final chartsJson = json['charts'];

    return DatasetWorkspaceUiState(
      activeTableId:
          json['activeTableId'] is int ? json['activeTableId'] as int : null,
      viewMode: _viewModeFromName(json['viewMode']),
      rowLimit: _positiveIntFromJson(
        json['rowLimit'],
        fallback: defaultRowLimit,
      ),
      pageIndex: _nonNegativeIntFromJson(json['pageIndex']),
      filters: filtersJson is List
          ? [
              for (final filterJson in filtersJson)
                if (filterJson is Map<String, dynamic>)
                  StoredDatasetFilter.fromJson(filterJson),
            ]
          : const [],
      sort: json['sort'] is Map<String, dynamic>
          ? StoredDatasetSort.fromJson(json['sort'] as Map<String, dynamic>)
          : null,
      charts: chartsJson is List
          ? [
              for (final chartJson in chartsJson)
                if (chartJson is Map<String, dynamic>)
                  StoredAnalyticsChart.fromJson(chartJson),
            ]
          : const [],
    );
  }

  String toJsonString() => jsonEncode(toJson());

  Map<String, dynamic> toJson() {
    return {
      'activeTableId': activeTableId,
      'viewMode': viewMode.name,
      'rowLimit': rowLimit,
      'pageIndex': pageIndex,
      'filters': [for (final filter in filters) filter.toJson()],
      if (sort != null) 'sort': sort!.toJson(),
      if (charts.isNotEmpty)
        'charts': [for (final chart in charts) chart.toJson()],
    };
  }

  List<DatasetFilter> restoreFilters(List<DatasetColumn> columns) {
    return [
      for (final storedFilter in filters)
        if (storedFilter.toDatasetFilter(columns) != null)
          storedFilter.toDatasetFilter(columns)!,
    ];
  }

  DatasetSort? restoreSort(List<DatasetColumn> columns) {
    return sort?.toDatasetSort(columns);
  }
}

class StoredAnalyticsChart {
  final String id;
  final String chartTypeName;
  final String? xColumnDbName;
  final String? yColumnDbName;
  final String aggregationTypeName;

  const StoredAnalyticsChart({
    required this.id,
    required this.chartTypeName,
    this.xColumnDbName,
    this.yColumnDbName,
    this.aggregationTypeName = 'count',
  });

  factory StoredAnalyticsChart.fromAnalyticsChart(AnalyticsChart chart) {
    return StoredAnalyticsChart(
      id: chart.id,
      chartTypeName: chart.suggestion.chartType.name,
      xColumnDbName: chart.suggestion.xColumn?.dbName,
      yColumnDbName: chart.suggestion.yColumn?.dbName,
      aggregationTypeName: chart.suggestion.aggregationType.name,
    );
  }

  factory StoredAnalyticsChart.fromJson(Map<String, dynamic> json) {
    return StoredAnalyticsChart(
      id: json['id']?.toString() ?? '',
      chartTypeName: json['chartType']?.toString() ?? 'bar',
      xColumnDbName: json['xColumn']?.toString(),
      yColumnDbName: json['yColumn']?.toString(),
      aggregationTypeName: json['aggregation']?.toString() ?? 'count',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chartType': chartTypeName,
      if (xColumnDbName != null) 'xColumn': xColumnDbName,
      if (yColumnDbName != null) 'yColumn': yColumnDbName,
      'aggregation': aggregationTypeName,
    };
  }

  ChartSuggestion? toChartSuggestion(List<DatasetColumn> columns) {
    final chartType = ChartType.values.firstWhere(
      (t) => t.name == chartTypeName,
      orElse: () => ChartType.none,
    );
    if (!chartType.isImplemented) return null;

    final xColumn =
        xColumnDbName != null ? _findColumn(columns, xColumnDbName!) : null;
    if (xColumn == null) return null;

    final yColumn =
        yColumnDbName != null ? _findColumn(columns, yColumnDbName!) : null;

    final aggregationType = AggregationType.values.firstWhere(
      (a) => a.name == aggregationTypeName,
      orElse: () => AggregationType.count,
    );

    return ChartSuggestion(
      chartType: chartType,
      xColumn: xColumn,
      yColumn: yColumn,
      aggregationType: aggregationType,
    );
  }
}

class StoredDatasetFilter {
  final String columnDbName;
  final FilterOperator operator;
  final Object? value;
  final Object? secondValue;

  const StoredDatasetFilter({
    required this.columnDbName,
    required this.operator,
    this.value,
    this.secondValue,
  });

  factory StoredDatasetFilter.fromDatasetFilter(DatasetFilter filter) {
    return StoredDatasetFilter(
      columnDbName: filter.column.dbName,
      operator: filter.operator,
      value: _jsonSafeValue(filter.value),
      secondValue: _jsonSafeValue(filter.secondValue),
    );
  }

  factory StoredDatasetFilter.fromJson(Map<String, dynamic> json) {
    return StoredDatasetFilter(
      columnDbName: json['columnDbName']?.toString() ?? '',
      operator: _filterOperatorFromName(json['operator']),
      value: json['value'],
      secondValue: json['secondValue'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'columnDbName': columnDbName,
      'operator': operator.name,
      if (value != null) 'value': value,
      if (secondValue != null) 'secondValue': secondValue,
    };
  }

  DatasetFilter? toDatasetFilter(List<DatasetColumn> columns) {
    final column = _findColumn(columns, columnDbName);
    if (column == null || !operator.supportsType(column.declaredType)) {
      return null;
    }

    return DatasetFilter(
      column: column,
      operator: operator,
      value: value,
      secondValue: secondValue,
    );
  }
}

class StoredDatasetSort {
  final String columnDbName;
  final SortDirection direction;

  const StoredDatasetSort({
    required this.columnDbName,
    required this.direction,
  });

  factory StoredDatasetSort.fromDatasetSort(DatasetSort sort) {
    return StoredDatasetSort(
      columnDbName: sort.column.dbName,
      direction: sort.direction,
    );
  }

  factory StoredDatasetSort.fromJson(Map<String, dynamic> json) {
    return StoredDatasetSort(
      columnDbName: json['columnDbName']?.toString() ?? '',
      direction: _sortDirectionFromName(json['direction']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'columnDbName': columnDbName,
      'direction': direction.name,
    };
  }

  DatasetSort? toDatasetSort(List<DatasetColumn> columns) {
    final column = _findColumn(columns, columnDbName);
    if (column == null) {
      return null;
    }

    return DatasetSort(
      column: column,
      direction: direction,
    );
  }
}

DatasetColumn? _findColumn(List<DatasetColumn> columns, String dbName) {
  for (final column in columns) {
    if (column.dbName == dbName) {
      return column;
    }
  }

  return null;
}

DatasetViewMode _viewModeFromName(Object? value) {
  for (final mode in DatasetViewMode.values) {
    if (mode.name == value) {
      return mode;
    }
  }

  return DatasetViewMode.table;
}

FilterOperator _filterOperatorFromName(Object? value) {
  for (final operator in FilterOperator.values) {
    if (operator.name == value) {
      return operator;
    }
  }

  return FilterOperator.contains;
}

SortDirection _sortDirectionFromName(Object? value) {
  for (final direction in SortDirection.values) {
    if (direction.name == value) {
      return direction;
    }
  }

  return SortDirection.ascending;
}

int _positiveIntFromJson(Object? value, {required int fallback}) {
  final parsed = _intFromJson(value);
  if (parsed == null || parsed <= 0) {
    return fallback;
  }

  return parsed;
}

int _nonNegativeIntFromJson(Object? value) {
  final parsed = _intFromJson(value);
  if (parsed == null || parsed < 0) {
    return 0;
  }

  return parsed;
}

int? _intFromJson(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '');
}

Object? _jsonSafeValue(Object? value) {
  if (value is DateTime) {
    return value.toIso8601String().split('T').first;
  }

  return value;
}
