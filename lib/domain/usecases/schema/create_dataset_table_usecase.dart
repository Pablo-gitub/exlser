import 'package:exel_category/data/adapters/sanitizers/sql_name_sanitizer.dart';
import 'package:exel_category/domain/entities/dataset_table.dart';
import 'package:exel_category/domain/repositories/schema_repository.dart';
/// Creates metadata for a dataset table.
///
/// A dataset table corresponds to one sheet (or logical table)
/// extracted from an imported file.
///
/// Responsibilities:
/// - create DatasetTable entity
/// - persist table metadata
///
/// Dependencies:
/// - SchemaRepository
///
/// Expected flow:
/// 1. Receive datasetId and sheet name
/// 2. Generate SQL-safe table name
/// 3. Create DatasetTable entity
/// 4. Persist metadata using repository
/// 5. Return created DatasetTable
class CreateDatasetTableUseCase {
  final SchemaRepository repository;

  CreateDatasetTableUseCase({
    required this.repository,
  });

  /// Creates and persists a dataset table.
  Future<DatasetTable> call({
    required int datasetId,
    required String sheetName,
    required int rowCount,
    required int colCount,
  }) async {
    final trimmedSheetName = sheetName.trim();

    if (trimmedSheetName.isEmpty) {
      throw Exception(
        'Sheet name cannot be empty',
      );
    }

    final sqlTableName = SqlNameSanitizer.sanitize(
      '${datasetId}_$trimmedSheetName',
    );

    final table = DatasetTable(
      id: 0,
      datasetId: datasetId,
      sheetNameOriginal: trimmedSheetName,
      sqlTableName: sqlTableName,
      rowCount: rowCount,
      colCount: colCount,
    );

    return repository.createDatasetTable(table);
  }
}