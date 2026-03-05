import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/datasets.dart';

part 'datasets_dao.g.dart';

/// Data Access Object for the [Datasets] table.
///
/// This class is responsible only for database access:
/// - insert
/// - read
/// - update
/// - delete
/// - watch
///
/// It must not contain business logic.
@DriftAccessor(tables: [Datasets])
class DatasetsDao extends DatabaseAccessor<AppDatabase>
    with _$DatasetsDaoMixin {
  DatasetsDao(super.db);

  /// Inserts a new dataset and returns the generated id.
  Future<int> createDataset({
    required String name,
    required String sourceFileName,
    String? sourceFileHash,
    required int createdAt,
    int? lastOpenedAt,
    String? uiStateJson,
  }) {
    return into(datasets).insert(
      DatasetsCompanion.insert(
        name: name,
        sourceFileName: sourceFileName,
        sourceFileHash: Value(sourceFileHash),
        createdAt: createdAt,
        lastOpenedAt: Value(lastOpenedAt),
        uiStateJson: Value(uiStateJson),
      ),
    );
  }

  /// Returns all datasets ordered by creation date descending.
  Future<List<Dataset>> getAllDatasets() {
    return (select(datasets)
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.createdAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
  }

  /// Watches all datasets ordered by creation date descending.
  Stream<List<Dataset>> watchAllDatasets() {
    return (select(datasets)
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.createdAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .watch();
  }

  /// Returns a single dataset by id, or null if it does not exist.
  Future<Dataset?> getDatasetById(int id) {
    return (select(datasets)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Updates the "last opened" timestamp.
  ///
  /// Returns true when at least one row has been updated.
  Future<bool> updateLastOpenedAt({
    required int datasetId,
    required int lastOpenedAt,
  }) async {
    final affectedRows =
        await (update(datasets)..where((t) => t.id.equals(datasetId))).write(
      DatasetsCompanion(
        lastOpenedAt: Value(lastOpenedAt),
      ),
    );

    return affectedRows > 0;
  }

  /// Updates the serialized UI state.
  ///
  /// Returns true when at least one row has been updated.
  Future<bool> updateUiState({
    required int datasetId,
    required String uiStateJson,
  }) async {
    final affectedRows =
        await (update(datasets)..where((t) => t.id.equals(datasetId))).write(
      DatasetsCompanion(
        uiStateJson: Value(uiStateJson),
      ),
    );

    return affectedRows > 0;
  }

  /// Deletes a dataset by id.
  ///
  /// Returns the number of deleted rows.
  Future<int> deleteDatasetById(int id) {
    return (delete(datasets)..where((t) => t.id.equals(id))).go();
  }
}