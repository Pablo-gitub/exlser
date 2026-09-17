import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:excel_community/excel_community.dart';
import 'package:exlser/data/adapters/mappers/table_row_mapper.dart';
import 'package:exlser/data/adapters/parsers/spreadsheet_parser.dart';
import 'package:exlser/data/adapters/table_normalizers/header_detector.dart';
import 'package:exlser/data/adapters/table_normalizers/table_boundary_detector.dart';
import 'package:exlser/domain/entities/parsed_sheet.dart';

/// Parser responsible for reading Excel files.
///
/// Supports:
/// - multiple sheets
/// - raw row extraction
/// - header normalization
///
/// This parser does NOT infer data types.
/// Values remain raw strings.
class ExcelParser implements SpreadsheetParser {
  @override
  Future<List<ParsedSheet>> parsePath(
    String path, {
    bool detectMultipleTables = true,
  }) async {
    final file = File(path);

    if (!await file.exists()) {
      throw Exception('Excel file not found');
    }

    final bytes = await file.readAsBytes();

    return parseBytes(bytes, detectMultipleTables: detectMultipleTables);
  }

  @override
  Future<List<ParsedSheet>> parseBytes(
    List<int> bytes, {
    bool detectMultipleTables = true,
  }) {
    // Unzipping the workbook, parsing its XML and segmenting every sheet is
    // CPU-bound and used to run on the UI isolate, freezing the app on a large
    // file. `compute` moves it to a worker isolate (inline on the web).
    return compute(
      _parseExcelBytes,
      ExcelParseRequest(
        bytes: Uint8List.fromList(bytes),
        detectMultipleTables: detectMultipleTables,
      ),
    );
  }

  /// Synchronous core, reachable from the isolate entry point below.
  @visibleForTesting
  List<ParsedSheet> parseBytesForIsolate(
    List<int> bytes, {
    bool detectMultipleTables = true,
  }) {
    final excel = Excel.decodeBytes(_normalizePackageForDecoder(bytes));

    final sheets = <ParsedSheet>[];
    final usedTableNames = <String>{};

    for (final sheetName in excel.tables.keys) {
      final table = excel.tables[sheetName];

      if (table == null || table.rows.isEmpty) {
        continue;
      }

      /// Convert Excel cells into raw string rows.
      /// For numeric cells with a currency number format, the currency symbol
      /// is appended to the value string so that downstream schema inference
      /// and currency detection can pick it up (e.g. "12.5€").
      final rawRows = table.rows.map((row) {
        return row.map(_cellString).toList();
      }).toList();

      if (detectMultipleTables) {
        /// Detect table boundaries within the sheet.
        final detectedBlocks = TableBoundaryDetector.detect(
          rawRows,
          defaultSheetName: sheetName,
        );

        if (detectedBlocks.isNotEmpty) {
          for (var i = 0; i < detectedBlocks.length; i++) {
            final block = detectedBlocks[i];
            final parsedRows = TableRowMapper.map(block.rows);
            if (parsedRows.isEmpty) continue;

            final baseName =
                (detectedBlocks.length == 1 && block.detectedTitle == null)
                    ? sheetName
                    : block.suggestedTableName(
                        fallbackBaseName: sheetName,
                        tableIndex: i + 1,
                      );
            final tableName = _deduplicateTableName(baseName, usedTableNames);
            usedTableNames.add(tableName.toLowerCase());

            sheets.add(
              ParsedSheet(
                name: tableName,
                rows: parsedRows,
                sourceSheetName: sheetName,
                cellRange: block.cellRange,
              ),
            );
          }
          continue;
        }
      }

      /// Fallback to single header detection if spatial detection was inconclusive
      /// or detectMultipleTables is false.
      final normalizedRows = HeaderDetector.detect(rawRows);
      if (normalizedRows.isNotEmpty) {
        final parsedRows = TableRowMapper.map(normalizedRows);
        if (parsedRows.isNotEmpty) {
          final tableName = _deduplicateTableName(sheetName, usedTableNames);
          usedTableNames.add(tableName.toLowerCase());

          sheets.add(
            ParsedSheet(
              name: tableName,
              rows: parsedRows,
              sourceSheetName: sheetName,
            ),
          );
        }
      }
    }

    if (sheets.isEmpty) {
      throw Exception(
        'Excel file contains no readable sheets',
      );
    }

    return sheets;
  }

