import 'package:exlser/core/sql/sql_statement_analyzer.dart';

class ReadOnlySqlValidation {
  final String originalSql;
  final String normalizedSql;
  final String executableSql;

  const ReadOnlySqlValidation({
    required this.originalSql,
    required this.normalizedSql,
    required this.executableSql,
  });
}

class ReadOnlyQueryException implements Exception {
  final String code;

  const ReadOnlyQueryException(this.code);

  @override
  String toString() => 'ReadOnlyQueryException($code)';
}

/// The read-only boundary for user-authored SQL.
///
/// Accepts a single `SELECT` that reads only the tables the caller allows, and
/// returns it wrapped in a hard row limit. Validation runs on the parsed
/// statement rather than on the text: a comma-joined table
/// (`SELECT * FROM sheet, other_dataset` or `…, sqlite_master`) used to slip past
/// the `FROM`/`JOIN` regular expression, and scanning raw text for blocked
/// keywords rejected safe queries such as `WHERE note = 'update'`.
class ReadOnlySqlValidator {
  static const String emptyCode = 'empty';
  static const String notSelectCode = 'not_select';
  static const String unsafeStatementCode = 'unsafe_statement';
  static const String multipleStatementsCode = 'multiple_statements';
  static const String unknownTableCode = 'unknown_table';
  static const String invalidLimitCode = 'invalid_limit';
  static const String invalidSyntaxCode = 'invalid_syntax';

  final SqlStatementAnalyzer analyzer;

  const ReadOnlySqlValidator({
    this.analyzer = const SqlStatementAnalyzer(),
  });

  ReadOnlySqlValidation validate({
    required String sql,
    required Set<String> allowedTableNames,
    required String activeTableName,
    required int limit,
  }) {
    final trimmedSql = sql.trim();
    final trimmedActiveTable = activeTableName.trim();
    final safeAllowedTableNames = {
      for (final tableName in allowedTableNames)
        if (tableName.trim().isNotEmpty) tableName.trim(),
    };

    if (trimmedSql.isEmpty) {
      throw const ReadOnlyQueryException(emptyCode);
    }

    if (trimmedActiveTable.isEmpty ||
        !safeAllowedTableNames.contains(trimmedActiveTable)) {
      throw const ReadOnlyQueryException(unknownTableCode);
    }

    if (limit <= 0) {
      throw const ReadOnlyQueryException(invalidLimitCode);
    }

    final normalizedSql = _replaceActiveSheetAlias(
      trimmedSql,
      activeTableName: trimmedActiveTable,
    );

    final analysis = analyzer.analyze(normalizedSql);

    if (analysis.hasMultipleStatements) {
      throw const ReadOnlyQueryException(multipleStatementsCode);
    }

    switch (analysis.kind) {
      case SqlStatementKind.invalid:
        throw const ReadOnlyQueryException(invalidSyntaxCode);
      case SqlStatementKind.write:
        throw const ReadOnlyQueryException(unsafeStatementCode);
      case SqlStatementKind.other:
        throw const ReadOnlyQueryException(notSelectCode);
      case SqlStatementKind.select:
        break;
    }

    // A table-valued function is a source we cannot allowlist (pragma_table_info
    // and friends expose the whole schema), so none is accepted.
    if (analysis.tableValuedFunctions.isNotEmpty) {
      throw const ReadOnlyQueryException(unsafeStatementCode);
    }

    for (final function in analysis.functionNames) {
      if (SqlStatementAnalyzer.dangerousFunctions.contains(function)) {
        throw const ReadOnlyQueryException(unsafeStatementCode);
      }
    }

    final lowerCasedAllowed = {
      for (final name in safeAllowedTableNames) name.toLowerCase(),
    };
    final lowerCasedCtes = {
      for (final name in analysis.cteNames) name.toLowerCase(),
    };

    for (final table in analysis.referencedTables) {
      final normalized = table.trim().toLowerCase();
      // SQLite identifiers are case-insensitive, and a name introduced by the
      // statement's own WITH clause is not a dataset table.
      if (lowerCasedCtes.contains(normalized)) continue;
      if (!lowerCasedAllowed.contains(normalized)) {
        throw const ReadOnlyQueryException(unknownTableCode);
      }
    }

    return ReadOnlySqlValidation(
      originalSql: trimmedSql,
      normalizedSql: normalizedSql,
      executableSql: 'SELECT * FROM ($normalizedSql) LIMIT $limit',
    );
  }

  String _replaceActiveSheetAlias(
    String sql, {
    required String activeTableName,
  }) {
    return sql
        .replaceAllMapped(
          RegExp(r'\b(from|join)\s+sheet\b', caseSensitive: false),
          (match) => '${match.group(1)} $activeTableName',
        )
        .replaceAllMapped(
          RegExp(r'\b(from|join)\s+"sheet"', caseSensitive: false),
          (match) => '${match.group(1)} $activeTableName',
        );
  }
}
