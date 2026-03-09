import 'package:exel_category/domain/entities/dataset.dart';

/// ViewModel responsible for managing DatasetView state.
///
/// Responsibilities:
///
/// - Load dataset metadata
/// - Load UI state from uiStateJson
/// - Handle filter changes
/// - Execute data queries
/// - Persist UI state
///
/// This class communicates with the Application Layer:
///
/// DatasetView
/// ↓
/// DatasetViewModel
/// ↓
/// Application Services
/// ↓
/// Domain UseCases
/// ↓
/// Repositories
class DatasetViewModel {

  /// Current dataset loaded in workspace
  Dataset? dataset;

  /// Currently selected sheet
  String? activeSheet;

  /// Map storing filters for current sheet
  Map<String, dynamic> activeFilters = {};

  /// Visible columns
  List<String> visibleColumns = [];

  /// Current result rows
  List<Map<String, dynamic>> rows = [];

  /// View mode: table or cards
  String viewMode = "table";

  /// TODO
  /// Load dataset and restore UI state
  Future<void> loadDataset(int datasetId) async {
    throw UnimplementedError();
  }

  /// TODO
  /// Change active sheet
  /// - update UI state
  /// - reload rows
  Future<void> changeSheet(String sheetName) async {
    throw UnimplementedError();
  }

  /// TODO
  /// Update filters for a column
  /// - update filter state
  /// - execute query
  /// - persist uiStateJson
  Future<void> updateFilter(
    String column,
    dynamic value,
  ) async {
    throw UnimplementedError();
  }

  /// TODO
  /// Execute query with current filters
  Future<void> refreshResults() async {
    throw UnimplementedError();
  }

  /// TODO
  /// Persist UI state to dataset.uiStateJson
  Future<void> saveUiState() async {
    throw UnimplementedError();
  }
}