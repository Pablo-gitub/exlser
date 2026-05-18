import 'dart:convert';

import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/value_objects/dataset_filter.dart';
import 'package:exel_category/domain/value_objects/dataset_sort.dart';
import 'package:exel_category/domain/value_objects/filter_operator.dart';

import 'dataset_state.dart';

class DatasetWorkspaceUiState {
  final int? activeTableId;
  final DatasetViewMode viewMode;
  final List<StoredDatasetFilter> filters;
  final StoredDatasetSort? sort;

  const DatasetWorkspaceUiState({
    this.activeTableId,
    this.viewMode = DatasetViewMode.table,
    this.filters = const [],
    this.sort,
  });

  factory DatasetWorkspaceUiState.fromLoadedState(
    DatasetLoadedState state,
  ) {
    return DatasetWorkspaceUiState(
      activeTableId: state.activeTable.id,
      viewMode: state.viewMode,
      filters: [
        for (final filter in state.filters)
          StoredDatasetFilter.fromDatasetFilter(filter),
      ],
      sort: state.sort == null
          ? null
          : StoredDatasetSort.fromDatasetSort(state.sort!),
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

    return DatasetWorkspaceUiState(
      activeTableId:
          json['activeTableId'] is int ? json['activeTableId'] as int : null,
      viewMode: _viewModeFromName(json['viewMode']),
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
    );
  }

  String toJsonString() => jsonEncode(toJson());

  Map<String, dynamic> toJson() {
    return {
      'activeTableId': activeTableId,
      'viewMode': viewMode.name,
      'filters': [for (final filter in filters) filter.toJson()],
      if (sort != null) 'sort': sort!.toJson(),
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

Object? _jsonSafeValue(Object? value) {
  if (value is DateTime) {
    return value.toIso8601String().split('T').first;
  }

  return value;
}
