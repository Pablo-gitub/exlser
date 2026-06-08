import 'package:exlser/application/dto/import_file.dart';
import 'package:exlser/application/dto/prepared_import_result.dart';
import 'package:exlser/application/dto/prepared_sheet.dart';
import 'package:exlser/application/exceptions/import_exceptions.dart';
import 'package:exlser/data/adapters/normalizers/number_normalizer.dart';
import 'package:exlser/data/adapters/parsers/spreadsheet_parser.dart';
import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/value_objects/column_type.dart';
import 'package:path/path.dart' as p;

import 'package:exlser/data/adapters/parsers/parser_factory.dart';
import 'package:exlser/domain/entities/parsed_sheet.dart';
import 'package:exlser/domain/usecases/schema/infer_schema_usecase.dart';

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

      final parsedSheets = await _parseFile(parser, file);

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

  SpreadsheetParser _resolveParser(String extension) {
    try {
      return parserFactory.createParser(extension);
    } catch (_) {
      throw UnsupportedFormatException(
        extension: extension,
      );
    }
  }

  Future<List<ParsedSheet>> _parseFile(
    SpreadsheetParser parser,
    ImportFile file,
  ) async {
    try {
      final sheets = file.hasPath
          ? await parser.parsePath(file.path!)
          : await parser.parseBytes(file.bytes!);

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

        final currencySymbols = _detectColumnCurrencies(matrix, columns);

        result.add(
          PreparedSheet(
            sheet: sheet,
            inferredColumns: columns,
            columnCurrencySymbols: currencySymbols,
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

  /// Scans raw column values and returns the dominant currency symbol for each
  /// numeric column, if one appears in the majority of non-empty cells.
  Map<String, String> _detectColumnCurrencies(
    List<List<String>> matrix,
    List<DatasetColumn> columns,
  ) {
    final result = <String, String>{};
    final dataRows = matrix.skip(1).toList();
    if (dataRows.isEmpty) return result;

    for (int i = 0; i < columns.length; i++) {
      final col = columns[i];
      if (col.declaredType != ColumnType.integer &&
          col.declaredType != ColumnType.real) {
        continue;
      }

      final symbolCounts = <String, int>{};
      int nonEmptyCount = 0;

      for (final row in dataRows) {
        if (i >= row.length) continue;
        final raw = row[i].trim();
        if (raw.isEmpty) continue;
        nonEmptyCount++;
        final symbol = NumberNormalizer.detectCurrencySymbol(raw);
        if (symbol != null) {
          symbolCounts[symbol] = (symbolCounts[symbol] ?? 0) + 1;
        }
      }

      if (symbolCounts.isEmpty || nonEmptyCount == 0) continue;

      // Accept the symbol only if it appears in over half the non-empty cells.
      final dominant = symbolCounts.entries
          .reduce((a, b) => a.value >= b.value ? a : b);
      if (dominant.value > nonEmptyCount * 0.5) {
        result[col.dbName] = dominant.key;
      }
    }

    return result;
  }
}
