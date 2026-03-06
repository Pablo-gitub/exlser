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

  // TODO:
  // - inject QueryRepository
  // - implement call(tableName, limit?, offset?)
  // - retrieve rows using repository
  // - return rows as List<Map<String, dynamic>>

}