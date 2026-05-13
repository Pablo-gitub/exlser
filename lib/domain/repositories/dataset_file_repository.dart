import 'package:exel_category/domain/entities/dataset_file.dart';

/// Repository contract for source file metadata associated with datasets.
abstract class DatasetFileRepository {
  Future<DatasetFile> createDatasetFile(DatasetFile file);

  Future<DatasetFile?> getByDatasetId(int datasetId);

  Future<void> deleteByDatasetId(int datasetId);
}
