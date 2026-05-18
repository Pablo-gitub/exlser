import 'dart:io';
import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:exel_category/data/adapters/mappers/table_row_mapper.dart';
import 'package:exel_category/data/adapters/parsers/spreadsheet_parser.dart';
import 'package:exel_category/data/adapters/table_normalizers/header_detector.dart';
import 'package:exel_category/domain/entities/parsed_sheet.dart';

/// Parser responsible for reading CSV files.
///
/// Responsibilities:
/// - read CSV file contents
/// - normalize headers
/// - convert tabular rows into ParsedSheet structures
///
/// This parser does NOT:
/// - infer schema
/// - normalize data types
/// - persist datasets
///
/// Output:
/// List of ParsedSheet values.
///
/// Each ParsedSheet contains:
/// - sheet name
/// - parsed rows as key-value maps
///
/// Values remain raw strings and will be normalized later
/// by the schema inference pipeline.
class CsvParser implements SpreadsheetParser {
  @override
  Future<List<ParsedSheet>> parsePath(String path) async {
    final file = File(path);

    final content = await file.readAsString();

    return _parseContent(content);
  }

  @override
  Future<List<ParsedSheet>> parseBytes(List<int> bytes) async {
    final content = utf8.decode(bytes);

    return _parseContent(content);
  }

  List<ParsedSheet> _parseContent(String content) {
    if (content.trim().isEmpty) {
      throw Exception('CSV file is empty');
    }

    /// Decode CSV content.
    final rows = csv.decode(content);

    if (rows.isEmpty) {
      throw Exception('CSV file contains no data');
    }

    /// Normalize headers.
    final normalizedRows = HeaderDetector.detect(rows);

    /// Convert rows into key-value maps.
    final parsedRows = TableRowMapper.map(normalizedRows);

    if (parsedRows.isEmpty) {
      throw Exception('CSV file contains no valid rows');
    }

    return [
      ParsedSheet(
        name: 'Sheet1',
        rows: parsedRows,
      ),
    ];
  }
}
