/// Adapter responsible for parsing Excel files.
///
/// Converts XLSX file structure into raw row data that can be
/// consumed by the schema inference engine.
class ExcelParser {

  /// TODO:
  /// Parse Excel file and return raw rows.
  ///
  /// Expected output structure:
  /// [
  ///   {"column1": value, "column2": value}
  /// ]
  Future<List<Map<String, dynamic>>> parse() async {
    throw UnimplementedError();
  }

}