import 'dart:typed_data';

import 'package:excel_community/excel_community.dart';
import 'package:exlser/domain/entities/exported_file.dart';
import 'package:exlser/domain/usecases/export/export_dataset_data.dart';
import 'package:exlser/domain/value_objects/export_format.dart';

class ExportExcelUseCase {
  const ExportExcelUseCase();

  ExportedFile call(ExportDatasetData data) {
    final excel = Excel.createExcel();
    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    for (final table in data.tables) {
      final sheetName = _uniqueSheetName(
        _sanitizeSheetName(table.table.sheetNameOriginal),
        excel.tables.keys.toSet(),
      );
      final sheet = excel[sheetName];

      for (var columnIndex = 0;
          columnIndex < table.columns.length;
          columnIndex++) {
        sheet.updateCell(
          CellIndex.indexByColumnRow(
            columnIndex: columnIndex,
            rowIndex: 0,
          ),
          TextCellValue(table.columns[columnIndex].originalName),
        );
      }

      for (var rowIndex = 0; rowIndex < table.rows.length; rowIndex++) {
        final row = table.rows[rowIndex];
        for (var columnIndex = 0;
            columnIndex < table.columns.length;
            columnIndex++) {
          final column = table.columns[columnIndex];
          sheet.updateCell(
            CellIndex.indexByColumnRow(
              columnIndex: columnIndex,
              rowIndex: rowIndex + 1,
            ),
            _toCellValue(row[column.dbName]),
          );
        }
      }
    }

    final bytes = excel.save();
    if (bytes == null || bytes.isEmpty) {
      throw StateError('Could not generate Excel export');
    }

    return ExportedFile(
      name: _sanitizeFileName(data.dataset.name, fallback: 'dataset'),
      extension: ExportFormat.excel.extension,
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      format: ExportFormat.excel,
      bytes: Uint8List.fromList(bytes),
    );
  }

  CellValue? _toCellValue(dynamic value) {
    if (value == null) return null;
    if (value is bool) return BoolCellValue(value);
    if (value is int) return IntCellValue(value);
    if (value is double) return DoubleCellValue(value);
    if (value is num) return DoubleCellValue(value.toDouble());
    return TextCellValue(value.toString());
  }

  String _sanitizeSheetName(String value) {
    final sanitized = value
        .trim()
        .replaceAll(RegExp(r'[\[\]\:\*\?\/\\]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
    final fallback = sanitized.isEmpty ? 'Sheet' : sanitized;
    return fallback.length > 31 ? fallback.substring(0, 31) : fallback;
  }

  String _uniqueSheetName(String baseName, Set<String> existingNames) {
    var name = baseName;
    var counter = 2;

    while (existingNames.contains(name)) {
      final suffix = ' $counter';
      final maxBaseLength = 31 - suffix.length;
      final trimmedBase = baseName.length > maxBaseLength
          ? baseName.substring(0, maxBaseLength)
          : baseName;
      name = '$trimmedBase$suffix';
      counter++;
    }

    return name;
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
