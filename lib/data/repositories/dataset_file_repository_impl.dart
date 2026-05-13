import 'package:exel_category/core/database/daos/dataset_files_dao.dart';
import 'package:exel_category/domain/entities/dataset_file.dart';
import 'package:exel_category/domain/repositories/dataset_file_repository.dart';
import 'package:exel_category/domain/value_objects/dataset_file_storage_mode.dart';

class DatasetFileRepositoryImpl implements DatasetFileRepository {
  final DatasetFilesDao dao;

  const DatasetFileRepositoryImpl({
    required this.dao,
  });

  @override
  Future<DatasetFile> createDatasetFile(DatasetFile file) async {
    final id = await dao.createDatasetFile(
      datasetId: file.datasetId,
      storageMode: file.storageMode.toDbValue(),
      originalPath: file.originalPath,
      storedPath: file.storedPath,
      importedAt: file.importedAt,
      fileSize: file.fileSize,
    );

    return file.copyWith(id: id);
  }

  @override
  Future<DatasetFile?> getByDatasetId(int datasetId) async {
    final row = await dao.getByDatasetId(datasetId);

    if (row == null) return null;

    return DatasetFile(
      id: row.id,
      datasetId: row.datasetId,
      storageMode: DatasetFileStorageModeMapper.fromDbValue(row.storageMode),
      originalPath: row.originalPath,
      storedPath: row.storedPath,
      importedAt: row.importedAt,
      fileSize: row.fileSize,
    );
  }

  @override
  Future<void> deleteByDatasetId(int datasetId) async {
    await dao.deleteByDatasetId(datasetId);
  }
}
