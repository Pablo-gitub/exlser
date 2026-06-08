import 'package:exlser/domain/entities/dataset.dart';
import 'package:exlser/domain/repositories/datasets_repository.dart';

/// Marks a dataset as opened and retrieves its metadata.
///
/// Used when a user selects an existing dataset from the UI.
///
/// Responsibilities:
/// - update lastOpenedAt timestamp
/// - retrieve dataset metadata
///
/// Dependencies:
/// - DatasetsRepository
///
/// Expected flow:
/// 1. Receive datasetId
/// 2. Call repository.markDatasetOpened(datasetId)
/// 3. Retrieve dataset metadata
/// 4. Return Dataset entity
class OpenDatasetUseCase {
  final DatasetsRepository repository;

  const OpenDatasetUseCase({
    required this.repository,
  });

  Future<Dataset> call(int datasetId) async {
    if (datasetId <= 0) {
      throw ArgumentError('Dataset id must be greater than 0');
    }

    await repository.markDatasetOpened(datasetId);

    final dataset = await repository.getDatasetById(datasetId);
    if (dataset == null) {
      throw StateError('Dataset not found: $datasetId');
    }

    return dataset;
  }
}
