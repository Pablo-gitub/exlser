import 'package:exel_category/application/dto/chart_data.dart';
import 'package:exel_category/presentation/state/dataset_state.dart';

/// Result of loading chart data, containing both data and optional error.
class ChartLoadResult {
  final ChartData data;
  final ChartLoadError? error;

  const ChartLoadResult({
    required this.data,
    this.error,
  });

  bool get hasError => error != null;

  factory ChartLoadResult.success(ChartData data) {
    return ChartLoadResult(data: data);
  }

  factory ChartLoadResult.error(ChartLoadError error) {
    return ChartLoadResult(data: const EmptyChartData(), error: error);
  }
}
