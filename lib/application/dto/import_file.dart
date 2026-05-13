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
    if (fileName.trim().isEmpty) {
      throw Exception('File name cannot be empty');
    }

    if (bytes.isEmpty) {
      throw Exception('File bytes cannot be empty');
    }

    return ImportFile._(
      fileName: fileName,
      bytes: bytes,
    );
  }

  /// Creates an import file from a filesystem path.
  factory ImportFile.fromPath({
    required String fileName,
    required String path,
  }) {
    if (fileName.trim().isEmpty) {
      throw Exception('File name cannot be empty');
    }

    if (path.trim().isEmpty) {
      throw Exception('File path cannot be empty');
    }

    return ImportFile._(
      fileName: fileName,
      path: path,
    );
  }

  bool get hasBytes => bytes != null;

  bool get hasPath => path != null;
}