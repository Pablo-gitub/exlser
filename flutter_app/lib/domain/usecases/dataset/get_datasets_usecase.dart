import 'package:exlser/domain/entities/dataset.dart';
import 'package:exlser/domain/repositories/datasets_repository.dart';

/// Retrieves all datasets stored in the system.
///
/// Used to populate the UI with previously imported datasets.
///
/// Responsibilities:
/// - retrieve dataset metadata from persistence layer
/// - return a list of Dataset entities
///
/// Dependencies:
/// - DatasetsRepository
///
/// Expected flow:
/// 1. Call repository.getAllDatasets()
/// 2. Return list of Dataset entities
class GetDatasetsUseCase {
  final DatasetsRepository repository;

  const GetDatasetsUseCase({
    required this.repository,
  });

  Future<List<Dataset>> call() async {
    return await repository.getAllDatasets();
  }
}
