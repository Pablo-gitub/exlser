import 'package:exel_category/application/dto/import_file.dart';
import 'package:exel_category/application/dto/prepared_import_result.dart';
import 'package:exel_category/application/dto/prepared_sheet.dart';
import 'package:exel_category/application/exceptions/import_exceptions.dart';
import 'package:path/path.dart' as p;

import 'package:exel_category/data/adapters/parsers/parser_factory.dart';
import 'package:exel_category/domain/entities/parsed_sheet.dart';
import 'package:exel_category/domain/usecases/schema/infer_schema_usecase.dart';

/// Robust import preparation service.
///
/// Handles:
/// - file parsing
/// - schema inference
/// - structured error propagation
class ImportDataService {
  final ParserFactory parserFactory;
  final InferSchemaUseCase inferSchemaUseCase;

  const ImportDataService({
    required this.parserFactory,
    required this.inferSchemaUseCase,
  });

  Future<PreparedImportResult> prepareImport({
    required ImportFile file,
  }) async {
    try {
      final extension = _getFileExtension(file.fileName);

      final parser = _resolveParser(extension);

      final parsedSheets = await _parseFile(parser, file.fileName);

      final prepared = _processSheets(parsedSheets);

      if (prepared.isEmpty) {
        throw const ParsingException(
          code: 'no_valid_sheets',
          message: 'All sheets were empty or invalid',
        );
      }

      return PreparedImportResult(
        fileName: p.basename(file.fileName),
        fileExtension: extension,
        sheets: prepared,
      );
    } on ImportException {
      rethrow;
    } catch (e) {
      throw ParsingException(
        code: 'unexpected_error',
        message: 'Unexpected import error: $e',
      );
    }
  }

  /// ---------------- INTERNAL STEPS ----------------

  String _getFileExtension(String filePath) {
    final extension = p.extension(filePath).replaceFirst('.', '').toLowerCase();

    if (extension.isEmpty) {
      throw const InvalidFileExtensionException();
    }

    return extension;
  }

  dynamic _resolveParser(String extension) {
    try {
      return parserFactory.createParser(extension);
    } catch (_) {
      throw UnsupportedFormatException(
        extension: extension,
      );
    }
  }

  Future<List<ParsedSheet>> _parseFile(
    dynamic parser,
    String filePath,
  ) async {
    try {
      final sheets = await parser.parse(filePath);

      if (sheets.isEmpty) {
        throw const ParsingException(
          code: 'no_sheets',
          message: 'File contains no readable sheets',
        );
      }

      return sheets;
    } on ImportException {
      rethrow;
    } catch (e) {
      throw ParsingException(
        code: 'parsing_failed',
        message: 'Failed to parse file: $e',
      );
    }
  }

  List<PreparedSheet> _processSheets(
    List<ParsedSheet> parsedSheets,
  ) {
    final result = <PreparedSheet>[];

    for (final sheet in parsedSheets) {
      try {
        if (sheet.rows.isEmpty) {
          /// Skip empty sheets silently OR throw (design choice)
          continue;
        }

        final matrix = _convertToMatrix(sheet.rows);

        final columns = inferSchemaUseCase.call(
          matrix,
          0,
        );

        result.add(
          PreparedSheet(
            sheet: sheet,
            inferredColumns: columns,
          ),
        );
      } catch (e) {
        throw SchemaInferenceException(
          sheetName: sheet.name,
          details: e.toString(),
        );
      }
    }

    return result;
  }

  List<List<String>> _convertToMatrix(
    List<Map<String, dynamic>> rows,
  ) {
    if (rows.isEmpty) return [];

    final headers = rows.first.keys.toList();

    final matrix = <List<String>>[];

    matrix.add(headers);

    for (final row in rows) {
      matrix.add(
        headers.map((h) => row[h]?.toString() ?? '').toList(),
      );
    }

    return matrix;
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