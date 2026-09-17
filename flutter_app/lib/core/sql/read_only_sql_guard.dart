import 'package:exlser/core/sql/sql_statement_analyzer.dart';

/// Raised when SQL that is supposed to be read-only would change the database.
class UnsafeRawQueryException implements Exception {
  final String reason;
  final String sql;

  const UnsafeRawQueryException({required this.reason, required this.sql});

  @override
  String toString() => 'UnsafeRawQueryException($reason): $sql';
}

/// Enforces "one read-only statement" on raw SQL at the database boundary.
///
/// The allowlist validation of user-authored SQL lives in the domain
/// ([ReadOnlySqlValidator]), but the repository also accepts SQL built in code —
/// analytics, filters, relationship sampling — and used to run it unchecked, so
/// the read-only guarantee held only as long as every caller remembered it. This
/// guard makes it a property of the call itself: cheap, and no callsite can
/// forget it.
class ReadOnlySqlGuard {
  final SqlStatementAnalyzer analyzer;

  const ReadOnlySqlGuard({
    this.analyzer = const SqlStatementAnalyzer(),
  });

  /// Throws [UnsafeRawQueryException] unless [sql] is a single SELECT.
  void assertSingleSelect(String sql) {
    final trimmed = sql.trim();
    if (trimmed.isEmpty) {
      throw UnsafeRawQueryException(reason: 'empty', sql: sql);
    }

    final analysis = analyzer.analyze(trimmed);

    if (analysis.hasMultipleStatements) {
      throw UnsafeRawQueryException(reason: 'multiple_statements', sql: sql);
    }

    switch (analysis.kind) {
      case SqlStatementKind.select:
        break;
      case SqlStatementKind.invalid:
        throw UnsafeRawQueryException(reason: 'invalid_syntax', sql: sql);
      case SqlStatementKind.write:
      case SqlStatementKind.other:
        throw UnsafeRawQueryException(reason: 'not_read_only', sql: sql);
    }

    if (analysis.tableValuedFunctions.isNotEmpty) {
      throw UnsafeRawQueryException(reason: 'table_valued_function', sql: sql);
    }

    for (final function in analysis.functionNames) {
      if (SqlStatementAnalyzer.dangerousFunctions.contains(function)) {
        throw UnsafeRawQueryException(reason: 'unsafe_function', sql: sql);
      }
    }
  }
}
