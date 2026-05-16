import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'file_copy_result.dart';

Future<FileCopyResult> copyPathToAppStorageImpl({
  required String fileName,
  required String sourcePath,
  String? storageRootPath,
}) async {
  final sourceFile = File(sourcePath);

  if (!await sourceFile.exists()) {
    throw Exception('Source file does not exist: $sourcePath');
  }

  final rootPath =
      storageRootPath ?? (await getApplicationDocumentsDirectory()).path;
  final importsDirectory = Directory(
    p.join(rootPath, 'imports'),
  );

  await importsDirectory.create(recursive: true);

  final storedPath = await _resolveAvailablePath(
    directoryPath: importsDirectory.path,
    fileName: _sanitizeFileName(fileName),
  );

  final copiedFile = await sourceFile.copy(storedPath);

  return FileCopyResult(
    storedPath: copiedFile.path,
    fileSize: await copiedFile.length(),
  );
}

Future<String> _resolveAvailablePath({
  required String directoryPath,
  required String fileName,
}) async {
  final extension = p.extension(fileName);
  final baseName = p.basenameWithoutExtension(fileName);

  var candidate = p.join(directoryPath, fileName);
  var index = 1;

  while (await File(candidate).exists()) {
    candidate = p.join(
      directoryPath,
      '${baseName}_$index$extension',
    );
    index++;
  }

  return candidate;
}

String _sanitizeFileName(String fileName) {
  final sanitized =
      p.basename(fileName).replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_').trim();

  if (sanitized.isEmpty) {
    return 'imported_file';
  }

  return sanitized;
}
