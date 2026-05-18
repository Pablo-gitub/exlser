import 'package:exel_category/domain/entities/dataset.dart';
import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/entities/dataset_table.dart';
import 'package:exel_category/domain/value_objects/dataset_filter.dart';
import 'package:exel_category/domain/value_objects/dataset_sort.dart';

enum DatasetViewMode {
  table,
  cards,
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
    );
  }
}

const Object _sortNotProvided = Object();

class DatasetErrorState extends DatasetState {
  final String code;

  const DatasetErrorState(this.code);
}
