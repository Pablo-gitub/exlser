import 'dart:typed_data';

import 'package:exel_category/domain/entities/exported_file.dart';
import 'package:exel_category/domain/usecases/export/export_dataset_data.dart';
import 'package:exel_category/domain/value_objects/export_format.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ExportPdfUseCase {
  const ExportPdfUseCase();

  Future<ExportedFile> call(ExportDatasetData data) async {
    final pdf = pw.Document();

    for (final table in data.tables) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (context) => [
            pw.Text(
              data.dataset.name,
              style: pw.Theme.of(context).header0,
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              table.table.sheetNameOriginal,
              style: pw.Theme.of(context).header1,
            ),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: table.columns
                  .map((column) => column.originalName)
                  .toList(growable: false),
              data: [
                for (final row in table.rows)
                  table.columns
                      .map((column) => _formatValue(row[column.dbName]))
                      .toList(growable: false),
              ],
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerStyle: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
              cellPadding: const pw.EdgeInsets.all(4),
            ),
          ],
        ),
      );
    }

    return ExportedFile(
      name: _sanitizeFileName(data.dataset.name, fallback: 'dataset'),
      extension: ExportFormat.pdf.extension,
      mimeType: 'application/pdf',
      format: ExportFormat.pdf,
      bytes: Uint8List.fromList(await pdf.save()),
    );
  }

  String _formatValue(dynamic value) {
    return value == null ? '' : value.toString();
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
