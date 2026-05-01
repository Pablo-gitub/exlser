import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/repositories/query_repository.dart';
import 'package:exel_category/data/datasources/drift_datasource.dart';

/// Concrete implementation of [QueryRepository].
///
/// Responsible for executing SQL queries against dynamically
/// generated dataset tables.

class QueryRepositoryImpl implements QueryRepository {
  final DriftDatasource datasource;
  static const int _batchSize = 200;

  QueryRepositoryImpl(this.datasource);

  /// Retrieves rows from a dataset table with optional pagination.
  ///
  /// This method builds a dynamic SQL query to fetch all rows from the
  /// specified table. It supports LIMIT and OFFSET for pagination.
  ///
  /// Example:
  /// SELECT * FROM products LIMIT 10 OFFSET 20
  ///
  /// Parameters:
  /// - [tableName]: target SQL table (must be a valid sanitized name)
  /// - [limit]: maximum number of rows to return (optional)
  /// - [offset]: number of rows to skip (optional)
  ///
  /// Returns:
  /// - List of rows as Map<String, dynamic>
  ///
  /// Throws:
  /// - Exception if tableName is empty
  /// - Exception if limit <= 0
  /// - Exception if offset < 0
  ///
  /// Notes:
  /// - This method does not perform filtering or ordering.
  /// - Intended as a base query for higher-level operations.
  @override
  Future<List<Map<String, dynamic>>> fetchRows({
    required String tableName,
    int? limit,
    int? offset,
  }) async {
    /// ----------------------------
    /// 1. Validate input
    /// ----------------------------
    final trimmedTable = tableName.trim();

    if (trimmedTable.isEmpty) {
      throw Exception('Table name cannot be empty');
    }

    if (limit != null && limit <= 0) {
      throw Exception('Limit must be greater than 0');
    }

    if (offset != null && offset < 0) {
      throw Exception('Offset cannot be negative');
    }

    /// ----------------------------
    /// 2. Build SQL query
    /// ----------------------------
    final buffer = StringBuffer('SELECT * FROM $trimmedTable');

    /// Apply LIMIT if present
    if (limit != null) {
      buffer.write(' LIMIT $limit');
    }

    /// Apply OFFSET if present
    /// SQLite allows OFFSET without LIMIT, but:
    /// - safer to always append after LIMIT if both exist
    if (offset != null) {
      buffer.write(' OFFSET $offset');
    }

    final sql = buffer.toString();

    /// ----------------------------
    /// 3. Execute query
    /// ----------------------------
    final result = await datasource.query(sql);

    /// ----------------------------
    /// 4. Return result
    /// ----------------------------
    return result;
  }

  /// Executes a filtered query on a dataset table.
  ///
  /// This method builds a dynamic SQL query using a WHERE clause
  /// and optional pagination (LIMIT / OFFSET).
  ///
  /// Example:
  /// SELECT * FROM products WHERE price > ?
  /// SELECT * FROM products WHERE name = ? LIMIT 10 OFFSET 5
  ///
  /// Parameters:
  /// - [tableName]: target SQL table (must be a valid sanitized name)
  /// - [whereClause]: SQL WHERE condition (without the 'WHERE' keyword)
  /// - [arguments]: values bound to placeholders (?) in the WHERE clause
  /// - [limit]: maximum number of rows to return (optional)
  /// - [offset]: number of rows to skip (optional)
  ///
  /// Returns:
  /// - List of rows as Map<String, dynamic>
  ///
  /// Throws:
  /// - Exception if tableName is empty
  /// - Exception if whereClause is empty
  /// - Exception if limit <= 0
  /// - Exception if offset < 0
  ///
  /// Notes:
  /// - Uses parameterized queries to prevent SQL injection.
  /// - WHERE clause must use '?' placeholders for arguments.
  /// - Designed to be extended with ORDER BY in future methods.
  @override
  Future<List<Map<String, dynamic>>> queryWithFilter({
    required String tableName,
    required String whereClause,
    List<dynamic>? arguments,
    int? limit,
    int? offset,
  }) async {
    /// ----------------------------
    /// 1. Validate input
    /// ----------------------------

    final trimmedTable = tableName.trim();
    final trimmedWhere = whereClause.trim();

    if (trimmedTable.isEmpty) {
      throw Exception('Table name cannot be empty');
    }

    if (trimmedWhere.isEmpty) {
      throw Exception('Where clause cannot be empty');
    }

    if (limit != null && limit <= 0) {
      throw Exception('Limit must be greater than 0');
    }

    if (offset != null && offset < 0) {
      throw Exception('Offset cannot be negative');
    }

    /// ----------------------------
    /// 2. Build SQL query
    /// ----------------------------

    final buffer = StringBuffer()
      ..write('SELECT * FROM $trimmedTable')
      ..write(' WHERE $trimmedWhere');

    /// Apply LIMIT if present
    if (limit != null) {
      buffer.write(' LIMIT $limit');
    }

    /// Apply OFFSET if present
    if (offset != null) {
      buffer.write(' OFFSET $offset');
    }

    final sql = buffer.toString();

    /// ----------------------------
    /// 3. Execute query
    /// ----------------------------

    final result = await datasource.query(
      sql,
      arguments: arguments,
    );

    /// ----------------------------
    /// 4. Return result
    /// ----------------------------

    return result;
  }

  @override
  Future<int> countRows(String tableName) async {
    /// TODO:
    /// Return number of rows in table.
    ///
    /// Example:
    /// SELECT COUNT(*) FROM table
    throw UnimplementedError();
  }

