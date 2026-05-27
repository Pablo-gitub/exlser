import 'package:exlser/application/dto/chart_data.dart';
import 'package:exlser/application/dto/chart_load_result.dart';
import 'package:exlser/domain/entities/chart_suggestion.dart';
import 'package:exlser/domain/entities/column_statistics.dart';
import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/exceptions/invalid_chart_config_exception.dart';
import 'package:exlser/domain/usecases/analytics/get_category_distribution_usecase.dart';
import 'package:exlser/domain/usecases/analytics/get_column_statistics_usecase.dart';
import 'package:exlser/domain/usecases/analytics/get_time_series_usecase.dart';
import 'package:exlser/domain/usecases/analytics/suggest_charts_usecase.dart';
import 'package:exlser/domain/value_objects/aggregation_type.dart';
import 'package:exlser/domain/value_objects/chart_type.dart';
import 'package:exlser/presentation/state/dataset_state.dart';

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

  Future<ChartLoadResult> loadChartDataFromRows({
    required List<Map<String, dynamic>> rows,
    required ChartSuggestion suggestion,
  }) async {
    if (!suggestion.hasChart) {
      return ChartLoadResult.error(ChartLoadError.chartTypeNotSupported);
    }
    if (rows.isEmpty) {
      return ChartLoadResult.error(ChartLoadError.noRowsAfterFilter);
    }

    final xCol = suggestion.xColumn;
    final yCol = suggestion.yColumn;
    final agg = suggestion.aggregationType;

    try {
      if (suggestion.chartType == ChartType.line && xCol != null) {
        final buckets = <DateTime, _AggregationBucket>{};
        for (final row in rows) {
          final date = _dateValue(row[xCol.dbName]);
          if (date == null) continue;
          final bucketDate = DateTime(date.year, date.month, date.day);
          final bucket = buckets.putIfAbsent(
            bucketDate,
            () => _AggregationBucket(),
          );
          if (agg == AggregationType.count) {
            bucket.addCount();
          } else {
            final numeric =
                yCol == null ? null : _numericValue(row[yCol.dbName]);
            bucket.addNumeric(numeric);
          }
        }

        final points = [
          for (final entry in buckets.entries)
            TimeSeriesPoint(x: entry.key, y: entry.value.valueFor(agg)),
        ]..sort((a, b) => a.x.compareTo(b.x));

        return ChartLoadResult.success(
          TimeSeriesChartData(
            xLabel: xCol.originalName,
            yLabel: _yLabel(agg, yCol),
            points: points,
          ),
        );
      }

      if ((suggestion.chartType == ChartType.bar ||
              suggestion.chartType == ChartType.pie) &&
          xCol != null) {
        final buckets = <String, _AggregationBucket>{};
        for (final row in rows) {
          final rawLabel = row[xCol.dbName];
          final label = rawLabel == null || rawLabel.toString().trim().isEmpty
              ? '-'
              : rawLabel.toString();
          final bucket = buckets.putIfAbsent(label, () => _AggregationBucket());
          if (agg == AggregationType.count) {
            bucket.addCount();
          } else {
            final numeric =
                yCol == null ? null : _numericValue(row[yCol.dbName]);
            bucket.addNumeric(numeric);
          }
        }

        final points = [
          for (final entry in buckets.entries)
            CategoryPoint(label: entry.key, value: entry.value.valueFor(agg)),
        ]..sort((a, b) => b.value.compareTo(a.value));

        return ChartLoadResult.success(
          CategoryChartData(
            chartType: suggestion.chartType,
            xLabel: xCol.originalName,
            yLabel: _yLabel(agg, yCol),
            points: points,
            aggregationType: agg,
          ),
        );
      }

      return ChartLoadResult.error(ChartLoadError.chartTypeNotSupported);
    } catch (_) {
      return ChartLoadResult.error(ChartLoadError.internalFailure);
    }
  }
}

class _AggregationBucket {
  int count = 0;
  double sum = 0;
  double? min;
  double? max;

  void addCount() {
    count += 1;
  }

  void addNumeric(double? value) {
    if (value == null) return;

    count += 1;
    sum += value;
    min = min == null || value < min! ? value : min;
    max = max == null || value > max! ? value : max;
  }

  double valueFor(AggregationType aggregationType) {
    return switch (aggregationType) {
      AggregationType.count => count.toDouble(),
      AggregationType.sum => sum,
      AggregationType.avg => count == 0 ? 0 : sum / count,
      AggregationType.min => min ?? 0,
      AggregationType.max => max ?? 0,
    };
  }
}

double? _numericValue(Object? value) {
  if (value is int) return value.toDouble();
  if (value is double) return value;
  if (value is num) return value.toDouble();

  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;

  return double.tryParse(text.replaceAll(',', '.'));
}

DateTime? _dateValue(Object? value) {
  if (value is DateTime) return value;

  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;

  return DateTime.tryParse(text);
}

String _yLabel(AggregationType aggregationType, DatasetColumn? column) {
  if (aggregationType == AggregationType.count || column == null) {
    return aggregationType.sqlFunction;
  }

  return '${aggregationType.sqlFunction} ${column.originalName}';
}
