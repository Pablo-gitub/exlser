import '../value_objects/dataset_file_storage_mode.dart';

/// Domain entity representing the file associated with a dataset.
///
/// This entity describes how the file is stored and accessed,
/// independently from the underlying database implementation.
class DatasetFile {
  final int id;
  final int datasetId;

  final DatasetFileStorageMode storageMode;

  final String? originalPath;
  final String? storedPath;

  final DateTime importedAt;
  final int? fileSize;

  const DatasetFile({
    required this.id,
    required this.datasetId,
    required this.storageMode,
    this.originalPath,
    this.storedPath,
    required this.importedAt,
    this.fileSize,
  });

  /// Creates a copy with updated fields
  DatasetFile copyWith({
    int? id,
    int? datasetId,
    DatasetFileStorageMode? storageMode,
    String? originalPath,
    String? storedPath,
    DateTime? importedAt,
    int? fileSize,
  }) {
    return DatasetFile(
      id: id ?? this.id,
      datasetId: datasetId ?? this.datasetId,
      storageMode: storageMode ?? this.storageMode,
      originalPath: originalPath ?? this.originalPath,
      storedPath: storedPath ?? this.storedPath,
      importedAt: importedAt ?? this.importedAt,
      fileSize: fileSize ?? this.fileSize,
    );
  }

  /// True if file has been copied into app storage
  bool get isStoredLocally => storedPath != null;

  /// True if file depends on external path
  bool get isExternalReference => originalPath != null;

  /// True if file is usable offline (copied)
  bool get isPersistent =>
      storageMode == DatasetFileStorageMode.pathAndCopy ||
      storageMode == DatasetFileStorageMode.webPersisted;
}
