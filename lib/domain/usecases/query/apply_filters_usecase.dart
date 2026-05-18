import 'package:exel_category/domain/repositories/query_repository.dart';
import 'package:exel_category/domain/value_objects/column_type.dart';
import 'package:exel_category/domain/value_objects/dataset_filter.dart';
import 'package:exel_category/domain/value_objects/dataset_sort.dart';
import 'package:exel_category/domain/value_objects/filter_operator.dart';

/// Executes filtered and sorted queries on a dataset table.
///
/// This use case is the query foundation for the dataset workspace. UI
/// surfaces can build filters in different ways while keeping a single
/// SQL translation path.
class ApplyFiltersUseCase {
  final QueryRepository repository;

  const ApplyFiltersUseCase({
    required this.repository,
  });

  Future<List<Map<String, dynamic>>> call({
    required String tableName,
    List<DatasetFilter> filters = const [],
    DatasetSort? sort,
    int? limit,
    int? offset,
  }) async {
    final trimmedTable = tableName.trim();
    if (trimmedTable.isEmpty) {
      throw ArgumentError('Table name cannot be empty');
    }

    if (limit != null && limit <= 0) {
      throw ArgumentError('Limit must be greater than 0');
    }

    if (offset != null && offset < 0) {
      throw ArgumentError('Offset cannot be negative');
    }

    final where = _buildWhereClause(filters);
    final orderBy = _buildOrderBy(sort);

    if (where == null && orderBy == null) {
      return repository.fetchRows(
        tableName: trimmedTable,
        limit: limit,
        offset: offset,
      );
    }

    if (where != null && orderBy == null) {
      return repository.queryWithFilter(
        tableName: trimmedTable,
        whereClause: where.sql,
        arguments: where.arguments,
        limit: limit,
        offset: offset,
      );
    }

    if (where != null && orderBy != null) {
      return repository.queryWithFilterAndOrder(
        tableName: trimmedTable,
        whereClause: where.sql,
        orderBy: orderBy,
        arguments: where.arguments,
        limit: limit,
        offset: offset,
      );
    }

    return repository.executeRawQuery(
      _buildOrderedQuery(
        tableName: trimmedTable,
        orderBy: orderBy!,
        limit: limit,
        offset: offset,
      ),
      null,
    );
  }

  /// Returns the SQL WHERE clause and bound arguments for the given filters,
  /// or null when no filters are active. Used by analytics to respect filters.
  ({String sql, List<Object?> arguments})? buildWhereClause(
    List<DatasetFilter> filters,
  ) {
    final clause = _buildWhereClause(filters);
    if (clause == null) return null;
    return (sql: clause.sql, arguments: clause.arguments);
  }

