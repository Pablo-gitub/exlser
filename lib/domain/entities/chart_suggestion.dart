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

  bool get hasChart => chartType != ChartType.none;

  ChartSuggestion copyWith({
    ChartType? chartType,
    DatasetColumn? xColumn,
    DatasetColumn? yColumn,
    DatasetColumn? groupColumn,
    AggregationType? aggregationType,
  }) {
    return ChartSuggestion(
      chartType: chartType ?? this.chartType,
      xColumn: xColumn ?? this.xColumn,
      yColumn: yColumn ?? this.yColumn,
      groupColumn: groupColumn ?? this.groupColumn,
      aggregationType: aggregationType ?? this.aggregationType,
    );
  }
}
