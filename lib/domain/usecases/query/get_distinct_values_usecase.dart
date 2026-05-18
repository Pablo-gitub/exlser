import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/repositories/query_repository.dart';

/// Retrieves distinct values for a specific column.
///
/// Used by the UI to build filtering suggestions such as dropdowns or
/// autocomplete options for text and boolean columns.
class GetDistinctValuesUseCase {
  final QueryRepository repository;

  const GetDistinctValuesUseCase({
    required this.repository,
  });

  Future<List<dynamic>> call({
    required String tableName,
    required DatasetColumn column,
  }) {
    if (tableName.trim().isEmpty) {
      throw ArgumentError('Table name cannot be empty');
    }

    if (column.dbName.trim().isEmpty) {
      throw ArgumentError('Column dbName cannot be empty');
    }

    return repository.getDistinctValues(
      tableName: tableName,
      column: column,
    );
  }
}
