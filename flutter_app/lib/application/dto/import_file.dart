import 'package:exlser/application/exceptions/import_exceptions.dart';

/// Represents the input file used by the import pipeline.
///
/// The file can come from:
/// - memory bytes, typically web upload / drag and drop
/// - a filesystem path, typically mobile or desktop
///
/// This DTO does not describe persistence.
/// Persistence metadata is handled separately by DatasetFile.
class ImportFile {
  final String fileName;
  final List<int>? bytes;
  final String? path;

  const ImportFile._({
    required this.fileName,
    this.bytes,
    this.path,
  });

  /// Creates an import file from in-memory bytes.
  factory ImportFile.fromBytes({
    required String fileName,
    required List<int> bytes,
  }) {
    final normalizedFileName = _normalizeFileName(fileName);

    if (bytes.isEmpty) {
      throw const InvalidImportFileException(
        code: 'empty_file_bytes',
        message: 'File bytes cannot be empty',
      );
    }

    return ImportFile._(
      fileName: normalizedFileName,
      bytes: List.unmodifiable(bytes),
    );
  }

  /// Creates an import file from a filesystem path.
  factory ImportFile.fromPath({
    required String fileName,
    required String path,
  }) {
    final normalizedFileName = _normalizeFileName(fileName);
    final normalizedPath = path.trim();

    if (normalizedPath.isEmpty) {
      throw const InvalidImportFileException(
        code: 'empty_file_path',
        message: 'File path cannot be empty',
      );
    }

    return ImportFile._(
      fileName: normalizedFileName,
      path: normalizedPath,
    );
  }

  bool get hasBytes => bytes != null;

  bool get hasPath => path != null;

  static String _normalizeFileName(String fileName) {
    final normalized = fileName.trim();

    if (normalized.isEmpty) {
      throw const InvalidImportFileException(
        code: 'empty_file_name',
        message: 'File name cannot be empty',
      );
    }

    return normalized;
  }
}
