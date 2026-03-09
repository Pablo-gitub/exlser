/// ViewModel responsible for cross-sheet analytics.
///
/// Responsibilities:
/// - load dataset tables
/// - allow selecting sheets
/// - execute analytics operations
///
/// Analytics operations will be delegated to:
/// Application Layer → AnalysisService.
class MultiDatasetAnalyticsViewModel {

  /// Selected sheets for the operation.
  List<String> selectedSheets = [];

  /// Selected analytics operation.
  String? operation;

  /// TODO:
  /// Load available dataset tables (sheets).
  Future<void> loadSheets(int datasetId) async {
    throw UnimplementedError();
  }

  /// TODO:
  /// Execute selected analytics operation.
  ///
  /// Example operations:
  /// - merge
  /// - join
  /// - compare
  /// - diff
  /// - consistency check
  Future<void> executeOperation() async {
    throw UnimplementedError();
  }
}