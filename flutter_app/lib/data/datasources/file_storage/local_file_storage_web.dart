import 'file_copy_result.dart';

Future<FileCopyResult> copyPathToAppStorageImpl({
  required String fileName,
  required String sourcePath,
  String? storageRootPath,
}) {
  throw UnsupportedError(
    'Local file copy is not supported on web path imports.',
  );
}
