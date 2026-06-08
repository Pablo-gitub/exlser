/// Represents supported export formats for dataset data.
///
/// This value object centralizes the definition of export formats
/// used by the application, avoiding the use of raw strings
/// across the codebase.
///
/// Supported formats:
/// - Excel
/// - CSV
/// - PDF
/// - SQL
/// - JSON
enum ExportFormat {
  excel,
  csv,
  pdf,
  sql,
  json;

  /// Returns the file extension associated with the export format.
  String get extension {
    switch (this) {
      case ExportFormat.excel:
        return 'xlsx';
      case ExportFormat.csv:
        return 'csv';
      case ExportFormat.pdf:
        return 'pdf';
      case ExportFormat.sql:
        return 'sql';
      case ExportFormat.json:
        return 'json';
    }
  }

  /// Returns a human-readable label for UI usage.
  String get label {
    switch (this) {
      case ExportFormat.excel:
        return 'Excel';
      case ExportFormat.csv:
        return 'CSV';
      case ExportFormat.pdf:
        return 'PDF';
      case ExportFormat.sql:
        return 'SQL';
      case ExportFormat.json:
        return 'JSON';
    }
  }
}
