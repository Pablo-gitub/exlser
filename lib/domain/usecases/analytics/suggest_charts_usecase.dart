import 'package:exlser/domain/entities/chart_suggestion.dart';
import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/value_objects/aggregation_type.dart';
import 'package:exlser/domain/value_objects/chart_type.dart';
import 'package:exlser/domain/value_objects/column_type.dart';

/// Suggests charts based on column types.
///
/// `call()` returns the single best suggestion (priority order).
/// `suggestAll()` returns one suggestion per supported chart type.
class SuggestChartsUseCase {
  const SuggestChartsUseCase();

  /// Returns one suggestion per chart type supported by the column set.
  List<ChartSuggestion> suggestAll(List<DatasetColumn> columns) {
    if (columns.isEmpty) return [];

    final suggestions = <ChartSuggestion>[];

    final line = _suggestLine(columns);
    if (line != null) suggestions.add(line);

    final bar = _suggestBar(columns);
    if (bar != null) suggestions.add(bar);

    final pie = _suggestPie(columns);
    if (pie != null) suggestions.add(pie);

    return suggestions;
  }

  ChartSuggestion? _suggestLine(List<DatasetColumn> columns) {
    final dates = columns.where((c) => c.declaredType == ColumnType.date);
    final numerics = columns.where((c) => c.isNumeric);
    if (dates.isEmpty || numerics.isEmpty) return null;
    return ChartSuggestion(
      chartType: ChartType.line,
      xColumn: dates.first,
      yColumn: numerics.first,
      aggregationType: AggregationType.sum,
    );
  }

  ChartSuggestion? _suggestBar(List<DatasetColumn> columns) {
    final xCandidates = columns.where(
      (c) => ChartType.bar.validXColumnTypes.contains(c.declaredType),
    );
    if (xCandidates.isEmpty) return null;
    final numerics = columns.where((c) => c.isNumeric);
    return ChartSuggestion(
      chartType: ChartType.bar,
      xColumn: xCandidates.first,
      yColumn: numerics.isNotEmpty ? numerics.first : null,
      aggregationType:
          numerics.isNotEmpty ? AggregationType.sum : AggregationType.count,
    );
  }

  ChartSuggestion? _suggestPie(List<DatasetColumn> columns) {
    final xCandidates = columns.where(
      (c) => ChartType.pie.validXColumnTypes.contains(c.declaredType),
    );
    if (xCandidates.isEmpty) return null;
    final numerics = columns.where((c) => c.isNumeric);
    return ChartSuggestion(
      chartType: ChartType.pie,
      xColumn: xCandidates.first,
      yColumn: numerics.isNotEmpty ? numerics.first : null,
      aggregationType:
          numerics.isNotEmpty ? AggregationType.sum : AggregationType.count,
    );
  }

  /// Returns the single best suggestion using priority order.
  ChartSuggestion call(List<DatasetColumn> columns) {
    if (columns.isEmpty) return const ChartSuggestion.none();

    final dateColumns =
        columns.where((c) => c.declaredType == ColumnType.date).toList();
    final numericColumns = columns.where((c) => c.isNumeric).toList();
    final textColumns =
        columns.where((c) => c.declaredType == ColumnType.text).toList();
    final booleanColumns =
        columns.where((c) => c.declaredType == ColumnType.boolean).toList();

    if (dateColumns.isNotEmpty && numericColumns.isNotEmpty) {
      return ChartSuggestion(
        chartType: ChartType.line,
        xColumn: dateColumns.first,
        yColumn: numericColumns.first,
        aggregationType: AggregationType.sum,
      );
    }

    if (textColumns.isNotEmpty && numericColumns.isNotEmpty) {
      return ChartSuggestion(
        chartType: ChartType.bar,
        xColumn: textColumns.first,
        yColumn: numericColumns.first,
        aggregationType: AggregationType.sum,
      );
    }

    if (booleanColumns.isNotEmpty) {
      return ChartSuggestion(
        chartType: ChartType.bar,
        xColumn: booleanColumns.first,
        aggregationType: AggregationType.count,
      );
    }

    if (textColumns.isNotEmpty) {
      return ChartSuggestion(
        chartType: ChartType.bar,
        xColumn: textColumns.first,
        aggregationType: AggregationType.count,
      );
    }

    return const ChartSuggestion.none();
  }
}
