import 'dart:io';

import 'package:csv/csv.dart';
import 'package:exel_category/data/adapters/mappers/table_row_mapper.dart';
import 'package:exel_category/data/adapters/parsers/spreadsheet_parser.dart';
import 'package:exel_category/data/adapters/table_normalizers/header_detector.dart';
import 'package:exel_category/domain/entities/parsed_sheet.dart';

/// Parser responsible for reading CSV files and converting them
/// into a normalized row structure.
///
/// Output format:
///
/// List<Map<String, dynamic>>
///
/// Example:
///
/// product,price,quantity
/// book,10,20
///
/// Result:
///
/// [
///   {
///     "product": "book",
///     "price": "10",
///     "quantity": "20"
///   }
/// ]
///
/// This parser does not interpret data types.
/// Values remain raw strings and will be normalized later.
/// 
/// Parser responsible for reading CSV files and converting them
/// into normalized sheet structures.
class CsvParser implements SpreadsheetParser {

  @override
  Future<List<ParsedSheet>> parse(String filePath) async {

    final file = File(filePath);

    final content = await file.readAsString();

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