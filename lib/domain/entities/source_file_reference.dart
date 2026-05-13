import 'package:exel_category/domain/entities/dataset_file.dart';
import 'package:exel_category/domain/value_objects/dataset_file_storage_mode.dart';

/// Domain entity representing a prepared source file reference.
///
/// It is created before dataset persistence and can later be converted into
/// DatasetFile metadata once a dataset id exists.
class SourceFileReference {
  final String fileName;
  final DatasetFileStorageMode storageMode;
  final String? originalPath;
  final String? storedPath;
  final DateTime importedAt;
  final int? fileSize;

  const SourceFileReference({
    required this.fileName,
    required this.storageMode,
    this.originalPath,
    this.storedPath,
    required this.importedAt,
    this.fileSize,
  });

  DatasetFile toDatasetFile({
    required int datasetId,
    int id = 0,
  }) {
    return DatasetFile(
      id: id,
      datasetId: datasetId,
      storageMode: storageMode,
      originalPath: originalPath,
      storedPath: storedPath,
      importedAt: importedAt,
      fileSize: fileSize,
    );
  }
}