  @override
  Future<List<dynamic>> getDistinctValues({
    required String tableName,
    required DatasetColumn column,
  }) async {
    /// TODO:
    /// Retrieve distinct values for a column.
    ///
    /// Example:
    /// SELECT DISTINCT column FROM table
    throw UnimplementedError();
  }

  @override
  Future<dynamic> aggregate({
    required String tableName,
    required DatasetColumn column,
    required String function,
  }) async {
    /// TODO:
    /// Execute aggregate function.
    ///
    /// Example:
    /// SELECT AVG(price) FROM table
    throw UnimplementedError();
  }

  /// Executes a filtered and ordered query on a dataset table.
  ///
  /// This method extends queryWithFilter by adding ORDER BY support.
  ///
  /// Example:
  /// SELECT * FROM products WHERE price > ? ORDER BY price DESC
  /// SELECT * FROM products WHERE name = ? ORDER BY name ASC LIMIT 10 OFFSET 5
  ///
  /// Parameters:
  /// - [tableName]: target SQL table (must be sanitized)
  /// - [whereClause]: SQL WHERE condition (without 'WHERE')
  /// - [orderBy]: SQL ORDER BY clause (e.g. "price DESC")
  /// - [arguments]: values bound to placeholders (?)
  /// - [limit]: max rows to return (optional)
  /// - [offset]: rows to skip (optional)
  ///
  /// Returns:
  /// - List of rows as Map<String, dynamic>
  ///
  /// Throws:
  /// - Exception if tableName, whereClause or orderBy are invalid
  ///
  /// Notes:
  /// - Uses parameterized queries for safety
  /// - Designed for UI sorting (tables, filters, analytics)
  @override
  Future<List<Map<String, dynamic>>> queryWithFilterAndOrder({
    required String tableName,
    required String whereClause,
    required String orderBy,
    List<dynamic>? arguments,
    int? limit,
    int? offset,
  }) async {
    /// ----------------------------
    /// 1. Validate input
    /// ----------------------------

    final trimmedTable = tableName.trim();
    final trimmedWhere = whereClause.trim();
    final trimmedOrder = orderBy.trim();

    if (trimmedTable.isEmpty) {
      throw Exception('Table name cannot be empty');
    }

    if (trimmedWhere.isEmpty) {
      throw Exception('Where clause cannot be empty');
    }

    if (trimmedOrder.isEmpty) {
      throw Exception('OrderBy cannot be empty');
    }

    if (limit != null && limit <= 0) {
      throw Exception('Limit must be greater than 0');
    }

    if (offset != null && offset < 0) {
      throw Exception('Offset cannot be negative');
    }

    /// ----------------------------
    /// 2. Build SQL query
    /// ----------------------------

    final buffer = StringBuffer()
      ..write('SELECT * FROM $trimmedTable')
      ..write(' WHERE $trimmedWhere')
      ..write(' ORDER BY $trimmedOrder');

    if (limit != null) {
      buffer.write(' LIMIT $limit');
    }

    if (offset != null) {
      buffer.write(' OFFSET $offset');
    }

    final sql = buffer.toString();

    /// ----------------------------
    /// 3. Execute query
    /// ----------------------------

    final result = await datasource.query(
      sql,
      arguments: arguments,
    );

    /// ----------------------------
    /// 4. Return result
    /// ----------------------------

    return result;
  }

  @override
  Future<List<Map<String, dynamic>>> executeRawQuery(
    String sql,
    List<dynamic>? arguments,
  ) async {
    /// TODO:
    /// Execute arbitrary SQL query.
    ///
    /// Used for advanced analytics queries.
    throw UnimplementedError();
  }

  @override
  Future<void> insertBatch({
    required String tableName,
    required List<Map<String, dynamic>> rows,
  }) async {
    /// Validate input
    if (tableName.trim().isEmpty) {
      throw Exception('Table name cannot be empty');
    }

    /// Nothing to insert → early exit
    if (rows.isEmpty) return;

    /// Extract column names from first row
    /// Assumption: all rows share the same structure
    final columns = rows.first.keys.toList();

    for (final row in rows) {
      if (row.keys.length != columns.length ||
          !row.keys.every(columns.contains)) {
        throw Exception('All rows must have the same structure');
      }
    }

    /// Build SQL structure once (reused for all inserts)
    ///
    /// Example:
    /// INSERT INTO my_table (col1, col2) VALUES (?, ?)
    final columnNames = columns.join(', ');
    final placeholders = List.filled(columns.length, '?').join(', ');
    final sql = 'INSERT INTO $tableName ($columnNames) VALUES ($placeholders)';

    /// Execute all inserts inside a single transaction
    /// → improves performance significantly
    /// → ensures atomicity (all or nothing)
    await datasource.runInTransaction(() async {
      /// Process rows in chunks to:
      /// - avoid memory spikes
      /// - prevent UI freezes on large datasets
      for (int i = 0; i < rows.length; i += _batchSize) {
        /// Extract current chunk
        final chunk = rows.sublist(
          i,
          i + _batchSize > rows.length ? rows.length : i + _batchSize,
        );

        /// Insert each row in the current chunk
        for (final row in chunk) {
          /// Map row values to ordered column list
          final values = List.generate(
            columns.length,
            (index) => row[columns[index]],
          );

          /// Execute insert statement with bound parameters
          /// → prevents SQL injection
          await datasource.executeWithArgs(sql, values);
        }
      }
    });
  }
}
