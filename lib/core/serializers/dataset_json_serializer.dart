import 'dart:convert';

import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/usecases/export/export_dataset_data.dart';

class DatasetJsonSerializer {
  const DatasetJsonSerializer._();

  static Map<String, Object?> dataset(ExportDatasetData data) {
    final usedSheetNames = <String>{};

    return {
      for (final table in data.tables)
        _uniqueSheetName(table.table.sheetNameOriginal, usedSheetNames):
            tableRows(table),
    };
  }

  static List<Map<String, Object?>> tableRows(ExportTableData table) {
    return [
      for (final row in table.rows) rowMap(columns: table.columns, row: row),
    ];
  }

  static Map<String, Object?> rowMap({
    required List<DatasetColumn> columns,
    required Map<String, dynamic> row,
  }) {
    return {
      for (final column in columns)
        column.originalName: _jsonSafeValue(row[column.dbName]),
    };
  }

  static String compactRowJson({
    required List<DatasetColumn> columns,
    required Map<String, dynamic> row,
  }) {
    return jsonEncode(
      DatasetJsonSerializer.rowMap(
        columns: columns,
        row: row,
      ),
    );
  }

  static Object? _jsonSafeValue(dynamic value) {
    if (value == null ||
        value is String ||
        value is num ||
        value is bool ||
        value is List ||
        value is Map) {
      return value;
    }

    return value.toString();
  }

  static String _uniqueSheetName(String rawName, Set<String> usedNames) {
    final fallback = rawName.trim().isEmpty ? 'Sheet' : rawName.trim();
    var name = fallback;
    var suffix = 2;

    while (usedNames.contains(name)) {
      name = '$fallback $suffix';
      suffix++;
    }

    usedNames.add(name);
    return name;
  }
}
