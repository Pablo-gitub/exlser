import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/entities/dataset_table.dart';
import 'package:exel_category/domain/repositories/schema_repository.dart';

import 'package:exel_category/data/datasources/drift_datasource.dart';
import 'package:exel_category/data/schema/dynamic_table_builder.dart';

/// Concrete implementation of [SchemaRepository].
///
/// Responsible for storing dataset schema metadata and
/// creating/dropping dynamic SQL tables.
class SchemaRepositoryImpl implements SchemaRepository {
  final DriftDatasource datasource;
  final DynamicTableBuilder tableBuilder;

  SchemaRepositoryImpl(
    this.datasource,
    this.tableBuilder,
  );

  @override
  Future<List<DatasetTable>> getTablesForDataset(int datasetId) async {
    /// TODO:
    /// Retrieve all tables belonging to a dataset.
    ///
    /// Steps:
    /// 1. Query dataset_tables metadata table
    /// 2. Map rows to DatasetTable entities
    throw UnimplementedError();
  }

  @override
  Future<DatasetTable?> getTableById(int tableId) async {
    /// TODO:
    /// Retrieve a single dataset table metadata entry.
    throw UnimplementedError();
  }

  @override
  Future<DatasetTable> createDatasetTable(DatasetTable table) async {
    /// TODO:
    /// Persist table metadata.
    ///
    /// Steps:
    /// 1. Insert row into dataset_tables metadata table
    /// 2. Return DatasetTable entity with generated id
    throw UnimplementedError();
  }

  @override
  Future<void> updateDatasetTable(DatasetTable table) async {
    /// TODO:
    /// Update metadata fields such as rowCount or colCount.
    throw UnimplementedError();
  }

  @override
  Future<void> deleteDatasetTable(int tableId) async {
    /// TODO:
    /// Delete table metadata entry.
    ///
    /// Note:
    /// Dynamic SQL table must also be dropped.
    throw UnimplementedError();
  }

  @override
  Future<List<DatasetColumn>> getColumnsForTable(int tableId) async {
    /// TODO:
    /// Retrieve all columns for a given table.
    ///
    /// Steps:
    /// 1. Query dataset_columns metadata table
    /// 2. Map rows to DatasetColumn entities
    throw UnimplementedError();
  }

  @override
  Future<void> createColumns(List<DatasetColumn> columns) async {
    /// TODO:
    /// Insert column metadata records.
    ///
    /// Steps:
    /// 1. Insert each column into dataset_columns table
    /// 2. Ensure correct table association
    throw UnimplementedError();
  }

  @override
  Future<void> updateColumn(DatasetColumn column) async {
    /// TODO:
    /// Update column metadata.
    ///
    /// Example:
    /// user overrides inferred type.
    throw UnimplementedError();
  }

  @override
  Future<void> deleteColumnsForTable(int tableId) async {
    /// TODO:
    /// Delete all columns belonging to a table.
    throw UnimplementedError();
  }

  @override
  Future<void> createDynamicTable(
    String tableName,
    List<DatasetColumn> columns,
  ) async {
    /// TODO:
    /// Delegate table creation to DynamicTableBuilder.
    ///
    /// Steps:
    /// 1. Validate column metadata
    /// 2. Generate SQL schema
    /// 3. Execute CREATE TABLE
    await tableBuilder.createTable();
  }

  @override
  Future<void> dropDynamicTable(String tableName) async {
    /// TODO:
    /// Drop SQL table from database.
    ///
    /// Steps:
    /// 1. Build DROP TABLE statement
    /// 2. Execute via datasource
    throw UnimplementedError();
  }
}