  _WhereClause? _buildWhereClause(List<DatasetFilter> filters) {
    if (filters.isEmpty) {
      return null;
    }

    final conditions = <String>[];
    final arguments = <Object?>[];

    for (final filter in filters) {
      _validateFilter(filter);

      final column = filter.column.dbName.trim();
      final operator = filter.operator;

      switch (operator) {
        case FilterOperator.contains:
          conditions.add("$column LIKE ? ESCAPE '\\'");
          arguments.add('%${_escapeLikeValue(filter.value!)}%');
        case FilterOperator.startsWith:
          conditions.add("$column LIKE ? ESCAPE '\\'");
          arguments.add('${_escapeLikeValue(filter.value!)}%');
        case FilterOperator.endsWith:
          conditions.add("$column LIKE ? ESCAPE '\\'");
          arguments.add('%${_escapeLikeValue(filter.value!)}');
        case FilterOperator.equals || FilterOperator.on:
          conditions.add('$column = ?');
          arguments
              .add(_normalizeValue(filter.column.declaredType, filter.value));
        case FilterOperator.notEquals:
          conditions.add('$column != ?');
          arguments
              .add(_normalizeValue(filter.column.declaredType, filter.value));
        case FilterOperator.greaterThan || FilterOperator.after:
          conditions.add('$column > ?');
          arguments
              .add(_normalizeValue(filter.column.declaredType, filter.value));
        case FilterOperator.greaterOrEqual:
          conditions.add('$column >= ?');
          arguments
              .add(_normalizeValue(filter.column.declaredType, filter.value));
        case FilterOperator.lessThan || FilterOperator.before:
          conditions.add('$column < ?');
          arguments
              .add(_normalizeValue(filter.column.declaredType, filter.value));
        case FilterOperator.lessOrEqual:
          conditions.add('$column <= ?');
          arguments
              .add(_normalizeValue(filter.column.declaredType, filter.value));
        case FilterOperator.between:
          conditions.add('$column BETWEEN ? AND ?');
          arguments
            ..add(_normalizeValue(filter.column.declaredType, filter.value))
            ..add(
              _normalizeValue(filter.column.declaredType, filter.secondValue),
            );
        case FilterOperator.isEmpty:
          conditions.add('($column IS NULL OR $column = \'\')');
        case FilterOperator.isNotEmpty:
          conditions.add('($column IS NOT NULL AND $column != \'\')');
        case FilterOperator.isTrue:
          conditions.add('$column = ?');
          arguments.add(1);
        case FilterOperator.isFalse:
          conditions.add('$column = ?');
          arguments.add(0);
      }
    }

    return _WhereClause(
      sql: conditions.map((condition) => '($condition)').join(' AND '),
      arguments: arguments,
    );
  }

  void _validateFilter(DatasetFilter filter) {
    final columnName = filter.column.dbName.trim();
    if (columnName.isEmpty) {
      throw ArgumentError('Column dbName cannot be empty');
    }

    if (!filter.operator.supportsType(filter.column.declaredType)) {
      throw ArgumentError(
        'Operator ${filter.operator.name} is not supported for '
        '${filter.column.declaredType.name}',
      );
    }

    if (filter.operator.requiresValue && filter.isValueMissing) {
      throw ArgumentError('Filter value is required');
    }

    if (filter.operator.requiresSecondValue && filter.isSecondValueMissing) {
      throw ArgumentError('Second filter value is required');
    }
  }

  String? _buildOrderBy(DatasetSort? sort) {
    if (sort == null) {
      return null;
    }

    final columnName = sort.column.dbName.trim();
    if (columnName.isEmpty) {
      throw ArgumentError('Sort column dbName cannot be empty');
    }

    return '$columnName ${sort.direction.sqlKeyword}';
  }

  String _buildOrderedQuery({
    required String tableName,
    required String orderBy,
    int? limit,
    int? offset,
  }) {
    final buffer = StringBuffer('SELECT * FROM $tableName ORDER BY $orderBy');

    if (limit != null) {
      buffer.write(' LIMIT $limit');
    }

    if (offset != null) {
      buffer.write(' OFFSET $offset');
    }

    return buffer.toString();
  }

  Object? _normalizeValue(ColumnType type, Object? value) {
    if (value == null) {
      return null;
    }

    if (type == ColumnType.boolean) {
      return _normalizeBoolean(value);
    }

    if (type == ColumnType.date && value is DateTime) {
      return value.toIso8601String().split('T').first;
    }

    return value;
  }

  int _normalizeBoolean(Object value) {
    if (value is bool) {
      return value ? 1 : 0;
    }

    if (value is num) {
      return value == 0 ? 0 : 1;
    }

    final normalized = value.toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == 'yes' || normalized == '1') {
      return 1;
    }
    if (normalized == 'false' || normalized == 'no' || normalized == '0') {
      return 0;
    }

    throw ArgumentError('Boolean filter value is invalid');
  }

  String _escapeLikeValue(Object value) {
    return value
        .toString()
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
  }
}

class _WhereClause {
  final String sql;
  final List<Object?> arguments;

  const _WhereClause({
    required this.sql,
    required this.arguments,
  });
}
