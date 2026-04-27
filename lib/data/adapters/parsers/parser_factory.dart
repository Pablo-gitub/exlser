import 'package:exel_category/data/adapters/parsers/csv_parser.dart';
import 'package:exel_category/data/adapters/parsers/excel_parser.dart';
import 'package:exel_category/data/adapters/parsers/spreadsheet_parser.dart';

/// Factory responsible for selecting the correct parser
/// based on file extension.
///
/// Supported formats:
/// - Excel (.xlsx)
/// - CSV (.csv)
class ParserFactory {

  /// Returns the correct parser instance
  /// based on file extension.
  ///
  /// Throws:
  /// - Exception if file type is unsupported.
  SpreadsheetParser createParser(
    String fileExtension,
  ) {

    switch (fileExtension.toLowerCase()) {

      case 'csv':
        return CsvParser();

      case 'xlsx':
        return ExcelParser();

      default:
        throw Exception(
          'Unsupported file format: $fileExtension',
        );
    }
  }
}