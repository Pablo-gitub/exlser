import 'package:exel_category/core/database/app_database.dart';

/// Data source responsible for interacting with the Drift database.
///
/// This component exposes low-level database operations used by
/// repository implementations.
///
/// Responsibilities:
/// - Execute raw SQL queries
/// - Execute SQL commands (DDL/DML)
/// - Provide a thin abstraction over Drift
///
/// IMPORTANT:
/// - This layer should NOT contain business logic
/// - This layer should NOT transform domain entities
/// - It only executes SQL and returns raw data
class DriftDatasource {

  final AppDatabase db;

  const DriftDatasource(this.db);

  /// Executes a raw SQL query and returns result rows.
  ///
  /// Example:
  /// SELECT * FROM my_table
  ///
  /// Returns:
  /// List<Map<String, dynamic>>
  ///
  /// Notes:
  /// - Uses Drift's customSelect
  /// - Result rows are mapped to simple key-value maps
  Future<List<Map<String, dynamic>>> query(String sql) async {

    final result = await db.customSelect(sql).get();

    return result
        .map((row) => row.data)
        .toList();
  }

  /// Executes a raw SQL command.
  ///
  /// Used for:
  /// - CREATE TABLE
  /// - INSERT
  /// - UPDATE
  /// - DELETE
  /// - DROP TABLE
  ///
  /// Example:
  /// CREATE TABLE my_table (...)
  ///
  /// Notes:
  /// - No result is returned
  /// - Uses Drift's customStatement
  Future<void> execute(String sql) async {

    await db.customStatement(sql);
  }

  /// Executes a batch of SQL commands inside a transaction.
  ///
  /// Useful for:
  /// - bulk inserts
  /// - performance-sensitive operations
  ///
  /// Example:
  /// multiple INSERT statements
  Future<void> executeBatch(List<String> statements) async {

    await db.transaction(() async {

      for (final sql in statements) {
        await db.customStatement(sql);
      }
    });
  }
}