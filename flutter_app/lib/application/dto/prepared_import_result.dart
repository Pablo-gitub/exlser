import 'package:exlser/application/dto/prepared_sheet.dart';

/// Represents the result of the import preparation phase.
///
/// This DTO is used before persistence and contains all data
/// required by the UI to show an import preview.
class PreparedImportResult {
  final String fileName;
  final String fileExtension;
  final List<PreparedSheet> sheets;

  const PreparedImportResult({
    required this.fileName,
    required this.fileExtension,
    required this.sheets,
  });

  /// Returns true when at least one sheet has been prepared.
  bool get hasSheets => sheets.isNotEmpty;

  /// Total number of prepared sheets.
  int get sheetCount => sheets.length;
}
