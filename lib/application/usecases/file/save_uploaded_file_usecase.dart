import 'package:exlser/application/dto/import_file.dart';
import 'package:exlser/data/datasources/file_datasource.dart';
import 'package:exlser/domain/entities/source_file_reference.dart';

/// Prepares source file metadata before dataset creation.
///
/// Current behavior:
/// - path-based imports are referenced by original path
/// - path-based imports can be copied into app storage
/// - byte-based imports are marked as web-temporary
///
/// This use case does not persist dataset metadata or parsed rows.
class SaveUploadedFileUseCase {
  final FileDatasource datasource;

  const SaveUploadedFileUseCase({
    required this.datasource,
  });

  Future<SourceFileReference> call(
    ImportFile file, {
    DateTime? importedAt,
    bool saveLocally = false,
  }) {
    if (file.hasPath) {
      if (saveLocally) {
        return datasource.copyPath(
          fileName: file.fileName,
          path: file.path!,
          importedAt: importedAt,
        );
      }

      return datasource.referencePath(
        fileName: file.fileName,
        path: file.path!,
        importedAt: importedAt,
      );
    }

    return datasource.referenceBytes(
      fileName: file.fileName,
      bytes: file.bytes!,
      importedAt: importedAt,
    );
  }
}
