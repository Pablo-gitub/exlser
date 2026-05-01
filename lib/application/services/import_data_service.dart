import 'package:path/path.dart' as p;

import 'package:exel_category/data/adapters/parsers/parser_factory.dart';
import 'package:exel_category/domain/entities/parsed_sheet.dart';
import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/usecases/schema/infer_schema_usecase.dart';

/// Result of the import preparation phase.
///
/// Contains:
/// - parsed raw sheet data
/// - inferred schema (columns)
///
/// This object is used by the UI to:
/// - preview data
/// - allow schema confirmation/editing
class PreparedSheet {
  final ParsedSheet sheet;
  final List<DatasetColumn> columns;

  PreparedSheet({
    required this.sheet,
    required this.columns,
  });
}

/// Handles the pre-commit import flow.
///
/// Responsibilities:
/// - detect file type
/// - resolve parser
/// - parse sheets
/// - infer schema
///
/// IMPORTANT:
/// This service DOES NOT persist anything.
/// It only prepares data for user confirmation.
class ImportDataService {
  final ParserFactory parserFactory;
  final InferSchemaUseCase inferSchemaUseCase;

  const ImportDataService({
    required this.parserFactory,
    required this.inferSchemaUseCase,
  });

  /// Executes the import preparation pipeline.
  ///
  /// Steps:
  /// 1. Detect file extension
  /// 2. Resolve parser
  /// 3. Parse file into sheets
  /// 4. Convert rows into matrix format
  /// 5. Infer schema for each sheet
  ///
  /// Returns:
  /// List of prepared sheets ready for UI preview and confirmation.
  Future<List<PreparedSheet>> prepareImport({
    required String filePath,
  }) async {
    /// ---------------- STEP 1: DETECT EXTENSION ----------------
    final extension = _getFileExtension(filePath);

    /// ---------------- STEP 2: RESOLVE PARSER ----------------
    final parser = parserFactory.createParser(extension);

    /// ---------------- STEP 3: PARSE FILE ----------------
    final parsedSheets = await parser.parse(filePath);

    final result = <PreparedSheet>[];

    /// ---------------- STEP 4–5: PROCESS EACH SHEET ----------------
    for (final sheet in parsedSheets) {
      /// Convert Map rows → matrix for schema inference
      final matrix = _convertToMatrix(sheet.rows);

      /// Infer schema (datasetTableId = 0 → temporary)
      final columns = inferSchemaUseCase.call(
        matrix,
        0,
      );

      result.add(
        PreparedSheet(
          sheet: sheet,
          columns: columns,
        ),
      );
    }

    return result;
  }

  /// Extracts normalized file extension.
  ///
  /// Example:
  /// "file.xlsx" → "xlsx"
  String _getFileExtension(String filePath) {
    final extension = p.extension(filePath)
        .replaceFirst('.', '')
        .toLowerCase();

    if (extension.isEmpty) {
      throw Exception('File extension cannot be empty');
    }

    return extension;
  }

  /// Converts parsed rows into matrix format required
  /// by InferSchemaUseCase.
  ///
  /// Input:
  /// [
  ///   {product: book, price: 10}
  /// ]
  ///
  /// Output:
  /// [
  ///   [product, price],
  ///   [book, 10]
  /// ]
  ///
  /// NOTE:
  /// Assumes all rows share the same keys.
  List<List<String>> _convertToMatrix(
    List<Map<String, dynamic>> rows,
  ) {
    if (rows.isEmpty) return [];

    final headers = rows.first.keys.toList();

    final matrix = <List<String>>[];

    /// Header row
    matrix.add(headers);

    /// Data rows
    for (final row in rows) {
      matrix.add(
        headers.map((h) => row[h]?.toString() ?? '').toList(),
      );
    }

    return matrix;
  }
}