  static String _deduplicateTableName(String name, Set<String> existingNames) {
    var candidate = name;
    var counter = 2;
    while (existingNames.contains(candidate.toLowerCase())) {
      candidate = '$name ($counter)';
      counter++;
    }
    return candidate;
  }

  /// Normalizes valid OOXML variants that `excel_community` 1.x does not read:
  /// absolute workbook targets and the optional `x:` SpreadsheetML prefix.
  static List<int> _normalizePackageForDecoder(List<int> bytes) {
    const relationshipsPath = 'xl/_rels/workbook.xml.rels';
    final source = ZipDecoder().decodeBytes(bytes);
    final relationships = source.findFile(relationshipsPath);
    final workbook = source.findFile('xl/workbook.xml');
    if (relationships == null || workbook == null) return bytes;

    final relationshipsXml = utf8.decode(relationships.content);
    final hasAbsoluteTargets =
        RegExp(r'''Target=(["'])/xl/''').hasMatch(relationshipsXml);
    final hasSpreadsheetPrefix = utf8.decode(workbook.content).contains('<x:');
    if (!hasAbsoluteTargets && !hasSpreadsheetPrefix) return bytes;

    final normalizedArchive = Archive();

    for (final file in source.files) {
      if (file.isDirectory) {
        normalizedArchive.addFile(ArchiveFile.directory(file.name));
        continue;
      }

      var content = file.content;
      if (file.name == relationshipsPath || file.name.endsWith('.xml')) {
        final xml = utf8.decode(content);
        var normalized = xml;
        if (file.name == relationshipsPath) {
          normalized = normalized.replaceAllMapped(
            RegExp(r'''Target=(["'])/xl/'''),
            (match) => 'Target=${match[1]}',
          );
        }
        if (file.name.endsWith('.xml')) {
          normalized =
              normalized.replaceAll('<x:', '<').replaceAll('</x:', '</');
        }
        if (normalized != xml) {
          content = Uint8List.fromList(utf8.encode(normalized));
        }
      }

      normalizedArchive.addFile(ArchiveFile.bytes(file.name, content));
    }

    return ZipEncoder().encode(normalizedArchive);
  }

  static final _currencyInFormat = RegExp(r'[$€£¥₹₽¢₩₪₫]');

  /// Converts a single Excel cell to its string representation.
  ///
  /// For numeric cells (DoubleCellValue / IntCellValue) whose number format
  /// contains a currency symbol, the symbol is appended to the raw numeric
  /// string (e.g. "12.5€"). This lets the downstream currency-detection and
  /// NumberNormalizer treat the value correctly without affecting non-currency
  /// numeric cells.
  static String _cellString(Data? cell) {
    final value = cell?.value;
    if (value == null) return '';

    if (value is DoubleCellValue || value is IntCellValue) {
      final formatCode = cell!.cellStyle?.numberFormat.formatCode ?? '';
      final match = _currencyInFormat.firstMatch(formatCode);
      if (match != null) {
        return '$value${match[0]}';
      }
    }

    return value.toString();
  }
}

/// Isolate payload for [ExcelParser].
@immutable
class ExcelParseRequest {
  final Uint8List bytes;
  final bool detectMultipleTables;

  const ExcelParseRequest({
    required this.bytes,
    required this.detectMultipleTables,
  });
}

/// Top-level entry point required by `compute`.
List<ParsedSheet> _parseExcelBytes(ExcelParseRequest request) {
  return ExcelParser().parseBytesForIsolate(
    request.bytes,
    detectMultipleTables: request.detectMultipleTables,
  );
}
