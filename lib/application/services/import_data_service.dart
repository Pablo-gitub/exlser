import 'package:path/path.dart' as p;

import 'package:exel_category/data/adapters/parsers/parser_factory.dart';
import 'package:exel_category/domain/entities/parsed_sheet.dart';

/// Handles the pre-commit import flow.
///
/// Responsibilities:
/// - detect file type
/// - resolve parser
/// - parse spreadsheet sheets
///
/// This service does NOT persist datasets, tables, columns or rows.
/// Persistence belongs to CreateDatasetService after user confirmation.
class ImportDataService {
  final ParserFactory parserFactory;

  const ImportDataService({
    required this.parserFactory,
  });

  /// Prepares parsed spreadsheet data from a selected file.
  Future<List<ParsedSheet>> prepareImport({
    required String filePath,
  }) async {
    final extension = _getFileExtension(filePath);

    final parser = parserFactory.createParser(extension);

    return parser.parse(filePath);
  }

  /// Extracts normalized file extension without dot.
  String _getFileExtension(String filePath) {
    final extension = p.extension(filePath).replaceFirst('.', '').toLowerCase();

    if (extension.isEmpty) {
      throw Exception('File extension cannot be empty');
    }

    return extension;
  }
}
/// Handles the pre-commit import flow:
/// 1. Save or reference uploaded file
/// 2. Detect file type
/// 3. Resolve parser
/// 4. Parse raw rows / sheets
/// 5. Infer schema for each parsed sheet
///
/// This service must NOT create persistent datasets/tables/rows.
/// That responsibility belongs to CreateDatasetService after user confirmation.
//class ImportDataService {
  //const ImportDataService();

  //Future<void> prepareImport() async {
    // TODO:
    // 1. Save or reference uploaded file
    // 2. Detect file type
    // 3. Get parser from ParserFactory
    // 4. Parse raw rows / sheets
    // 5. Infer schema for each parsed sheet
    //throw UnimplementedError();
  //}
//}