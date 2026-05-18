import 'package:exel_category/domain/repositories/query_repository.dart';

/// Inserts dataset rows into the dynamically created SQL table.
///
/// After the table schema has been created, rows extracted from the
/// source file are inserted into the table.
///
/// Responsibilities:
/// - validate input data
/// - perform batch insert operations
///
/// Dependencies:
/// - QueryRepository
class InsertRowsUseCase {
  final QueryRepository repository;

  InsertRowsUseCase(this.repository);

  /// Executes batch insertion of parsed rows.
  ///
  /// [tableName] → target SQL table
  /// [rows] → parsed rows (already mapped as key-value)
  Future<void> call({
    required String tableName,
    required List<Map<String, dynamic>> rows,
  }) async {
    /// Validate input
    if (tableName.trim().isEmpty) {
      throw Exception('Table name cannot be empty');
    }

    if (rows.isEmpty) {
      /// Nothing to insert → early return (no error)
      return;
    }

    /// Perform batch insert via repository
    await repository.insertBatch(
      tableName: tableName,
      rows: rows,
    );
  }
}
