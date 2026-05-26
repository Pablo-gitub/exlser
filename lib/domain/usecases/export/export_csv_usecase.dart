import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart' as csv;
import 'package:exlser/domain/entities/exported_file.dart';
import 'package:exlser/domain/usecases/export/export_dataset_data.dart';
import 'package:exlser/domain/value_objects/export_format.dart';

class ExportCsvUseCase {
  const ExportCsvUseCase();

  List<ExportedFile> call(ExportDatasetData data) {
    return [
      for (final table in data.tables)
        ExportedFile(
          name: _fileBaseName(data.dataset.name, table.table.sheetNameOriginal),
          extension: ExportFormat.csv.extension,
          mimeType: 'text/csv',
          format: ExportFormat.csv,
          bytes: Uint8List.fromList(utf8.encode(_toCsv(table))),
        ),
    ];
  }

  String _toCsv(ExportTableData table) {
    final csvRows = <List<dynamic>>[
      table.columns.map((column) => column.originalName).toList(),
      for (final row in table.rows)
        table.columns.map((column) => row[column.dbName]).toList(),
    ];

    return csv.csv.encode(csvRows);
  }

  String _fileBaseName(String datasetName, String sheetName) {
    final dataset = _sanitizeFilePart(datasetName, fallback: 'dataset');
    final sheet = _sanitizeFilePart(sheetName, fallback: 'sheet');
    return '${dataset}_$sheet';
  }

  String _sanitizeFilePart(String value, {required String fallback}) {
    final sanitized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    return sanitized.isEmpty ? fallback : sanitized;
  }
}
