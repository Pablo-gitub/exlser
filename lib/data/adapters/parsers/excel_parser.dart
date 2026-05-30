import 'dart:io';

import 'package:excel_community/excel_community.dart';
import 'package:exlser/data/adapters/mappers/table_row_mapper.dart';
import 'package:exlser/data/adapters/parsers/spreadsheet_parser.dart';
import 'package:exlser/data/adapters/table_normalizers/header_detector.dart';
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
  Future<List<ParsedSheet>> parsePath(String path) async {
    final file = File(path);

    if (!await file.exists()) {
      throw Exception('Excel file not found');
    }

    final bytes = await file.readAsBytes();

    return parseBytes(bytes);
  }

  @override
  Future<List<ParsedSheet>> parseBytes(List<int> bytes) async {
    final excel = Excel.decodeBytes(bytes);

    final sheets = <ParsedSheet>[];

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

      /// Normalize headers.
      final normalizedRows = HeaderDetector.detect(rawRows);

      if (normalizedRows.isEmpty) {
        continue;
      }

      /// Convert rows into key-value maps.
      final parsedRows = TableRowMapper.map(normalizedRows);

      if (parsedRows.isEmpty) {
        continue;
      }

      sheets.add(
        ParsedSheet(
          name: sheetName,
          rows: parsedRows,
        ),
      );
    }

    if (sheets.isEmpty) {
      throw Exception(
        'Excel file contains no readable sheets',
      );
    }

    return sheets;
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
