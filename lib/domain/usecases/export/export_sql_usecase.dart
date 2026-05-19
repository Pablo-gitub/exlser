import 'dart:convert';
import 'dart:typed_data';

import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/entities/exported_file.dart';
import 'package:exel_category/domain/usecases/export/export_dataset_data.dart';
import 'package:exel_category/domain/value_objects/export_format.dart';

class ExportSqlUseCase {
  const ExportSqlUseCase();

  ExportedFile call(ExportDatasetData data) {
    final buffer = StringBuffer()
      ..writeln('-- ExlSer dataset export')
      ..writeln('-- Dataset: ${data.dataset.name}')
      ..writeln();

    for (final table in data.tables) {
      buffer
        ..writeln(
          'DROP TABLE IF EXISTS ${_identifier(table.table.sqlTableName)};',
        )
        ..writeln(_createTableSql(table.columns, table.table.sqlTableName))
        ..writeln();

      for (final row in table.rows) {
        buffer
            .writeln(_insertSql(table.columns, table.table.sqlTableName, row));
      }

      buffer.writeln();
    }

    return ExportedFile(
      name: _sanitizeFileName(data.dataset.name, fallback: 'dataset'),
      extension: ExportFormat.sql.extension,
      mimeType: 'application/sql',
      format: ExportFormat.sql,
      bytes: Uint8List.fromList(utf8.encode(buffer.toString())),
    );
  }

  String _createTableSql(List<DatasetColumn> columns, String tableName) {
    final definitions = columns
        .map(
          (column) =>
              '  ${_identifier(column.dbName)} ${column.declaredType.toSqlType()}',
        )
        .join(',\n');

    return 'CREATE TABLE ${_identifier(tableName)} (\n$definitions\n);';
  }

  String _insertSql(
    List<DatasetColumn> columns,
    String tableName,
    Map<String, dynamic> row,
  ) {
    final columnNames =
        columns.map((column) => _identifier(column.dbName)).join(', ');
    final values =
        columns.map((column) => _literal(row[column.dbName])).join(', ');

    return 'INSERT INTO ${_identifier(tableName)} ($columnNames) VALUES ($values);';
  }

  String _identifier(String value) {
    return '"${value.replaceAll('"', '""')}"';
  }

  String _literal(dynamic value) {
    if (value == null) return 'NULL';
    if (value is bool) return value ? '1' : '0';
    if (value is num) return value.toString();
    return "'${value.toString().replaceAll("'", "''")}'";
  }

  String _sanitizeFileName(String value, {required String fallback}) {
    final sanitized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    return sanitized.isEmpty ? fallback : sanitized;
  }
}
