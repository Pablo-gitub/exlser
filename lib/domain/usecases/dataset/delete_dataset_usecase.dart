import 'package:exel_category/domain/repositories/dataset_file_repository.dart';
import 'package:exel_category/domain/repositories/datasets_repository.dart';
import 'package:exel_category/domain/repositories/schema_repository.dart';

/// Deletes a dataset and its associated metadata.
///
/// This operation removes:
/// - dataset metadata
/// - associated schema metadata
/// - dynamic SQL tables (if they exist)
///
/// Responsibilities:
/// - call repository delete method
/// - ensure cleanup of related schema and tables
///
/// Dependencies:
/// - DatasetsRepository
/// - SchemaRepository
///
/// Expected flow:
/// 1. Receive datasetId
/// 2. Remove schema metadata via SchemaRepository
/// 3. Delete dataset via DatasetsRepository
class DeleteDatasetUseCase {
  final DatasetsRepository datasetsRepository;
  final SchemaRepository schemaRepository;
  final DatasetFileRepository datasetFileRepository;

  const DeleteDatasetUseCase({
    required this.datasetsRepository,
    required this.schemaRepository,
    required this.datasetFileRepository,
  });

  Future<void> call(int datasetId) async {
    if (datasetId <= 0) {
      throw Exception('Dataset id must be greater than 0');
    }

    await datasetFileRepository.deleteByDatasetId(datasetId);
    await schemaRepository.deleteSchemaForDataset(datasetId);
    await datasetsRepository.deleteDataset(datasetId);
  }
}
