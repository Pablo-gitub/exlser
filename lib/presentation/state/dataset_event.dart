import 'dataset_state.dart';

abstract class DatasetEvent {
  const DatasetEvent();
}

class LoadDatasetEvent extends DatasetEvent {
  final int datasetId;

  const LoadDatasetEvent(this.datasetId);
}

class ChangeSheetEvent extends DatasetEvent {
  final int tableId;

  const ChangeSheetEvent(this.tableId);
}

class RefreshResultsEvent extends DatasetEvent {
  const RefreshResultsEvent();
}

class ChangeViewModeEvent extends DatasetEvent {
  final DatasetViewMode viewMode;

  const ChangeViewModeEvent(this.viewMode);
}
