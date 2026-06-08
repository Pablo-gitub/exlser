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

    // Extract header row and ignore columns without a header.
    final headers = <({int index, String name})>[];
    for (int i = 0; i < rows.first.length; i++) {
      final header = rows.first[i]?.toString().trim() ?? '';
      if (header.isNotEmpty) {
        headers.add((index: i, name: header));
      }
    }

    if (headers.isEmpty) {
      return [];
    }

    // Extract data rows.
    final dataRows = rows.skip(1);

    return dataRows.map((row) {
      final Map<String, dynamic> rowMap = {};

      for (final header in headers) {
        final key = header.name;

        final value =
            header.index < row.length ? row[header.index]?.toString() : null;

        rowMap[key] = value;
      }

      return rowMap;
    }).toList();
  }
}
