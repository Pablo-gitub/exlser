import 'local_file_storage_native.dart'
    if (dart.library.html) 'local_file_storage_web.dart';
import 'file_copy_result.dart';

export 'file_copy_result.dart';

/// Copies a path-based import into app-controlled storage.
///
/// [storageRootPath] is injectable for tests. In production, native platforms
/// use the application documents directory.
Future<FileCopyResult> copyPathToAppStorage({
  required String fileName,
  required String sourcePath,
  String? storageRootPath,
}) {
  return copyPathToAppStorageImpl(
    fileName: fileName,
    sourcePath: sourcePath,
    storageRootPath: storageRootPath,
  );
}
