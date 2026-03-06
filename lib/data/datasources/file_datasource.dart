/// Datasource responsible for file storage operations.
///
/// Responsibilities:
/// - Save imported files
/// - Load files from disk
/// - Handle platform-specific storage
/// - Provide file streams for parsers
class FileDatasource {

  /// TODO:
  /// Save file inside application storage.
  Future<String> saveFile() async {
    throw UnimplementedError();
  }

  /// TODO:
  /// Load file from provided path.
  Future<List<int>> loadFile() async {
    throw UnimplementedError();
  }

}