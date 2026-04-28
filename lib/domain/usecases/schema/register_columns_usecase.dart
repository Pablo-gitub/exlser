import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/repositories/schema_repository.dart';
/// Persists column metadata for a dataset table.
///
/// Columns are inferred from the imported dataset and then stored
/// as metadata in the database.
///
/// Responsibilities:
/// - receive inferred columns
/// - attach them to a dataset table
/// - persist them through SchemaRepository
///
/// Dependencies:
/// - SchemaRepository
///
/// Expected flow:
/// 1. Receive tableId and inferred columns
/// 2. associate columns with datasetTableId
/// 3. persist column metadata via repository
class RegisterColumnsUseCase {
  final SchemaRepository repository;

  RegisterColumnsUseCase({
    required this.repository,
  });

  /// Persists dataset columns metadata.
  Future<void> call({
    required int datasetTableId,
    required List<DatasetColumn> columns,
  }) async {
    if (columns.isEmpty) {
      throw Exception(
        'Cannot register empty column list',
      );
    }

    final updatedColumns = columns.map((column) {
      return column.copyWith(
        datasetTableId: datasetTableId,
      );
    }).toList();

    await repository.createColumns(updatedColumns);
  }
}