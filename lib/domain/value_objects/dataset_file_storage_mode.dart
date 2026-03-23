/// Represents how the source file is handled.
///
/// - path: only original file path is stored
/// - pathAndCopy: file is copied into app storage
/// - webTemporary: file exists only in browser session
/// - webPersisted: file is persisted in browser storage
enum DatasetFileStorageMode {
  path,
  pathAndCopy,
  webTemporary,
  webPersisted,
}

/// Extension for serialization (DB <-> domain)
extension DatasetFileStorageModeMapper on DatasetFileStorageMode {
  String toDbValue() {
    return name;
  }

  static DatasetFileStorageMode fromDbValue(String value) {
    return DatasetFileStorageMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DatasetFileStorageMode.path,
    );
  }
}