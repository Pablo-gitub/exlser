import 'dart:io';
import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:exlser/data/adapters/mappers/table_row_mapper.dart';
import 'package:exlser/data/adapters/parsers/spreadsheet_parser.dart';
import 'package:exlser/data/adapters/table_normalizers/header_detector.dart';
import 'package:exlser/data/adapters/table_normalizers/table_boundary_detector.dart';
import 'package:exlser/domain/entities/parsed_sheet.dart';

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
  Future<List<ParsedSheet>> parsePath(
    String path, {
    bool detectMultipleTables = true,
  }) async {
    final file = File(path);

    final content = await file.readAsString();

    return _parseContent(content, detectMultipleTables: detectMultipleTables);
  }

  @override
  Future<List<ParsedSheet>> parseBytes(
    List<int> bytes, {
    bool detectMultipleTables = true,
  }) async {
    final content = utf8.decode(bytes);

    return _parseContent(content, detectMultipleTables: detectMultipleTables);
  }

  List<ParsedSheet> _parseContent(
    String content, {
    bool detectMultipleTables = true,
  }) {
    if (content.trim().isEmpty) {
      throw Exception('CSV file is empty');
    }

    /// Preserve empty rows outside quotes so boundary detector can detect table separators.
    final preservedContent = _preserveEmptyLines(content);

    /// Decode CSV content and restore empty row markers.
    final rawDecoded = csv.decode(preservedContent);
    final rows = rawDecoded.map((r) {
      if (r.length == 1 && r[0] == _blankRowMarker) {
        return const <dynamic>[];
      }
      return r;
    }).toList();

    if (rows.isEmpty) {
      throw Exception('CSV file contains no data');
    }

    if (detectMultipleTables) {
      /// Detect table boundaries within the CSV.
      final detectedBlocks = TableBoundaryDetector.detect(
        rows,
        defaultSheetName: 'Sheet1',
      );

      if (detectedBlocks.isNotEmpty) {
        final sheets = <ParsedSheet>[];
        final usedTableNames = <String>{};

        for (var i = 0; i < detectedBlocks.length; i++) {
          final block = detectedBlocks[i];
          final parsedRows = TableRowMapper.map(block.rows);
          if (parsedRows.isEmpty) continue;

          final baseName =
              (detectedBlocks.length == 1 && block.detectedTitle == null)
                  ? 'Sheet1'
                  : block.suggestedTableName(
                      fallbackBaseName: 'Sheet1',
                      tableIndex: i + 1,
                    );
          final tableName = _deduplicateTableName(baseName, usedTableNames);
          usedTableNames.add(tableName.toLowerCase());

          sheets.add(
            ParsedSheet(
              name: tableName,
              rows: parsedRows,
              sourceSheetName: 'Sheet1',
              cellRange: block.cellRange,
            ),
          );
        }

        if (sheets.isNotEmpty) {
          return sheets;
        }
      }
    }

    /// Fallback to legacy single header detection.
    final normalizedRows = HeaderDetector.detect(rows);
    final parsedRows = TableRowMapper.map(normalizedRows);

    if (parsedRows.isEmpty) {
      throw Exception('CSV file contains no valid rows');
    }

    return [
      ParsedSheet(
        name: 'Sheet1',
        rows: parsedRows,
        sourceSheetName: 'Sheet1',
      ),
    ];
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

  static const String _blankRowMarker = '__EXLSER_BLANK_ROW__';

  /// Preserves empty lines outside quotes so the boundary detector can see table separators.
  static String _preserveEmptyLines(String content) {
    final buffer = StringBuffer();
    var inQuotes = false;
    final length = content.length;

    for (var i = 0; i < length; i++) {
      final char = content[i];

      if (char == '"') {
        if (inQuotes && i + 1 < length && content[i + 1] == '"') {
          buffer.write('""');
          i++;
          continue;
        }
        inQuotes = !inQuotes;
        buffer.write(char);
      } else if (!inQuotes && char == '\n') {
        buffer.write('\n');
        var j = i + 1;
        while (j < length &&
            (content[j] == ' ' || content[j] == '\t' || content[j] == '\r')) {
          j++;
        }
        if (j < length && content[j] == '\n') {
          buffer.write('$_blankRowMarker\n');
          i = j;
        }
      } else {
        buffer.write(char);
      }
    }

    return buffer.toString();
  }
}
