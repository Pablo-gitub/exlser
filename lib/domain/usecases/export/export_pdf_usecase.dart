import 'dart:typed_data';

import 'package:exel_category/core/serializers/dataset_json_serializer.dart';
import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/entities/exported_file.dart';
import 'package:exel_category/domain/usecases/export/export_dataset_data.dart';
import 'package:exel_category/domain/value_objects/export_format.dart';
import 'package:exel_category/domain/value_objects/pdf_export_layout.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ExportPdfUseCase {
  static const int _maxPagesPerSheet = 10000;
  static const int _maxColumnsPerTable = 8;
  static const int _maxPdfCellCharacters = 500;

  const ExportPdfUseCase();

  Future<ExportedFile> call(
    ExportDatasetData data, {
    PdfExportLayout layout = PdfExportLayout.table,
  }) async {
    final pdf = pw.Document();

    for (final table in data.tables) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          maxPages: _maxPagesPerSheet,
          build: (context) => [
            ..._header(
                context, data.dataset.name, table.table.sheetNameOriginal),
            if (layout == PdfExportLayout.table)
              ..._tableViews(context, table)
            else
              ..._cardViews(table),
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

  List<pw.Widget> _header(
    pw.Context context,
    String datasetName,
    String sheetName,
  ) {
    return [
      pw.Text(
        datasetName,
        style: pw.Theme.of(context).header0,
      ),
      pw.SizedBox(height: 8),
      pw.Text(
        sheetName,
        style: pw.Theme.of(context).header1,
      ),
      pw.SizedBox(height: 12),
    ];
  }

  List<pw.Widget> _tableViews(pw.Context context, ExportTableData table) {
    final chunks = _columnChunks(table.columns);

    return [
      for (var i = 0; i < chunks.length; i++) ...[
        if (chunks.length > 1)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Text(
              'Columns ${i + 1} of ${chunks.length}',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        _tableView(context, table, chunks[i]),
        if (i < chunks.length - 1) pw.SizedBox(height: 16),
      ],
    ];
  }

  pw.Widget _tableView(
    pw.Context context,
    ExportTableData table,
    List<DatasetColumn> columns,
  ) {
    return pw.TableHelper.fromTextArray(
      context: context,
      headers: columns
          .map((column) => _formatPdfText(column.originalName))
          .toList(growable: false),
      data: [
        for (final row in table.rows)
          columns
              .map((column) => _formatPdfText(row[column.dbName]))
              .toList(growable: false),
      ],
      cellStyle: const pw.TextStyle(fontSize: 8),
      headerStyle: pw.TextStyle(
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
      ),
      cellPadding: const pw.EdgeInsets.all(4),
    );
  }

  List<pw.Widget> _cardViews(ExportTableData table) {
    return [
      for (final row in table.rows)
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 10),
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    for (final column in table.columns)
                      pw.SizedBox(
                        width: 160,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              column.originalName,
                              style: pw.TextStyle(
                                fontSize: 7,
                                color: PdfColors.grey700,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              _formatPdfText(row[column.dbName]),
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(width: 12),
              _qrCode(
                DatasetJsonSerializer.compactRowJson(
                  columns: table.columns,
                  row: row,
                ),
              ),
            ],
          ),
        ),
    ];
  }

  pw.Widget _qrCode(String data) {
    try {
      return pw.BarcodeWidget(
        barcode: pw.Barcode.qrCode(),
        data: data,
        width: 86,
        height: 86,
        drawText: false,
      );
    } catch (_) {
      return pw.SizedBox(
        width: 86,
        child: pw.Text(
          'QR unavailable',
          style: const pw.TextStyle(fontSize: 7),
        ),
      );
    }
  }

  List<List<T>> _columnChunks<T>(List<T> columns) {
    if (columns.length <= _maxColumnsPerTable) {
      return [columns];
    }

    return [
      for (var start = 0; start < columns.length; start += _maxColumnsPerTable)
        columns.sublist(
          start,
          _chunkEnd(start, columns.length),
        ),
    ];
  }

  int _chunkEnd(int start, int length) {
    final end = start + _maxColumnsPerTable;
    return end > length ? length : end;
  }

  String _formatPdfText(dynamic value) {
    if (value == null) return '';

    final normalized = value
        .toString()
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (normalized.length <= _maxPdfCellCharacters) {
      return normalized;
    }

    return '${normalized.substring(0, _maxPdfCellCharacters)}...';
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
