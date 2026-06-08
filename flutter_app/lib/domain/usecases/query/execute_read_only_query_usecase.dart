import 'package:exlser/domain/repositories/query_repository.dart';
import 'package:exlser/domain/usecases/query/read_only_sql_validator.dart';

class ReadOnlyQueryResult {
  final List<Map<String, dynamic>> rows;
  final String executedSql;
  final int rowCount;

  const ReadOnlyQueryResult({
    required this.rows,
    required this.executedSql,
    required this.rowCount,
  });
}

class ExecuteReadOnlyQueryUseCase {
  final QueryRepository repository;
  final ReadOnlySqlValidator validator;

  const ExecuteReadOnlyQueryUseCase({
    required this.repository,
    this.validator = const ReadOnlySqlValidator(),
  });

  Future<ReadOnlyQueryResult> call({
    required String sql,
    required String activeTableName,
    required Set<String> allowedTableNames,
    required int limit,
  }) async {
    final validation = validator.validate(
      sql: sql,
      activeTableName: activeTableName,
      allowedTableNames: allowedTableNames,
      limit: limit,
    );

    final countSourceSql = _stripTopLevelLimit(validation.normalizedSql);
    final countSql = 'SELECT COUNT(*) AS __row_count FROM ($countSourceSql)';
    final results = await Future.wait([
      repository.executeRawQuery(validation.executableSql, null),
      repository.executeRawQuery(countSql, null),
    ]);
    final rows = results[0];
    final countRows = results[1];

    return ReadOnlyQueryResult(
      rows: rows,
      executedSql: validation.executableSql,
      rowCount: _readRowCount(countRows),
    );
  }
}

int _readRowCount(List<Map<String, dynamic>> rows) {
  if (rows.isEmpty) return 0;

  final value = rows.first['__row_count'];
  if (value is int) return value;
  if (value is num) return value.toInt();

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _stripTopLevelLimit(String sql) {
  var depth = 0;
  var inSingleQuote = false;
  var inDoubleQuote = false;
  var inBacktick = false;
  var inBracket = false;
  int? limitIndex;

  for (var i = 0; i < sql.length; i++) {
    final char = sql[i];

    if (inSingleQuote) {
      if (char == "'" && i + 1 < sql.length && sql[i + 1] == "'") {
        i += 1;
        continue;
      }
      if (char == "'") inSingleQuote = false;
      continue;
    }

    if (inDoubleQuote) {
      if (char == '"') inDoubleQuote = false;
      continue;
    }

    if (inBacktick) {
      if (char == '`') inBacktick = false;
      continue;
    }

    if (inBracket) {
      if (char == ']') inBracket = false;
      continue;
    }

    if (char == "'") {
      inSingleQuote = true;
      continue;
    }
    if (char == '"') {
      inDoubleQuote = true;
      continue;
    }
    if (char == '`') {
      inBacktick = true;
      continue;
    }
    if (char == '[') {
      inBracket = true;
      continue;
    }
    if (char == '(') {
      depth += 1;
      continue;
    }
    if (char == ')' && depth > 0) {
      depth -= 1;
      continue;
    }

    if (depth == 0 && _startsKeywordAt(sql, i, 'limit')) {
      limitIndex = i;
    }
  }

  if (limitIndex == null) return sql;

  final stripped = sql.substring(0, limitIndex).trimRight();
  return stripped.isEmpty ? sql : stripped;
}

bool _startsKeywordAt(String sql, int index, String keyword) {
  final end = index + keyword.length;
  if (end > sql.length) return false;
  if (sql.substring(index, end).toLowerCase() != keyword) return false;

  final before = index == 0 ? '' : sql[index - 1];
  final after = end >= sql.length ? '' : sql[end];

  return !_isIdentifierChar(before) && !_isIdentifierChar(after);
}

bool _isIdentifierChar(String char) {
  if (char.isEmpty) return false;
  final code = char.codeUnitAt(0);
  return (code >= 65 && code <= 90) ||
      (code >= 97 && code <= 122) ||
      (code >= 48 && code <= 57) ||
      char == '_';
}
