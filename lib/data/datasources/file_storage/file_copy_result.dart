/// Result of copying an imported file into application storage.
class FileCopyResult {
  final String storedPath;
  final int fileSize;

  const FileCopyResult({
    required this.storedPath,
    required this.fileSize,
  });
}
