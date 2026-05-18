import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/value_objects/aggregation_type.dart';
import 'package:exel_category/domain/value_objects/chart_type.dart';

class ChartSuggestion {
  final ChartType chartType;
  final DatasetColumn? xColumn;
  final DatasetColumn? yColumn;
  final DatasetColumn? groupColumn;
  final AggregationType aggregationType;

  const ChartSuggestion({
    required this.chartType,
    this.xColumn,
    this.yColumn,
    this.groupColumn,
    this.aggregationType = AggregationType.count,
  });

  const ChartSuggestion.none()
      : chartType = ChartType.none,
        xColumn = null,
        yColumn = null,
        groupColumn = null,
        aggregationType = AggregationType.count;

  bool get hasChart => chartType.isImplemented;

  ChartSuggestion copyWith({
    ChartType? chartType,
    Object? xColumn = _notProvided,
    Object? yColumn = _notProvided,
    Object? groupColumn = _notProvided,
    AggregationType? aggregationType,
  }) {
    return ChartSuggestion(
      chartType: chartType ?? this.chartType,
      xColumn: identical(xColumn, _notProvided)
          ? this.xColumn
          : xColumn as DatasetColumn?,
      yColumn: identical(yColumn, _notProvided)
          ? this.yColumn
          : yColumn as DatasetColumn?,
      groupColumn: identical(groupColumn, _notProvided)
          ? this.groupColumn
          : groupColumn as DatasetColumn?,
      aggregationType: aggregationType ?? this.aggregationType,
    );
  }
}

const Object _notProvided = Object();
