import 'dart:convert';

import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/entities/chart_suggestion.dart';
import 'package:exlser/domain/value_objects/aggregation_type.dart';
import 'package:exlser/domain/value_objects/chart_type.dart';
import 'package:exlser/domain/value_objects/dataset_filter.dart';
import 'package:exlser/domain/value_objects/dataset_sort.dart';
import 'package:exlser/domain/value_objects/filter_operator.dart';

import 'dataset_state.dart';

class DatasetWorkspaceUiState {
  static const int defaultRowLimit = 100;

  final int? activeTableId;
  final DatasetViewMode viewMode;
  final int rowLimit;
  final int pageIndex;
  final List<String> hiddenColumnDbNames;
  final List<StoredDatasetFilter> filters;
  final StoredDatasetSort? sort;
  final Map<int, StoredTableWorkspaceState> tableStates;
  @Deprecated(
      'Charts are now stored per-table in StoredTableWorkspaceState. This field is kept only for backward compatibility with old datasets.')
  final List<StoredAnalyticsChart> charts;

  const DatasetWorkspaceUiState({
    this.activeTableId,
    this.viewMode = DatasetViewMode.table,
    this.rowLimit = defaultRowLimit,
    this.pageIndex = 0,
    this.hiddenColumnDbNames = const [],
    this.filters = const [],
    this.sort,
    this.tableStates = const {},
    this.charts = const [],
  });

