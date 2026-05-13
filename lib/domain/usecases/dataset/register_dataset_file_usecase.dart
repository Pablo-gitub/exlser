import 'package:exel_category/domain/entities/dataset_file.dart';
import 'package:exel_category/domain/entities/source_file_reference.dart';
import 'package:exel_category/domain/repositories/dataset_file_repository.dart';

class RegisterDatasetFileUseCase {
  final DatasetFileRepository repository;

  const RegisterDatasetFileUseCase({
    required this.repository,
  });

  Future<DatasetFile> call({
    required int datasetId,
    required SourceFileReference sourceFileReference,
  }) {
    if (datasetId <= 0) {
      throw Exception('Dataset id must be greater than 0');
    }

    final datasetFile = sourceFileReference.toDatasetFile(
      datasetId: datasetId,
    );

    return repository.createDatasetFile(datasetFile);
  }
}
