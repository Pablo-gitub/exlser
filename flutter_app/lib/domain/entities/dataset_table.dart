//lib/domain/entities/dataset_table.dart

/// Domain entity representing a table generated from an Excel sheet.
class DatasetTable {
  final int id;
  final int datasetId;

  final String sheetNameOriginal;
  final String sqlTableName;

  final int rowCount;
  final int colCount;
  final String? sourceSheetName;

  const DatasetTable({
    required this.id,
    required this.datasetId,
    required this.sheetNameOriginal,
    required this.sqlTableName,
    required this.rowCount,
    required this.colCount,
    this.sourceSheetName,
  });

  DatasetTable copyWith({
    int? id,
    int? datasetId,
    String? sheetNameOriginal,
    String? sqlTableName,
    int? rowCount,
    int? colCount,
    String? sourceSheetName,
  }) {
    return DatasetTable(
      id: id ?? this.id,
      datasetId: datasetId ?? this.datasetId,
      sheetNameOriginal: sheetNameOriginal ?? this.sheetNameOriginal,
      sqlTableName: sqlTableName ?? this.sqlTableName,
      rowCount: rowCount ?? this.rowCount,
      colCount: colCount ?? this.colCount,
      sourceSheetName: sourceSheetName ?? this.sourceSheetName,
    );
  }

  String get displayName => sheetNameOriginal;

  String get effectiveSourceSheetName => sourceSheetName ?? sheetNameOriginal;
}
