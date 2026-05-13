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

  const DeleteDatasetUseCase({
    required this.datasetsRepository,
    required this.schemaRepository,
  });

  Future<void> call(int datasetId) async {
    // Si delega allo SchemaRepository la cancellazione delle tabelle dinamiche e dei metadati delle colonne
    await schemaRepository.deleteSchemaForDataset(datasetId);
    // Si elimina l'entità principale
    await datasetsRepository.deleteDataset(datasetId);
  }
}
