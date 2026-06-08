import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/entities/dataset_table.dart';
import 'package:exlser/domain/repositories/schema_repository.dart';

/// Builds the physical SQL table for storing dataset rows.
///
/// The structure of the table is derived from DatasetColumn metadata.
///
/// Responsibilities:
/// - validate schema metadata
/// - delegate dynamic table creation to repository
///
/// Dependencies:
/// - SchemaRepository
///
/// Expected flow:
/// 1. Receive DatasetTable metadata
/// 2. Receive DatasetColumn list
/// 3. Validate schema
/// 4. Call repository.createDynamicTable()
class BuildDynamicTableUseCase {
  final SchemaRepository repository;

  const BuildDynamicTableUseCase({
    required this.repository,
  });

  /// Creates the physical SQL table.
  Future<void> call({
    required DatasetTable table,
    required List<DatasetColumn> columns,
  }) async {
    /// Prevent creation of empty tables.
    if (columns.isEmpty) {
      throw Exception(
        'Cannot create dynamic table without columns',
      );
    }

    /// Delegate SQL generation and execution
    /// to repository layer.
    await repository.createDynamicTable(
      table.sqlTableName,
      columns,
    );
  }
}
