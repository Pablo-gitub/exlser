/// Utility responsible for converting tabular rows
/// into key-value row maps.
///
/// Expected input:
/// [
///   ["name", "age"],
///   ["john", "20"]
/// ]
///
/// Output:
/// [
///   {
///     "name": "john",
///     "age": "20",
///   }
/// ]
class TableRowMapper {
  /// Converts normalized rows into mapped rows.
  ///
  /// Assumes:
  /// - first row contains headers
  /// - remaining rows contain data
  static List<Map<String, dynamic>> map(
    List<List<dynamic>> rows,
  ) {
    if (rows.isEmpty) {
      return [];
    }

    /// Extract header row.
    final headers = rows.first.map((e) => e.toString()).toList();

    /// Extract data rows.
    final dataRows = rows.skip(1);

    return dataRows.map((row) {
      final Map<String, dynamic> rowMap = {};

      for (int i = 0; i < headers.length; i++) {
        final key = headers[i];

        final value = i < row.length ? row[i]?.toString() : null;

        rowMap[key] = value;
      }

      return rowMap;
    }).toList();
  }
}
