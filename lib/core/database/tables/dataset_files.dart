import 'package:drift/drift.dart';
import 'datasets.dart';

class DatasetFiles extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();

  /// Foreign key to datasets
  IntColumn get datasetId =>
      integer().references(Datasets, #id).unique()();

  /// Storage mode:
  /// path, pathAndCopy, webTemporary, webPersisted
  TextColumn get storageMode => text()();

  /// Original file path (nullable if not available, e.g. web)
  TextColumn get originalPath => text().nullable()();

  /// Stored file path inside app storage (nullable if not copied)
  TextColumn get storedPath => text().nullable()();

  /// Timestamp of last import
  DateTimeColumn get importedAt => dateTime()();

  /// File size in bytes (optional)
  IntColumn get fileSize => integer().nullable()();
}