import 'package:exlser/domain/repositories/datasets_repository.dart';

class UpdateDatasetUiStateUseCase {
  final DatasetsRepository repository;

  const UpdateDatasetUiStateUseCase({
    required this.repository,
  });

  Future<void> call({
    required int datasetId,
    required String uiStateJson,
  }) async {
    if (datasetId <= 0) {
      throw ArgumentError('Dataset id must be greater than 0');
    }

    if (uiStateJson.trim().isEmpty) {
      throw ArgumentError('UI state JSON cannot be empty');
    }

    await repository.updateDatasetUiState(
      datasetId: datasetId,
      uiStateJson: uiStateJson,
    );
  }
}
