//lib/domain/repositories/datasets_repository.dart
import 'package:exel_category/domain/entities/dataset.dart';

/// Repository contract for managing datasets.
///
/// A dataset represents a single Excel import session.
/// This repository handles creation, retrieval and updates
/// of dataset metadata.
abstract class DatasetsRepository {
  /// Returns all datasets stored in the system.
  Future<List<Dataset>> getAllDatasets();

  /// Returns a dataset by its id.
  Future<Dataset?> getDatasetById(int id);

  /// Creates a new dataset.
  ///
  /// Returns the created dataset with its generated id.
  Future<Dataset> createDataset(Dataset dataset);

  /// Updates dataset metadata (name, lastOpenedAt, etc.).
  Future<void> updateDataset(Dataset dataset);

  /// Deletes a dataset and its associated metadata.
  Future<void> deleteDataset(int id);

  /// Updates the last opened timestamp of a dataset.
  Future<void> markDatasetOpened(int datasetId);

  /// Updates the serialized UI state for a dataset workspace.
  Future<void> updateDatasetUiState({
    required int datasetId,
    required String uiStateJson,
  });
}
