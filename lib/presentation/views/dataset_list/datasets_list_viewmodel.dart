import 'package:exel_category/domain/entities/dataset.dart';

/// ViewModel responsible for the saved datasets list.
///
/// Responsibilities:
/// - load all saved datasets
/// - expose them to the UI
/// - handle open dataset action
/// - handle delete dataset action
///
/// This ViewModel should delegate business logic to
/// application services / domain usecases.
class DatasetsListViewModel {
  /// Cached list of saved datasets.
  List<Dataset> datasets = [];

  /// TODO:
  /// Load saved datasets from persistence layer.
  ///
  /// Steps:
  /// 1. Call GetDatasetsUseCase
  /// 2. Store result in local state
  /// 3. Notify UI
  Future<void> loadDatasets() async {
    throw UnimplementedError();
  }

  /// TODO:
  /// Open the selected dataset workspace.
  ///
  /// Steps:
  /// 1. Mark dataset as opened
  /// 2. Navigate to DatasetView
  Future<void> openDataset(int datasetId) async {
    throw UnimplementedError();
  }

  /// TODO:
  /// Delete a saved dataset.
  ///
  /// Steps:
  /// 1. Call DeleteDatasetUseCase
  /// 2. Remove item from local state
  /// 3. Notify UI
  Future<void> deleteDataset(int datasetId) async {
    throw UnimplementedError();
  }
}