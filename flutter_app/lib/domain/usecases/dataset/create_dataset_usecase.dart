import 'package:exlser/domain/entities/dataset.dart';
import 'package:exlser/domain/repositories/datasets_repository.dart';

/// Creates a new dataset entry in the system.
///
/// A dataset represents a single data import session.
/// It stores metadata about the source file and the moment
/// the dataset was created.
///
/// Responsibilities:
/// - validate input parameters (dataset name, file metadata)
/// - generate timestamps if necessary
/// - call DatasetsRepository.createDataset
/// - return the created Dataset entity with its generated id
///
/// Dependencies:
/// - DatasetsRepository
///
/// Expected flow:
/// 1. Receive dataset name and source file information
/// 2. Create Dataset entity instance
/// 3. Call repository to persist dataset
/// 4. Return persisted Dataset
class CreateDatasetUseCase {
  final DatasetsRepository repository;

  CreateDatasetUseCase({
    required this.repository,
  });

  /// Creates and persists a new dataset.
  Future<Dataset> call({
    required String datasetName,
    required String sourceFileName,
    String? sourceFileHash,
  }) async {
    final trimmedName = datasetName.trim();

    if (trimmedName.isEmpty) {
      throw Exception(
        'Dataset name cannot be empty',
      );
    }

    final dataset = Dataset(
      id: 0,
      name: trimmedName,
      sourceFileName: sourceFileName,
      sourceFileHash: sourceFileHash,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      lastOpenedAt: null,
    );

    return repository.createDataset(dataset);
  }
}
