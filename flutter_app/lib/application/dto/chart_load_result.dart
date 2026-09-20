import 'package:exlser/domain/value_objects/chart_data.dart';

/// Why a chart could not be built from the data it was asked for.
///
/// Lives with the result that carries it: the analysis layer decides these
/// cases, the presentation layer only renders them.
enum ChartLoadError {
  noNumericColumn,
  invalidAggregation,
  noRowsAfterFilter,
  chartTypeNotSupported,
  internalFailure,
}

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