  factory DatasetWorkspaceUiState.fromLoadedState(
    DatasetLoadedState state,
  ) {
    final previousState = DatasetWorkspaceUiState.fromJsonString(
      state.dataset.uiStateJson,
    );
    final activeTableState = StoredTableWorkspaceState.fromLoadedState(
      state,
      previousState: previousState.tableStates[state.activeTable.id],
    );
    final tableStates = {
      ...previousState.tableStates,
      state.activeTable.id: activeTableState,
    };

    return DatasetWorkspaceUiState(
      activeTableId: state.activeTable.id,
      viewMode: state.viewMode,
      rowLimit: state.rowLimit,
      pageIndex: state.pageIndex,
      hiddenColumnDbNames: activeTableState.hiddenColumnDbNames,
      filters: activeTableState.filters,
      sort: activeTableState.sort,
      tableStates: tableStates,
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
    final hiddenColumnsJson = json['hiddenColumnDbNames'];
    final tableStatesJson = json['tableStates'];

    return DatasetWorkspaceUiState(
      activeTableId:
          json['activeTableId'] is int ? json['activeTableId'] as int : null,
      viewMode: _viewModeFromName(json['viewMode']),
      rowLimit: _positiveIntFromJson(
        json['rowLimit'],
        fallback: defaultRowLimit,
      ),
      pageIndex: _nonNegativeIntFromJson(json['pageIndex']),
      hiddenColumnDbNames: hiddenColumnsJson is List
          ? [
              for (final value in hiddenColumnsJson)
                if (value.toString().trim().isNotEmpty) value.toString().trim(),
            ]
          : const [],
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
      tableStates: tableStatesJson is Map
          ? {
              for (final entry in tableStatesJson.entries)
                if (_intFromJson(entry.key) != null &&
                    entry.value is Map<String, dynamic>)
                  _intFromJson(entry.key)!: StoredTableWorkspaceState.fromJson(
                    entry.value as Map<String, dynamic>,
                  ),
            }
          : const {},
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
    // ignore: deprecated_member_use_from_same_package
    final legacyCharts = charts;

    return {
      'activeTableId': activeTableId,
      'viewMode': viewMode.name,
      'rowLimit': rowLimit,
      'pageIndex': pageIndex,
      if (hiddenColumnDbNames.isNotEmpty)
        'hiddenColumnDbNames': hiddenColumnDbNames,
      'filters': [for (final filter in filters) filter.toJson()],
      if (sort != null) 'sort': sort!.toJson(),
      if (tableStates.isNotEmpty)
        'tableStates': {
          for (final entry in tableStates.entries)
            entry.key.toString(): entry.value.toJson(),
        },
      // Note: global 'charts' field is deprecated. Charts are now stored per-table.
      // This line handles backward compatibility: if there are global charts,
      // they are migrated to per-table on next load via restoreCharts() fallback.
      // New charts are always stored in tableStates[...].charts
      if (legacyCharts.isNotEmpty)
        'charts': [for (final chart in legacyCharts) chart.toJson()],
    };
  }

  List<DatasetFilter> restoreFilters(
    List<DatasetColumn> columns, {
    int? tableId,
  }) {
    final storedFilters = _tableStateFor(tableId)?.filters ?? filters;

    return [
      for (final storedFilter in storedFilters)
        if (storedFilter.toDatasetFilter(columns) != null)
          storedFilter.toDatasetFilter(columns)!,
    ];
  }

  DatasetSort? restoreSort(List<DatasetColumn> columns, {int? tableId}) {
    return (_tableStateFor(tableId)?.sort ?? sort)?.toDatasetSort(columns);
  }

  List<String> restoreHiddenColumnDbNames(
    List<DatasetColumn> columns, {
    int? tableId,
  }) {
    final knownColumns = columns.map((column) => column.dbName).toSet();
    final hiddenColumns =
        _tableStateFor(tableId)?.hiddenColumnDbNames ?? hiddenColumnDbNames;
    final restored = [
      for (final dbName in hiddenColumns)
        if (knownColumns.contains(dbName)) dbName,
    ];

    if (restored.length >= columns.length) {
      return const [];
    }

    return restored;
  }

  StoredTableWorkspaceState? _tableStateFor(int? tableId) {
    if (tableId == null) {
      return null;
    }

    return tableStates[tableId];
  }

  List<StoredAnalyticsChart> restoreCharts({int? tableId}) {
    // Charts are now stored per-table. This method prioritizes per-table charts
    // and falls back to global charts only for backward compatibility with old datasets.
    final tableCharts = _tableStateFor(tableId)?.charts;
    if (tableCharts != null && tableCharts.isNotEmpty) {
      return tableCharts;
    }

    // Fallback to deprecated global charts for backward compatibility
    // (These will only exist in datasets created with old code)
    // ignore: deprecated_member_use_from_same_package
    return charts;
  }

  /// Migrates global charts to per-table state for backward compatibility.
  /// Returns a new DatasetWorkspaceUiState with charts moved from global to per-table.
  /// If activeTableId is provided, global charts are moved to that table.
  DatasetWorkspaceUiState migrateGlobalChartsToPerTable({int? activeTableId}) {
    // ignore: deprecated_member_use_from_same_package
    final legacyCharts = charts;

    if (legacyCharts.isEmpty) {
      return this; // Nothing to migrate
    }

    final targetTableId = activeTableId ?? this.activeTableId ?? 0;

    // Get or create per-table state for target table
    final existingTableState = _tableStateFor(targetTableId);
    final migratedTableState = StoredTableWorkspaceState(
      charts: legacyCharts,
      hiddenColumnDbNames: existingTableState?.hiddenColumnDbNames ?? const [],
      filters: existingTableState?.filters ?? const [],
      sort: existingTableState?.sort,
    );

    // Update tableStates with migrated charts
    final newTableStates = {
      ...tableStates,
      targetTableId: migratedTableState,
    };

    // Return new state with empty global charts and migrated per-table charts
    return DatasetWorkspaceUiState(
      activeTableId: activeTableId,
      viewMode: viewMode,
      rowLimit: rowLimit,
      pageIndex: pageIndex,
      hiddenColumnDbNames: hiddenColumnDbNames,
      filters: filters,
      sort: sort,
      tableStates: newTableStates,
      charts: const [], // Clear deprecated global charts
    );
  }
}

class StoredTableWorkspaceState {
  final List<String> hiddenColumnDbNames;
  final List<StoredDatasetFilter> filters;
  final StoredDatasetSort? sort;
  final List<StoredAnalyticsChart> charts;

  const StoredTableWorkspaceState({
    this.hiddenColumnDbNames = const [],
    this.filters = const [],
    this.sort,
    this.charts = const [],
  });

  factory StoredTableWorkspaceState.fromLoadedState(DatasetLoadedState state,
      {StoredTableWorkspaceState? previousState}) {
    final analyticsState = state.analyticsState;
    final charts = analyticsState is DatasetAnalyticsLoadedState
        ? [
            for (final chart in analyticsState.charts)
              StoredAnalyticsChart.fromAnalyticsChart(chart),
          ]
        : previousState?.charts ?? const <StoredAnalyticsChart>[];

    return StoredTableWorkspaceState(
      hiddenColumnDbNames: state.hiddenColumnDbNames,
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

  factory StoredTableWorkspaceState.fromJson(Map<String, dynamic> json) {
    final hiddenColumnsJson = json['hiddenColumnDbNames'];
    final filtersJson = json['filters'];
    final chartsJson = json['charts'];

    return StoredTableWorkspaceState(
      hiddenColumnDbNames: hiddenColumnsJson is List
          ? [
              for (final value in hiddenColumnsJson)
                if (value.toString().trim().isNotEmpty) value.toString().trim(),
            ]
          : const [],
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

  Map<String, dynamic> toJson() {
    return {
      if (hiddenColumnDbNames.isNotEmpty)
        'hiddenColumnDbNames': hiddenColumnDbNames,
      if (filters.isNotEmpty)
        'filters': [for (final filter in filters) filter.toJson()],
      if (sort != null) 'sort': sort!.toJson(),
      if (charts.isNotEmpty)
        'charts': [for (final chart in charts) chart.toJson()],
    };
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
    if (!chartType.validXColumnTypes.contains(xColumn.declaredType)) {
      return null;
    }

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
