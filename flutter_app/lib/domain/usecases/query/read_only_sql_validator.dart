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

class ReadOnlySqlValidator {
  static const String emptyCode = 'empty';
  static const String notSelectCode = 'not_select';
  static const String unsafeStatementCode = 'unsafe_statement';
  static const String multipleStatementsCode = 'multiple_statements';
  static const String unknownTableCode = 'unknown_table';
  static const String invalidLimitCode = 'invalid_limit';

  static const Set<String> _blockedKeywords = {
    'insert',
    'update',
    'delete',
    'drop',
    'alter',
    'create',
    'replace',
    'attach',
    'detach',
    'pragma',
    'vacuum',
    'reindex',
    'analyze',
    'begin',
    'commit',
    'rollback',
    'savepoint',
    'release',
    'grant',
    'revoke',
    'truncate',
  };

  const ReadOnlySqlValidator();

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

    if (trimmedSql.contains(';') ||
        trimmedSql.contains('--') ||
        trimmedSql.contains('/*') ||
        trimmedSql.contains('*/')) {
      throw const ReadOnlyQueryException(multipleStatementsCode);
    }

    if (!RegExp(r'^\s*select\b', caseSensitive: false).hasMatch(trimmedSql)) {
      throw const ReadOnlyQueryException(notSelectCode);
    }

    for (final keyword in _blockedKeywords) {
      if (RegExp('\\b$keyword\\b', caseSensitive: false).hasMatch(trimmedSql)) {
        throw const ReadOnlyQueryException(unsafeStatementCode);
      }
    }

    final normalizedSql = _replaceActiveSheetAlias(
      trimmedSql,
      activeTableName: trimmedActiveTable,
    );
    final referencedTables = _referencedTables(normalizedSql);

    for (final tableName in referencedTables) {
      if (!safeAllowedTableNames.contains(tableName)) {
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

  Set<String> _referencedTables(String sql) {
    final tablePattern = RegExp(
      r'\b(?:from|join)\s+("[^"]+"|`[^`]+`|\[[^\]]+\]|[A-Za-z_][A-Za-z0-9_]*)',
      caseSensitive: false,
    );

    return {
      for (final match in tablePattern.allMatches(sql))
        _unquoteIdentifier(match.group(1) ?? ''),
    };
  }

  String _unquoteIdentifier(String value) {
    final trimmed = value.trim();
    if (trimmed.length >= 2 &&
        ((trimmed.startsWith('"') && trimmed.endsWith('"')) ||
            (trimmed.startsWith('`') && trimmed.endsWith('`')) ||
            (trimmed.startsWith('[') && trimmed.endsWith(']')))) {
      return trimmed.substring(1, trimmed.length - 1);
    }

    return trimmed;
  }
}
