/// Events dispatched to DatasetBloc.
///
/// Events represent user interactions or UI triggers.
abstract class DatasetEvent {}

/// Load dataset workspace.
class LoadDatasetEvent extends DatasetEvent {
  final int datasetId;

  LoadDatasetEvent(this.datasetId);
}

/// Change active sheet.
class ChangeSheetEvent extends DatasetEvent {
  final String sheetName;

  ChangeSheetEvent(this.sheetName);
}

/// Update filter for a column.
class UpdateFilterEvent extends DatasetEvent {
  final String column;
  final dynamic value;

  UpdateFilterEvent(this.column, this.value);
}

/// Refresh dataset query results.
class RefreshResultsEvent extends DatasetEvent {}

/// Change result visualization mode.
class ChangeViewModeEvent extends DatasetEvent {
  final String mode; // table or cards

  ChangeViewModeEvent(this.mode);
}