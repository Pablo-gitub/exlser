import 'dart:io';

import 'package:excel_community/excel_community.dart';
import 'package:exel_category/data/adapters/mappers/table_row_mapper.dart';
import 'package:exel_category/data/adapters/parsers/spreadsheet_parser.dart';
import 'package:exel_category/data/adapters/table_normalizers/header_detector.dart';
import 'package:exel_category/domain/entities/parsed_sheet.dart';

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
  Future<List<ParsedSheet>> parse(String filePath) async {

    final file = File(filePath);

    if (!await file.exists()) {
      throw Exception('Excel file not found');
    }

    final bytes = await file.readAsBytes();

    final excel = Excel.decodeBytes(bytes);

    final sheets = <ParsedSheet>[];

    for (final sheetName in excel.tables.keys) {

      final table = excel.tables[sheetName];

      if (table == null || table.rows.isEmpty) {
        continue;
      }

      /// Convert Excel cells into raw string rows.
      final rawRows = table.rows.map((row) {

        return row.map((cell) {

          final value = cell?.value;

          return value?.toString() ?? '';

        }).toList();

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
}