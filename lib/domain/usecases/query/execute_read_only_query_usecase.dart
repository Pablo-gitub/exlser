import 'package:exlser/domain/repositories/query_repository.dart';
import 'package:exlser/domain/usecases/query/read_only_sql_validator.dart';

class ReadOnlyQueryResult {
  final List<Map<String, dynamic>> rows;
  final String executedSql;

  const ReadOnlyQueryResult({
    required this.rows,
    required this.executedSql,
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

    final rows = await repository.executeRawQuery(
      validation.executableSql,
      null,
    );

    return ReadOnlyQueryResult(
      rows: rows,
      executedSql: validation.executableSql,
    );
  }
}
