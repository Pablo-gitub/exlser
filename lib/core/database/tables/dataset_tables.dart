import 'package:drift/drift.dart';
import 'datasets.dart';

/// Represents a physical SQL table created from an Excel sheet.
class DatasetTables extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Foreign key to Datasets.id
  IntColumn get datasetId =>
      integer().references(Datasets, #id)();

  /// Original sheet name inside Excel file
  TextColumn get sheetNameOriginal => text()();

  /// Actual SQL table name (e.g. ds_12_sheet_1)
  TextColumn get sqlTableName => text()();

  /// Number of rows inserted into this table
  IntColumn get rowCount => integer()();

  /// Number of columns created (denormalized for quick access)
  IntColumn get colCount => integer()();
}