import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/entities/dataset_table.dart';
import 'package:exel_category/domain/repositories/schema_repository.dart';
import 'package:exel_category/domain/value_objects/column_type.dart';

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
    _validateId(datasetId, 'Dataset id');

    final rows = await datasource.query(
      '''
      SELECT id, dataset_id, sheet_name_original, sql_table_name, row_count, col_count
      FROM dataset_tables
      WHERE dataset_id = ?
      ORDER BY id ASC
      ''',
      arguments: [datasetId],
    );

    return rows.map(_mapTableRow).toList();
  }

  @override
  Future<DatasetTable?> getTableById(int tableId) async {
    _validateId(tableId, 'Table id');

    final rows = await datasource.query(
      '''
      SELECT id, dataset_id, sheet_name_original, sql_table_name, row_count, col_count
      FROM dataset_tables
      WHERE id = ?
      LIMIT 1
      ''',
      arguments: [tableId],
    );

    if (rows.isEmpty) return null;

    return _mapTableRow(rows.first);
  }

  @override
  Future<DatasetTable> createDatasetTable(DatasetTable table) async {
    _validateTable(table);

    await datasource.executeWithArgs(
      '''
      INSERT INTO dataset_tables (
        dataset_id,
        sheet_name_original,
        sql_table_name,
        row_count,
        col_count
      ) VALUES (?, ?, ?, ?, ?)
      ''',
      [
        table.datasetId,
        table.sheetNameOriginal.trim(),
        table.sqlTableName.trim(),
        table.rowCount,
        table.colCount,
      ],
    );

    final id = await _lastInsertId();

    return table.copyWith(
      id: id,
      sheetNameOriginal: table.sheetNameOriginal.trim(),
      sqlTableName: table.sqlTableName.trim(),
    );
  }

  @override
  Future<void> updateDatasetTable(DatasetTable table) async {
    _validateId(table.id, 'Table id');
    _validateTable(table);

    final existing = await getTableById(table.id);
    if (existing == null) {
      throw StateError('Dataset table not found: ${table.id}');
    }

    await datasource.executeWithArgs(
      '''
      UPDATE dataset_tables
      SET dataset_id = ?,
          sheet_name_original = ?,
          sql_table_name = ?,
          row_count = ?,
          col_count = ?
      WHERE id = ?
      ''',
      [
        table.datasetId,
        table.sheetNameOriginal.trim(),
        table.sqlTableName.trim(),
        table.rowCount,
        table.colCount,
        table.id,
      ],
    );
  }

  @override
  Future<void> deleteDatasetTable(int tableId) async {
    _validateId(tableId, 'Table id');

    final table = await getTableById(tableId);
    if (table == null) {
      throw StateError('Dataset table not found: $tableId');
    }

    await datasource.runInTransaction(() async {
      await dropDynamicTable(table.sqlTableName);

      await datasource.executeWithArgs(
        'DELETE FROM dataset_columns WHERE dataset_table_id = ?',
        [tableId],
      );

      await datasource.executeWithArgs(
        'DELETE FROM dataset_tables WHERE id = ?',
        [tableId],
      );
    });
  }

  @override
  Future<List<DatasetColumn>> getColumnsForTable(int tableId) async {
    _validateId(tableId, 'Table id');

    final rows = await datasource.query(
      '''
      SELECT id,
             dataset_table_id,
             original_name,
             db_name,
             declared_type,
             inferred_type,
             nullable,
             stats_json
      FROM dataset_columns
      WHERE dataset_table_id = ?
      ORDER BY id ASC
      ''',
      arguments: [tableId],
    );

    return rows.map(_mapColumnRow).toList();
  }

  @override
  Future<void> createColumns(List<DatasetColumn> columns) async {
    if (columns.isEmpty) {
      throw Exception('Cannot create empty column list');
    }

    for (final column in columns) {
      _validateColumn(column);
    }

    await datasource.runInTransaction(() async {
      for (final column in columns) {
        await datasource.executeWithArgs(
          '''
          INSERT INTO dataset_columns (
            dataset_table_id,
            original_name,
            db_name,
            declared_type,
            inferred_type,
            nullable,
            stats_json
          ) VALUES (?, ?, ?, ?, ?, ?, ?)
          ''',
          [
            column.datasetTableId,
            column.originalName.trim(),
            column.dbName.trim(),
            column.declaredType.toSqlType(),
            column.inferredType.toSqlType(),
            column.nullable,
            column.statsJson,
          ],
        );
      }
    });
  }

  @override
  Future<void> updateColumn(DatasetColumn column) async {
    _validateId(column.id, 'Column id');
    _validateColumn(column);

    await datasource.executeWithArgs(
      '''
      UPDATE dataset_columns
      SET dataset_table_id = ?,
          original_name = ?,
          db_name = ?,
          declared_type = ?,
          inferred_type = ?,
          nullable = ?,
          stats_json = ?
      WHERE id = ?
      ''',
      [
        column.datasetTableId,
        column.originalName.trim(),
        column.dbName.trim(),
        column.declaredType.toSqlType(),
        column.inferredType.toSqlType(),
        column.nullable,
        column.statsJson,
        column.id,
      ],
    );
  }

  @override
  Future<void> deleteColumnsForTable(int tableId) async {
    _validateId(tableId, 'Table id');

    await datasource.executeWithArgs(
      'DELETE FROM dataset_columns WHERE dataset_table_id = ?',
      [tableId],
    );
  }

  @override
  Future<void> createDynamicTable(
    String tableName,
    List<DatasetColumn> columns,
  ) async {
    /// Prevent invalid table creation.
    if (columns.isEmpty) {
      throw Exception(
        'Cannot create dynamic table without columns',
      );
    }

    /// Generate SQL using builder.
    final sql = tableBuilder.buildCreateTableSql(
      tableName: tableName,
      columns: columns,
    );

    /// Execute CREATE TABLE statement.
    await datasource.execute(sql);
  }

  @override
  Future<void> dropDynamicTable(String tableName) async {
    /// DROP TABLE safely (avoids crash if table does not exist).
    final sql = 'DROP TABLE IF EXISTS $tableName';

    await datasource.execute(sql);
  }

  @override
  Future<void> deleteSchemaForDataset(int datasetId) async {
    if (datasetId <= 0) {
      throw Exception('Dataset id must be greater than 0');
    }

    final tables = await datasource.query(
      'SELECT id, sql_table_name FROM dataset_tables WHERE dataset_id = ?',
      arguments: [datasetId],
    );

    await datasource.runInTransaction(() async {
      for (final table in tables) {
        final tableId = table['id'];
        final tableName = table['sql_table_name'];

        if (tableName is String && tableName.trim().isNotEmpty) {
          await dropDynamicTable(tableName);
        }

        if (tableId is int) {
          await datasource.executeWithArgs(
            'DELETE FROM dataset_columns WHERE dataset_table_id = ?',
            [tableId],
          );
        }
      }

      await datasource.executeWithArgs(
        'DELETE FROM dataset_tables WHERE dataset_id = ?',
        [datasetId],
      );
    });
  }

  Future<int> _lastInsertId() async {
    final rows = await datasource.query(
      'SELECT last_insert_rowid() AS id',
    );

    if (rows.isEmpty || rows.first['id'] is! int) {
      throw StateError('Could not read generated id');
    }

    return rows.first['id'] as int;
  }

  DatasetTable _mapTableRow(Map<String, dynamic> row) {
    return DatasetTable(
      id: _readInt(row, 'id'),
      datasetId: _readInt(row, 'dataset_id'),
      sheetNameOriginal: _readString(row, 'sheet_name_original'),
      sqlTableName: _readString(row, 'sql_table_name'),
      rowCount: _readInt(row, 'row_count'),
      colCount: _readInt(row, 'col_count'),
    );
  }

  DatasetColumn _mapColumnRow(Map<String, dynamic> row) {
    return DatasetColumn(
      id: _readInt(row, 'id'),
      datasetTableId: _readInt(row, 'dataset_table_id'),
      originalName: _readString(row, 'original_name'),
      dbName: _readString(row, 'db_name'),
      declaredType: ColumnType.fromString(_readString(row, 'declared_type')),
      inferredType: ColumnType.fromString(_readString(row, 'inferred_type')),
      nullable: _readBool(row, 'nullable'),
      statsJson: row['stats_json'] as String?,
    );
  }

  int _readInt(Map<String, dynamic> row, String key) {
    final value = row[key];

    if (value is int) return value;

    throw StateError('Invalid integer value for $key');
  }

  String _readString(Map<String, dynamic> row, String key) {
    final value = row[key];

    if (value is String) return value;

    throw StateError('Invalid string value for $key');
  }

  bool _readBool(Map<String, dynamic> row, String key) {
    final value = row[key];

    if (value is bool) return value;
    if (value is int) return value == 1;

    throw StateError('Invalid boolean value for $key');
  }

  void _validateId(int id, String label) {
    if (id <= 0) {
      throw Exception('$label must be greater than 0');
    }
  }

  void _validateTable(DatasetTable table) {
    _validateId(table.datasetId, 'Dataset id');

    if (table.sheetNameOriginal.trim().isEmpty) {
      throw Exception('Sheet name cannot be empty');
    }

    if (table.sqlTableName.trim().isEmpty) {
      throw Exception('SQL table name cannot be empty');
    }

    if (table.rowCount < 0) {
      throw Exception('Row count cannot be negative');
    }

    if (table.colCount < 0) {
      throw Exception('Column count cannot be negative');
    }
  }

  void _validateColumn(DatasetColumn column) {
    _validateId(column.datasetTableId, 'Table id');

    if (column.originalName.trim().isEmpty) {
      throw Exception('Column name cannot be empty');
    }

    if (column.dbName.trim().isEmpty) {
      throw Exception('Database column name cannot be empty');
    }
  }
}
