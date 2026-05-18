/// Detects the header row inside parsed tabular data.
///
/// Some CSV or Excel files may contain empty rows
/// before the actual header row.
///
/// Example input:
///
/// [
///   ["",""],
///   ["",""],
///   ["name","price"],
///   ["book","10"]
/// ]
///
/// Output:
///
/// [
///   ["name","price"],
///   ["book","10"]
/// ]
///
/// This prevents schema inference from incorrectly
/// interpreting empty rows as headers.
class HeaderDetector {
  /// Detects and returns the table starting from the first
  /// non-empty row (considered the header).
  static List<List<dynamic>> detect(List<List<dynamic>> rows) {
    if (rows.isEmpty) {
      throw Exception("Dataset is empty");
    }

    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];

      final hasValue = row.any((cell) => cell.trim().isNotEmpty);

      if (hasValue) {
        return rows.sublist(i);
      }
    }

    throw Exception("No header row found in dataset");
  }
}
