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

    final buffer = StringBuffer('SELECT * FROM $trimmedTable');

    // Apply LIMIT if present
    if (limit != null) {
      buffer.write(' LIMIT $limit');
    }

    if (offset != null) {
      buffer.write(' OFFSET $offset');
    }

    final sql = buffer.toString();

    final result = await datasource.query(sql);

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

    final buffer = StringBuffer()
      ..write('SELECT * FROM $trimmedTable')
      ..write(' WHERE $trimmedWhere');

    // Apply LIMIT if present
    if (limit != null) {
      buffer.write(' LIMIT $limit');
    }

    // Apply OFFSET if present
    if (offset != null) {
      buffer.write(' OFFSET $offset');
    }

    final sql = buffer.toString();

    final result = await datasource.query(
      sql,
      arguments: arguments,
    );

    return result;
  }

  /// Returns the number of rows inside a dataset table.
  ///
  /// Example:
  /// SELECT COUNT(*) as count FROM products
  ///
  /// Parameters:
  /// - [tableName]: target SQL table
  ///
  /// Returns:
  /// - total number of rows as integer
  ///
  /// Throws:
  /// - Exception if table name is empty
  ///
  /// Notes:
  /// - Uses alias "count" to standardize result parsing
  @override
  Future<int> countRows(String tableName) async {

    final trimmedTable = tableName.trim();

    if (trimmedTable.isEmpty) {
      throw Exception('Table name cannot be empty');
    }

    final sql = 'SELECT COUNT(*) as count FROM $trimmedTable';

    final result = await datasource.query(
      sql,
      arguments: null,
    );

    if (result.isEmpty) {
      return 0;
    }

    final value = result.first['count'];

    if (value is int) {
      return value;
    }

    // Safety fallback (SQLite can return num)
    if (value is num) {
      return value.toInt();
    }

    // Unexpected case
    throw Exception('Invalid count result');
  }

  /// Returns distinct values for a specific column in a dataset table.
  ///
  /// Example:
  /// SELECT DISTINCT price FROM products
  ///
  /// Parameters:
  /// - [tableName]: target SQL table
  /// - [column]: DatasetColumn metadata (uses dbName)
  ///
  /// Returns:
  /// - List of distinct values (dynamic type)
  ///
  /// Throws:
  /// - Exception if table name is empty
  /// - Exception if column dbName is empty
  ///
  /// Notes:
  /// - Uses column.dbName (NOT originalName)
  /// - Safe for dynamic schema usage
  /// - Order is not guaranteed (SQLite default behavior)
  @override
  Future<List<dynamic>> getDistinctValues({
    required String tableName,
    required DatasetColumn column,
  }) async {

    final trimmedTable = tableName.trim();
    final trimmedColumn = column.dbName.trim();

    if (trimmedTable.isEmpty) {
      throw Exception('Table name cannot be empty');
    }

    if (trimmedColumn.isEmpty) {
      throw Exception('Column name cannot be empty');
    }

    final sql = 'SELECT DISTINCT $trimmedColumn FROM $trimmedTable';

    final result = await datasource.query(
      sql,
      arguments: null,
    );

    if (result.isEmpty) {
      return [];
    }

    // Each row contains:
    // { 'columnName': value }
    //
    // We extract only the value
    return result.map((row) => row[trimmedColumn]).toList();
  }

  /// Executes an aggregation query on a dataset table.
  ///
  /// Example:
  /// SELECT SUM(price) as result FROM products
  /// SELECT AVG(quantity) as result FROM orders
  ///
  /// Parameters:
  /// - [tableName]: target SQL table
  /// - [column]: DatasetColumn metadata (uses dbName)
  /// - [function]: SQL aggregate function (e.g. COUNT, SUM, AVG, MIN, MAX)
  ///
  /// Returns:
  /// - Aggregated value (dynamic)
  /// - Returns null if no result is available
  ///
  /// Throws:
  /// - Exception if inputs are invalid
  ///
  /// Notes:
  /// - Uses alias "result" for consistent parsing
  /// - Function is normalized to uppercase
  @override
  Future<dynamic> aggregate({
    required String tableName,
    required DatasetColumn column,
    required String function,
  }) async {

    final trimmedTable = tableName.trim();
    final trimmedColumn = column.dbName.trim();
    final trimmedFunction = function.trim().toUpperCase();

    if (trimmedTable.isEmpty) {
      throw Exception('Table name cannot be empty');
    }

    if (trimmedColumn.isEmpty) {
      throw Exception('Column name cannot be empty');
    }

    if (trimmedFunction.isEmpty) {
      throw Exception('Function cannot be empty');
    }

    // Optional: whitelist functions (recommended)
    const allowedFunctions = {'COUNT', 'SUM', 'AVG', 'MIN', 'MAX'};
    if (!allowedFunctions.contains(trimmedFunction)) {
      throw Exception('Unsupported aggregate function: $trimmedFunction');
    }

    final sql =
        'SELECT $trimmedFunction($trimmedColumn) as result FROM $trimmedTable';

    final result = await datasource.query(
      sql,
      arguments: null,
    );

    if (result.isEmpty) {
      return null;
    }

    final value = result.first['result'];

    // SQLite can return int, double, or null
    return value;
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

    final result = await datasource.query(
      sql,
      arguments: arguments,
    );

    return result;
  }

  /// Executes a raw SQL query against the dataset database.
  ///
  /// This method is intended for advanced use cases:
  /// - analytics queries
  /// - debugging
  /// - complex SQL not covered by repository methods
  ///
  /// Parameters:
  /// - [sql]: raw SQL query
  /// - [arguments]: optional bound parameters
  ///
  /// Returns:
  /// - List of rows as Map<String, dynamic>
  ///
  /// Throws:
  /// - Exception if SQL is empty
  ///
  /// Notes:
  /// - Use carefully (bypasses abstraction safety)
  /// - Prefer structured methods when possible
  @override
  Future<List<Map<String, dynamic>>> executeRawQuery(
    String sql,
    List<dynamic>? arguments,
  ) async {

    final trimmedSql = sql.trim();

    if (trimmedSql.isEmpty) {
      throw Exception('SQL query cannot be empty');
    }

    final result = await datasource.query(
      trimmedSql,
      arguments: arguments,
    );

    return result;
  }

  /// Inserts multiple rows into a dynamically generated dataset table.
  ///
  /// This method is optimized for bulk import operations:
  /// - validates table name and row structure
  /// - builds the INSERT SQL statement once
  /// - executes all inserts inside a transaction
  /// - processes rows in chunks to reduce memory pressure
  ///
  /// Requirements:
  /// - [tableName] must be a valid sanitized SQL table name
  /// - [rows] must all share the same keys
  /// - row keys must match existing SQL column names
  ///
  /// Notes:
  /// - Empty row lists are ignored
  /// - Values are bound through SQL parameters to prevent injection
  /// - This method is mainly used by InsertRowsUseCase during dataset creation
  @override
  Future<void> insertBatch({
    required String tableName,
    required List<Map<String, dynamic>> rows,
  }) async {
    // Validate input
    if (tableName.trim().isEmpty) {
      throw Exception('Table name cannot be empty');
    }

    // Nothing to insert → early exit
    if (rows.isEmpty) return;

    // Extract column names from first row
    // Assumption: all rows share the same structure
    final columns = rows.first.keys.toList();

    for (final row in rows) {
      if (row.keys.length != columns.length ||
          !row.keys.every(columns.contains)) {
        throw Exception('All rows must have the same structure');
      }
    }

    // Build SQL structure once (reused for all inserts)
    //
    // Example:
    // INSERT INTO my_table (col1, col2) VALUES (?, ?)
    final columnNames = columns.join(', ');
    final placeholders = List.filled(columns.length, '?').join(', ');
    final sql = 'INSERT INTO $tableName ($columnNames) VALUES ($placeholders)';

    // Execute all inserts inside a single transaction
    // → improves performance significantly
    // → ensures atomicity (all or nothing)
    await datasource.runInTransaction(() async {
      // Process rows in chunks to:
      // - avoid memory spikes
      // - prevent UI freezes on large datasets
      for (int i = 0; i < rows.length; i += _batchSize) {
        // Extract current chunk
        final chunk = rows.sublist(
          i,
          i + _batchSize > rows.length ? rows.length : i + _batchSize,
        );

        // Insert each row in the current chunk
        for (final row in chunk) {
          // Map row values to ordered column list
          final values = List.generate(
            columns.length,
            (index) => row[columns[index]],
          );

          // Execute insert statement with bound parameters
          // → prevents SQL injection
          await datasource.executeWithArgs(sql, values);
        }
      }
    });
  }
}
