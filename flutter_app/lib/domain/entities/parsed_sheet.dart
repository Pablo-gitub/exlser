/// Represents a parsed spreadsheet sheet.
///
/// This entity contains raw tabular data extracted
/// from a source file before schema inference.
class ParsedSheet {
  /// Original sheet name.
  final String name;

  /// Raw rows including headers.
  ///
  /// Example:
  /// [
  ///   ["name", "age"],
  ///   ["john", "20"]
  /// ]
  final List<Map<String, dynamic>> rows;

  /// Original source sheet name within the file (if distinguishable).
  final String? sourceSheetName;

  /// Detected cell boundary range (e.g. `A1:D20`).
  final String? cellRange;

  const ParsedSheet({
    required this.name,
    required this.rows,
    this.sourceSheetName,
    this.cellRange,
  });
}
