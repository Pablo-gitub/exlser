import 'package:exlser/data/datasources/file_storage/local_file_storage.dart';
import 'package:exlser/domain/entities/source_file_reference.dart';
import 'package:exlser/domain/value_objects/dataset_file_storage_mode.dart';

/// Data source responsible for representing imported source files.
///
/// This layer does not create datasets, tables, or rows. It only prepares
/// metadata describing how the original file can be referenced later.
class FileDatasource {
  final String? storageRootPath;

  const FileDatasource({
    this.storageRootPath,
  });

  Future<SourceFileReference> referencePath({
    required String fileName,
    required String path,
    DateTime? importedAt,
  }) async {
    return SourceFileReference(
      fileName: fileName,
      storageMode: DatasetFileStorageMode.path,
      originalPath: path,
      importedAt: importedAt ?? DateTime.now(),
    );
  }

  Future<SourceFileReference> referenceBytes({
    required String fileName,
    required List<int> bytes,
    DateTime? importedAt,
  }) async {
    return SourceFileReference(
      fileName: fileName,
      storageMode: DatasetFileStorageMode.webTemporary,
      importedAt: importedAt ?? DateTime.now(),
      fileSize: bytes.length,
    );
  }

  Future<SourceFileReference> copyPath({
    required String fileName,
    required String path,
    DateTime? importedAt,
  }) async {
    final copiedFile = await copyPathToAppStorage(
      fileName: fileName,
      sourcePath: path,
      storageRootPath: storageRootPath,
    );

    return SourceFileReference(
      fileName: fileName,
      storageMode: DatasetFileStorageMode.pathAndCopy,
      originalPath: path,
      storedPath: copiedFile.storedPath,
      importedAt: importedAt ?? DateTime.now(),
      fileSize: copiedFile.fileSize,
    );
  }
}
