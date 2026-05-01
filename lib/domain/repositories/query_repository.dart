//lib/domain/repositories/query_repository.dart
import 'package:exel_category/domain/entities/dataset_column.dart';

/// Repository responsible for querying dataset data.
///
/// This repository exposes operations used to read data
/// from dynamically generated SQL tables created from Excel imports.
abstract class QueryRepository {
  /// Returns rows from a dataset table.
  ///
  /// Supports pagination through limit and offset.
  Future<List<Map<String, dynamic>>> fetchRows({
    required String tableName,
    int? limit,
    int? offset,
  });

  /// Executes a filtered query on a dataset table.
  ///
  /// The filter is expressed as a SQL WHERE clause.
  Future<List<Map<String, dynamic>>> queryWithFilter({
    required String tableName,
    required String whereClause,
    List<dynamic>? arguments,
    int? limit,
    int? offset,
  });

  /// Returns the number of rows inside a table.
  Future<int> countRows(String tableName);

  /// Returns distinct values for a column.
  ///
  /// Useful for building UI filters.
  Future<List<dynamic>> getDistinctValues({
    required String tableName,
    required DatasetColumn column,
  });

  /// Executes an aggregation query.
  ///
  /// Example:
  /// COUNT, SUM, AVG, MIN, MAX
  Future<dynamic> aggregate({
    required String tableName,
    required DatasetColumn column,
    required String function,
  });

  /// Executes a filtered and ordered query on a dataset table.
  ///
  /// Allows combining a WHERE clause with an ORDER BY clause
  /// and optional pagination parameters.
  ///
  /// Example:
  /// WHERE price > ?
  /// ORDER BY price DESC
  Future<List<Map<String, dynamic>>> queryWithFilterAndOrder({
    required String tableName,
    required String whereClause,
    required String orderBy,
    List<dynamic>? arguments,
    int? limit,
    int? offset,
  });

  /// Executes a raw SQL query against the underlying dataset database.
  ///
  /// This method is intended for advanced operations such as
  /// debugging, analytics queries or complex aggregations that
  /// are not covered by the standard repository methods.
  ///
  /// The result is returned as a list of rows represented
  /// as key-value maps.
  Future<List<Map<String, dynamic>>> executeRawQuery(
    String sql,
    List<dynamic>? arguments,
  );

  /// Inserts a batch of rows into a dataset table.
  ///
  /// This method is optimized for bulk insert operations and
  /// should be executed inside a database transaction.
  ///
  /// [tableName] → target SQL table
  /// [rows] → list of key-value maps where:
  ///   - keys represent column names
  ///   - values represent cell values
  ///
  /// Requirements:
  /// - All rows must share the same structure (same keys)
  /// - Keys must match existing SQL columns
  ///
  /// Notes:
  /// - Implementations should use batch/transaction inserts
  ///   for performance
  /// - Should handle large datasets efficiently
  /// - Should throw in case of constraint violations
  Future<void> insertBatch({
    required String tableName,
    required List<Map<String, dynamic>> rows,
  });
}
