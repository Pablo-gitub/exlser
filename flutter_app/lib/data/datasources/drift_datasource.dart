import 'package:drift/drift.dart';

/// Data source responsible for interacting with the Drift database.
///
/// This component exposes low-level database operations used by
/// repository implementations.
///
/// Responsibilities:
/// - Execute SQL queries
/// - Execute inserts
/// - Execute updates
/// - Execute dynamic schema operations
class DriftDatasource {
  final dynamic db; // Your Drift database instance

  DriftDatasource(this.db);

  /// Execute a raw SQL query and return result rows.
  Future<List<Map<String, dynamic>>> query(
    String sql, {
    List<dynamic>? arguments,
  }) async {
    final variables = arguments?.map((e) => Variable(e)).toList();

    final result = await db
        .customSelect(
          sql,
          variables: variables ?? const [],
        )
        .get();

    return result
        .map<Map<String, dynamic>>(
          (row) => Map<String, dynamic>.from(row.data),
        )
        .toList();
  }

  /// Execute a raw SQL command (INSERT/UPDATE/DELETE).
  Future<void> execute(String sql) async {
    await db.customStatement(sql);
  }

  /// Executes operations inside a database transaction.
  ///
  /// If any operation fails, the entire transaction is rolled back.
  Future<void> runInTransaction(Future<void> Function() action) async {
    await db.transaction(() async {
      await action();
    });
  }

  /// Executes a raw SQL command with bound parameters.
  ///
  /// Used for parameterized DML operations (INSERT, UPDATE, DELETE)
  /// to prevent SQL injection.
  ///
  /// [sql] → SQL statement with placeholders (?)
  /// [args] → values bound to placeholders
  ///
  /// Example:
  /// await datasource.executeWithArgs(
  ///   'UPDATE my_table SET col1 = ? WHERE id = ?',
  ///   ['new value', 123],
  /// );
  Future<void> executeWithArgs(
    String sql,
    List<dynamic> args,
  ) async {
    await db.customStatement(sql, args);
  }
}
