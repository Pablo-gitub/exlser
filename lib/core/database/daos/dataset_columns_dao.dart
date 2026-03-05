import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/dataset_columns.dart';

part 'dataset_columns_dao.g.dart';

/// DAO responsible for accessing DatasetColumns.
///
/// Each row represents metadata about a column
/// belonging to a dataset table (Excel sheet).
///
/// Responsibilities:
/// - create column metadata
/// - query columns for a table
/// - watch columns for reactive UI
/// - delete columns
///
/// No business logic should exist here.
@DriftAccessor(tables: [DatasetColumns])
class DatasetColumnsDao extends DatabaseAccessor<AppDatabase>
    with _$DatasetColumnsDaoMixin {

  DatasetColumnsDao(super.db);

  /// Inserts metadata for a column.
  ///
  /// Returns the generated column id.
  Future<int> createColumn({
    required int datasetTableId,
    required String originalName,
    required String dbName,
    required String declaredType,
    required String inferredType,
    required bool nullable,
    String? statsJson,
  }) {
    return into(datasetColumns).insert(
      DatasetColumnsCompanion.insert(
        datasetTableId: datasetTableId,
        originalName: originalName,
        dbName: dbName,
        declaredType: declaredType,
        inferredType: inferredType,
        nullable: nullable,
        statsJson: Value(statsJson),
      ),
    );
  }

  /// Returns all columns belonging to a dataset table.
  Future<List<DatasetColumn>> getColumnsForTable(int datasetTableId) {
    return (select(datasetColumns)
          ..where((t) => t.datasetTableId.equals(datasetTableId)))
        .get();
  }

  /// Watches columns belonging to a dataset table.
  Stream<List<DatasetColumn>> watchColumnsForTable(int datasetTableId) {
    return (select(datasetColumns)
          ..where((t) => t.datasetTableId.equals(datasetTableId)))
        .watch();
  }

  /// Deletes all columns belonging to a dataset table.
  Future<int> deleteColumnsForTable(int datasetTableId) {
    return (delete(datasetColumns)
          ..where((t) => t.datasetTableId.equals(datasetTableId)))
        .go();
  }

  /// Deletes a specific column by id.
  Future<int> deleteColumnById(int columnId) {
    return (delete(datasetColumns)
          ..where((t) => t.id.equals(columnId)))
        .go();
  }
}