import 'package:exel_category/domain/value_objects/aggregation_type.dart';
import 'package:exel_category/domain/value_objects/chart_type.dart';

class CategoryPoint {
  final String label;
  final double value;

  const CategoryPoint({required this.label, required this.value});
}

class TimeSeriesPoint {
  final DateTime x;
  final double y;

  const TimeSeriesPoint({required this.x, required this.y});
}

sealed class ChartData {
  final ChartType chartType;
  final String xLabel;
  final String yLabel;

  const ChartData({
    required this.chartType,
    required this.xLabel,
    required this.yLabel,
  });
}

class CategoryChartData extends ChartData {
  final List<CategoryPoint> points;
  final AggregationType aggregationType;

  const CategoryChartData({
    required super.chartType,
    required super.xLabel,
    required super.yLabel,
    required this.points,
    required this.aggregationType,
  });

  bool get isEmpty => points.isEmpty;
}

class TimeSeriesChartData extends ChartData {
  final List<TimeSeriesPoint> points;

  const TimeSeriesChartData({
    required super.xLabel,
    required super.yLabel,
    required this.points,
  }) : super(chartType: ChartType.line);

  bool get isEmpty => points.isEmpty;
}

class EmptyChartData extends ChartData {
  const EmptyChartData()
      : super(chartType: ChartType.none, xLabel: '', yLabel: '');
}
