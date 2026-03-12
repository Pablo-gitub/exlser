import 'dart:io';

import 'package:csv/csv.dart';
import 'package:exel_category/data/adapters/table_normalizers/header_detector.dart';

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
class CsvParser {

  Future<List<Map<String, dynamic>>> parse(String filePath) async {

    final file = File(filePath);

    final content = await file.readAsString();

    if (content.trim().isEmpty) {
      throw Exception('CSV file is empty');
    }

    /// Decode CSV using the csv package
    final rows = csv.decode(content);

    if (rows.isEmpty) {
      throw Exception('CSV file contains no data');
    }

    final normalizedRows = HeaderDetector.detect(rows);
    /// Extract header row
    final headers = normalizedRows.first.map((e) => e.toString()).toList();

    /// Extract data rows
    final dataRows = normalizedRows.skip(1);

    final result = dataRows.map((row) {

      final Map<String, dynamic> rowMap = {};

      for (int i = 0; i < headers.length; i++) {

        final key = headers[i];

        final value = i < row.length
            ? row[i]?.toString()
            : null;

        rowMap[key] = value;
      }

      return rowMap;

    }).toList();

    return result;
  }
}