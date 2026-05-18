import 'package:exel_category/domain/entities/chart_suggestion.dart';
import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/value_objects/chart_type.dart';
import 'package:exel_category/domain/value_objects/dataset_filter.dart';
import 'package:exel_category/domain/value_objects/dataset_sort.dart';

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

class ChangeRowLimitEvent extends DatasetEvent {
  final int rowLimit;

  const ChangeRowLimitEvent(this.rowLimit);
}

class ChangePageEvent extends DatasetEvent {
  final int pageIndex;

  const ChangePageEvent(this.pageIndex);
}

class AddFilterEvent extends DatasetEvent {
  final DatasetFilter filter;

  const AddFilterEvent(this.filter);
}

class RemoveFilterEvent extends DatasetEvent {
  final String filterId;

  const RemoveFilterEvent(this.filterId);
}

class ClearFiltersEvent extends DatasetEvent {
  const ClearFiltersEvent();
}

class ChangeSortEvent extends DatasetEvent {
  final DatasetSort? sort;

  const ChangeSortEvent(this.sort);
}

class ToggleSortColumnEvent extends DatasetEvent {
  final DatasetColumn column;

  const ToggleSortColumnEvent(this.column);
}

class LoadAnalyticsEvent extends DatasetEvent {
  const LoadAnalyticsEvent();
}

class AddChartEvent extends DatasetEvent {
  final ChartType chartType;

  const AddChartEvent(this.chartType);
}

class RemoveChartEvent extends DatasetEvent {
  final String chartId;

  const RemoveChartEvent(this.chartId);
}

class UpdateChartConfigEvent extends DatasetEvent {
  final String chartId;
  final ChartSuggestion suggestion;

  const UpdateChartConfigEvent({
    required this.chartId,
    required this.suggestion,
  });
}
