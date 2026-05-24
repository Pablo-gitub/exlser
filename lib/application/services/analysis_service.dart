import 'package:exel_category/application/dto/chart_data.dart';
import 'package:exel_category/application/dto/chart_load_result.dart';
import 'package:exel_category/domain/entities/chart_suggestion.dart';
import 'package:exel_category/domain/entities/column_statistics.dart';
import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/exceptions/invalid_chart_config_exception.dart';
import 'package:exel_category/domain/usecases/analytics/get_category_distribution_usecase.dart';
import 'package:exel_category/domain/usecases/analytics/get_column_statistics_usecase.dart';
import 'package:exel_category/domain/usecases/analytics/get_time_series_usecase.dart';
import 'package:exel_category/domain/usecases/analytics/suggest_charts_usecase.dart';
import 'package:exel_category/domain/value_objects/chart_type.dart';
import 'package:exel_category/presentation/state/dataset_state.dart';

/// Orchestrates analytical operations on dataset tables.
///
/// Responsibilities:
/// - suggest the initial chart from column types
/// - load chart data for the active suggestion and filters
/// - compute column statistics on demand
class AnalysisService {
  final SuggestChartsUseCase suggestChartsUseCase;
  final GetColumnStatisticsUseCase getColumnStatisticsUseCase;
  final GetCategoryDistributionUseCase getCategoryDistributionUseCase;
  final GetTimeSeriesUseCase getTimeSeriesUseCase;

  const AnalysisService({
    required this.suggestChartsUseCase,
    required this.getCategoryDistributionUseCase,
    required this.getColumnStatisticsUseCase,
    required this.getTimeSeriesUseCase,
  });

  ChartSuggestion suggestChart(List<DatasetColumn> columns) =>
      suggestChartsUseCase(columns);

  List<ChartSuggestion> suggestAllCharts(List<DatasetColumn> columns) =>
      suggestChartsUseCase.suggestAll(columns);

  Future<ColumnStatistics> getColumnStatistics({
    required String tableName,
    required DatasetColumn column,
    String? whereClause,
    List<Object?>? whereArguments,
  }) {
    return getColumnStatisticsUseCase(
      tableName: tableName,
      column: column,
      whereClause: whereClause,
      whereArguments: whereArguments,
    );
  }

  Future<ChartLoadResult> loadChartData({
    required String tableName,
    required ChartSuggestion suggestion,
    String? whereClause,
    List<Object?>? whereArguments,
  }) async {
    if (!suggestion.hasChart) {
      return ChartLoadResult.error(ChartLoadError.chartTypeNotSupported);
    }

    final xCol = suggestion.xColumn;
    final yCol = suggestion.yColumn;
    final agg = suggestion.aggregationType;

    try {
      if (suggestion.chartType == ChartType.line &&
          xCol != null &&
          yCol != null) {
        final data = await getTimeSeriesUseCase(
          tableName: tableName,
          xColumn: xCol,
          yColumn: yCol,
          aggregationType: agg,
          whereClause: whereClause,
          whereArguments: whereArguments,
        );
        return ChartLoadResult.success(data);
      }

      if ((suggestion.chartType == ChartType.bar ||
              suggestion.chartType == ChartType.pie) &&
          xCol != null) {
        final data = await getCategoryDistributionUseCase(
          tableName: tableName,
          xColumn: xCol,
          yColumn: yCol,
          aggregationType: agg,
          chartType: suggestion.chartType,
          whereClause: whereClause,
          whereArguments: whereArguments,
        );
        return ChartLoadResult.success(data);
      }

      return ChartLoadResult.error(ChartLoadError.chartTypeNotSupported);
    } on InvalidChartConfigException {
      return ChartLoadResult.error(ChartLoadError.invalidAggregation);
    } catch (e) {
      return ChartLoadResult.error(ChartLoadError.internalFailure);
    }
  }
}
