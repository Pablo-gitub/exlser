import 'package:exlser/domain/repositories/query_repository.dart';

/// Retrieves rows from a dataset table.
///
/// This use case provides paginated access to dataset rows
/// stored inside a dynamically generated SQL table.
///
/// Responsibilities:
/// - request rows from QueryRepository
/// - support pagination parameters
///
/// Dependencies:
/// - QueryRepository
///
/// Expected flow:
/// 1. Receive tableName
/// 2. Optionally receive limit and offset
/// 3. Call repository.fetchRows()
/// 4. Return resulting rows
class FetchRowsUseCase {
  final QueryRepository repository;

  const FetchRowsUseCase({
    required this.repository,
  });

  Future<List<Map<String, dynamic>>> call({
    required String tableName,
    int? limit,
    int? offset,
  }) async {
    return await repository.fetchRows(
        tableName: tableName, limit: limit, offset: offset);
  }
}
