import 'package:exel_category/domain/entities/chart_config_validator.dart';
import 'package:exel_category/domain/entities/chart_suggestion.dart';
import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/value_objects/aggregation_type.dart';
import 'package:exel_category/domain/value_objects/chart_type.dart';
import 'package:exel_category/domain/value_objects/column_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartConfigValidator', () {
    group('isAggregationValidForChartType', () {
      test('COUNT is valid for category charts without Y column', () {
        expect(
          ChartConfigValidator.isAggregationValidForChartType(
            ChartType.bar,
            AggregationType.count,
            false,
          ),
          true,
        );
        expect(
          ChartConfigValidator.isAggregationValidForChartType(
            ChartType.pie,
            AggregationType.count,
            false,
          ),
          true,
        );
      });

      test('COUNT is invalid for line chart without Y column', () {
        expect(
          ChartConfigValidator.isAggregationValidForChartType(
            ChartType.line,
            AggregationType.count,
            false,
          ),
          false,
        );
      });

      test('COUNT is valid with Y column', () {
        expect(
          ChartConfigValidator.isAggregationValidForChartType(
            ChartType.bar,
            AggregationType.count,
            true,
          ),
          true,
        );
      });

      test('SUM/AVG/MIN/MAX are invalid without Y column', () {
        for (final agg in [
          AggregationType.sum,
          AggregationType.avg,
          AggregationType.min,
          AggregationType.max,
        ]) {
          expect(
            ChartConfigValidator.isAggregationValidForChartType(
              ChartType.bar,
              agg,
              false,
            ),
            false,
            reason: '$agg should be invalid without Y column',
          );
        }
      });

      test('SUM/AVG/MIN/MAX are valid with Y column', () {
        for (final agg in [
          AggregationType.sum,
          AggregationType.avg,
          AggregationType.min,
          AggregationType.max,
        ]) {
          expect(
            ChartConfigValidator.isAggregationValidForChartType(
              ChartType.bar,
              agg,
              true,
            ),
            true,
            reason: '$agg should be valid with Y column',
          );
        }
      });

      test('returns false for unimplemented chart types', () {
        expect(
          ChartConfigValidator.isAggregationValidForChartType(
            ChartType.scatter,
            AggregationType.count,
            false,
          ),
          false,
        );
        expect(
          ChartConfigValidator.isAggregationValidForChartType(
            ChartType.none,
            AggregationType.count,
            false,
          ),
          false,
        );
      });
    });

    group('getValidAggregations', () {
      test('returns only COUNT when no Y column', () {
        final valid = ChartConfigValidator.getValidAggregations(
          ChartType.bar,
          false,
        );
        expect(valid, [AggregationType.count]);
      });

      test('returns empty list for line charts without Y column', () {
        final valid = ChartConfigValidator.getValidAggregations(
          ChartType.line,
          false,
        );
        expect(valid, isEmpty);
      });

      test('returns all aggregations when Y column exists', () {
        final valid = ChartConfigValidator.getValidAggregations(
          ChartType.bar,
          true,
        );
        expect(
          valid,
          containsAll([
            AggregationType.count,
            AggregationType.sum,
            AggregationType.avg,
            AggregationType.min,
            AggregationType.max,
          ]),
        );
      });

      test('returns empty list for unimplemented chart types', () {
        final valid = ChartConfigValidator.getValidAggregations(
          ChartType.scatter,
          true,
        );
        expect(valid, isEmpty);
      });
    });

    group('validateChartSuggestion', () {
      final textColumn = DatasetColumn(
        id: 1,
        datasetTableId: 1,
        originalName: 'category',
        dbName: 'category',
        declaredType: ColumnType.text,
        inferredType: ColumnType.text,
        nullable: false,
        statsJson: null,
      );

      final numericColumn = DatasetColumn(
        id: 2,
        datasetTableId: 1,
        originalName: 'amount',
        dbName: 'amount',
        declaredType: ColumnType.integer,
        inferredType: ColumnType.integer,
        nullable: false,
        statsJson: null,
      );

      final dateColumn = DatasetColumn(
        id: 3,
        datasetTableId: 1,
        originalName: 'date',
        dbName: 'date',
        declaredType: ColumnType.date,
        inferredType: ColumnType.date,
        nullable: false,
        statsJson: null,
      );

      test('valid bar chart with text X and numeric Y', () {
        final suggestion = ChartSuggestion(
          chartType: ChartType.bar,
          xColumn: textColumn,
          yColumn: numericColumn,
          aggregationType: AggregationType.sum,
        );
        expect(
          ChartConfigValidator.validateChartSuggestion(suggestion),
          ChartValidationResult.valid,
        );
      });

      test('valid pie chart with COUNT and text X', () {
        final suggestion = ChartSuggestion(
          chartType: ChartType.pie,
          xColumn: textColumn,
          aggregationType: AggregationType.count,
        );
        expect(
          ChartConfigValidator.validateChartSuggestion(suggestion),
          ChartValidationResult.valid,
        );
      });

      test('valid line chart with date X and numeric Y', () {
        final suggestion = ChartSuggestion(
          chartType: ChartType.line,
          xColumn: dateColumn,
          yColumn: numericColumn,
          aggregationType: AggregationType.sum,
        );
        expect(
          ChartConfigValidator.validateChartSuggestion(suggestion),
          ChartValidationResult.valid,
        );
      });

      test('invalid bar chart with SUM but no Y column', () {
        final suggestion = ChartSuggestion(
          chartType: ChartType.bar,
          xColumn: textColumn,
          aggregationType: AggregationType.sum,
        );
        expect(
          ChartConfigValidator.validateChartSuggestion(suggestion),
          ChartValidationResult.missingYColumn,
        );
      });

      test('invalid line chart without Y column', () {
        final suggestion = ChartSuggestion(
          chartType: ChartType.line,
          xColumn: dateColumn,
          aggregationType: AggregationType.count,
        );
        expect(
          ChartConfigValidator.validateChartSuggestion(suggestion),
          ChartValidationResult.missingYColumn,
        );
      });

      test('invalid bar chart with numeric X column', () {
        final suggestion = ChartSuggestion(
          chartType: ChartType.bar,
          xColumn: numericColumn,
          yColumn: numericColumn,
          aggregationType: AggregationType.sum,
        );
        expect(
          ChartConfigValidator.validateChartSuggestion(suggestion),
          ChartValidationResult.invalidXColumn,
        );
      });

      test('invalid bar chart with text Y column', () {
        final suggestion = ChartSuggestion(
          chartType: ChartType.bar,
          xColumn: textColumn,
          yColumn: textColumn,
          aggregationType: AggregationType.sum,
        );
        expect(
          ChartConfigValidator.validateChartSuggestion(suggestion),
          ChartValidationResult.invalidYColumn,
        );
      });

      test('invalid line chart with text X column', () {
        final suggestion = ChartSuggestion(
          chartType: ChartType.line,
          xColumn: textColumn,
          yColumn: numericColumn,
          aggregationType: AggregationType.sum,
        );
        expect(
          ChartConfigValidator.validateChartSuggestion(suggestion),
          ChartValidationResult.invalidXColumn,
        );
      });

      test('rejects unimplemented chart types', () {
        final suggestion = ChartSuggestion(
          chartType: ChartType.scatter,
          xColumn: numericColumn,
          yColumn: numericColumn,
          aggregationType: AggregationType.count,
        );
        expect(
          ChartConfigValidator.validateChartSuggestion(suggestion),
          ChartValidationResult.chartTypeNotSupported,
        );
      });
    });
  });
}
