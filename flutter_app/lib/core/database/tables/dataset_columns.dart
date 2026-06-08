import 'package:drift/drift.dart';
import 'dataset_tables.dart';

/// Represents metadata for a single column inside a dataset table.
class DatasetColumns extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Foreign key to DatasetTables.id
  IntColumn get datasetTableId => integer().references(DatasetTables, #id)();

  /// Column name as found in the Excel header
  TextColumn get originalName => text()();

  /// Sanitized SQL-safe column name
  TextColumn get dbName => text()();

  /// Type selected/confirmed by user (TEXT, INTEGER, REAL, DATE, etc.)
  TextColumn get declaredType => text()();

  /// Type inferred automatically by the system
  TextColumn get inferredType => text()();

  /// Whether column allows null values
  BoolColumn get nullable => boolean()();

  /// JSON containing statistics (min, max, distinctCount, etc.)
  TextColumn get statsJson => text().nullable()();
}
