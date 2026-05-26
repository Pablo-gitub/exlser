//lib/domain/repositories/schema_repository.dart
import 'package:exlser/domain/entities/dataset_table.dart';
import 'package:exlser/domain/entities/dataset_column.dart';

/// Repository contract responsible for managing dataset schema.
///
/// The schema describes how Excel sheets are mapped into relational tables.
/// It handles sheet metadata, column metadata and the creation of
/// dynamic SQL tables used to store imported data.
abstract class SchemaRepository {
  /// Returns all tables belonging to a dataset.
  Future<List<DatasetTable>> getTablesForDataset(int datasetId);

  /// Returns a specific table by id.
  Future<DatasetTable?> getTableById(int tableId);

  /// Creates metadata for a new table generated from an Excel sheet.
  Future<DatasetTable> createDatasetTable(DatasetTable table);

  /// Updates table metadata such as row count or column count.
  Future<void> updateDatasetTable(DatasetTable table);

  /// Deletes table metadata.
  Future<void> deleteDatasetTable(int tableId);

  /// Returns all columns belonging to a table.
  Future<List<DatasetColumn>> getColumnsForTable(int tableId);

  /// Inserts column metadata for a table.
  Future<void> createColumns(List<DatasetColumn> columns);

  /// Updates column metadata (e.g. declaredType change by user).
  Future<void> updateColumn(DatasetColumn column);

  /// Deletes all columns belonging to a table.
  Future<void> deleteColumnsForTable(int tableId);

  /// Creates the physical SQL table used to store dataset data.
  ///
  /// The schema is derived from the provided column metadata.
  Future<void> createDynamicTable(
    String tableName,
    List<DatasetColumn> columns,
  );

  /// Drops a dynamic SQL table.
  Future<void> dropDynamicTable(String tableName);

  /// Deletes schema metadata and dynamic tables for a given dataset
  Future<void> deleteSchemaForDataset(int datasetId);
}
