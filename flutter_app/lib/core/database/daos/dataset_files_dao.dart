import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/dataset_files.dart';

part 'dataset_files_dao.g.dart';

@DriftAccessor(tables: [DatasetFiles])
class DatasetFilesDao extends DatabaseAccessor<AppDatabase>
    with _$DatasetFilesDaoMixin {
  DatasetFilesDao(super.db);

  /// Creates file metadata for a dataset
  Future<int> createDatasetFile({
    required int datasetId,
    required String storageMode,
    String? originalPath,
    String? storedPath,
    required DateTime importedAt,
    int? fileSize,
  }) {
    return into(datasetFiles).insert(
      DatasetFilesCompanion.insert(
        datasetId: datasetId,
        storageMode: storageMode,
        importedAt: importedAt,
        originalPath: Value(originalPath),
        storedPath: Value(storedPath),
        fileSize: Value(fileSize),
      ),
    );
  }

  /// Get file metadata by datasetId
  Future<DatasetFile?> getByDatasetId(int datasetId) {
    return (select(datasetFiles)..where((t) => t.datasetId.equals(datasetId)))
        .getSingleOrNull();
  }

  /// Delete file metadata by datasetId
  Future<int> deleteByDatasetId(int datasetId) {
    return (delete(datasetFiles)..where((t) => t.datasetId.equals(datasetId)))
        .go();
  }

  /// Update storage mode (utility method)
  Future<bool> updateStorageMode({
    required int datasetId,
    required String storageMode,
  }) async {
    final entry = await getByDatasetId(datasetId);
    if (entry == null) return false;

    return update(datasetFiles).replace(
      entry.copyWith(storageMode: storageMode),
    );
  }
}
