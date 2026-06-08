import 'package:exlser/domain/entities/chart_suggestion.dart';
import 'package:exlser/domain/value_objects/aggregation_type.dart';
import 'package:exlser/domain/value_objects/chart_type.dart';

enum ChartValidationResult {
  valid,
  missingYColumn,
  invalidAggregation,
  invalidXColumn,
  invalidYColumn,
  chartTypeNotSupported,
}

/// Validates chart configurations to prevent invalid combinations.
/// Enforces rules like: SUM/AVG/MIN/MAX require a numeric Y column.
class ChartConfigValidator {
  ChartConfigValidator._();

  /// Returns true if the aggregation is valid for the given chart type and Y column state.
  static bool isAggregationValidForChartType(
    ChartType chartType,
    AggregationType aggregationType,
    bool hasYColumn,
  ) {
    if (!chartType.isImplemented) {
      return false;
    }

    if (chartType.requiresYColumn && !hasYColumn) {
      return false;
    }

    final needsYColumn = aggregationType != AggregationType.count;

    if (needsYColumn && !hasYColumn) {
      return false;
    }

    return true;
  }

  /// Returns list of aggregations that are valid for the given chart type and Y column state.
  static List<AggregationType> getValidAggregations(
    ChartType chartType,
    bool hasYColumn,
  ) {
    if (!chartType.isImplemented) {
      return [];
    }

    if (chartType.requiresYColumn && !hasYColumn) {
      return [];
    }

    if (hasYColumn) {
      return AggregationType.values;
    }

    return [AggregationType.count];
  }

  /// Validates a chart suggestion for correctness.
  static ChartValidationResult validateChartSuggestion(
    ChartSuggestion suggestion,
  ) {
    if (!suggestion.chartType.isImplemented) {
      return ChartValidationResult.chartTypeNotSupported;
    }

    final xColumn = suggestion.xColumn;
    final yColumn = suggestion.yColumn;
    final chartType = suggestion.chartType;
    final aggregationType = suggestion.aggregationType;

    if (chartType.requiresYColumn && yColumn == null) {
      return ChartValidationResult.missingYColumn;
    }

    // Check X column validity
    if (xColumn != null) {
      if (!chartType.validXColumnTypes.contains(xColumn.inferredType)) {
        return ChartValidationResult.invalidXColumn;
      }
    }

    // Check aggregation validity: SUM/AVG/MIN/MAX require Y column
    if (aggregationType != AggregationType.count && yColumn == null) {
      return ChartValidationResult.missingYColumn;
    }

    // Check Y column validity
    if (yColumn != null) {
      if (!chartType.validYColumnTypes.contains(yColumn.inferredType)) {
        return ChartValidationResult.invalidYColumn;
      }
    }

    return ChartValidationResult.valid;
  }
}
