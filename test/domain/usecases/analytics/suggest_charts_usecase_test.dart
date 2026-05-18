import 'package:exel_category/domain/entities/chart_suggestion.dart';
import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/usecases/analytics/suggest_charts_usecase.dart';
import 'package:exel_category/domain/value_objects/aggregation_type.dart';
import 'package:exel_category/domain/value_objects/chart_type.dart';
import 'package:exel_category/domain/value_objects/column_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const useCase = SuggestChartsUseCase();

  group('SuggestChartsUseCase', () {
    test('returns none for empty column list', () {
      final result = useCase([]);
      expect(result.chartType, ChartType.none);
    });

    test('suggests line chart when date + numeric columns exist', () {
      final columns = [
        _col('date_col', ColumnType.date),
        _col('amount', ColumnType.integer),
      ];
      final result = useCase(columns);
      expect(result.chartType, ChartType.line);
      expect(result.xColumn?.dbName, 'date_col');
      expect(result.yColumn?.dbName, 'amount');
      expect(result.aggregationType, AggregationType.sum);
    });

    test('suggests bar chart when text + numeric columns exist (no date)', () {
      final columns = [
        _col('category', ColumnType.text),
        _col('sales', ColumnType.real),
      ];
      final result = useCase(columns);
      expect(result.chartType, ChartType.bar);
      expect(result.xColumn?.dbName, 'category');
      expect(result.yColumn?.dbName, 'sales');
    });

    test('prefers date+numeric over text+numeric', () {
      final columns = [
        _col('label', ColumnType.text),
        _col('date_col', ColumnType.date),
        _col('value', ColumnType.integer),
      ];
      final result = useCase(columns);
      expect(result.chartType, ChartType.line);
    });

    test('returns none for numeric-only columns until scatter is implemented',
        () {
      final columns = [
        _col('x', ColumnType.integer),
        _col('y', ColumnType.real),
      ];
      final result = useCase(columns);
      expect(result.chartType, ChartType.none);
    });

    test('suggests bar chart for boolean-only columns', () {
      final columns = [_col('active', ColumnType.boolean)];
      final result = useCase(columns);
      expect(result.chartType, ChartType.bar);
      expect(result.xColumn?.dbName, 'active');
      expect(result.aggregationType, AggregationType.count);
    });

    test('suggests bar chart for text-only columns', () {
      final columns = [_col('country', ColumnType.text)];
      final result = useCase(columns);
      expect(result.chartType, ChartType.bar);
      expect(result.xColumn?.dbName, 'country');
      expect(result.aggregationType, AggregationType.count);
    });

    test('returns none for a single numeric column', () {
      final columns = [_col('value', ColumnType.real)];
      final result = useCase(columns);
      expect(result.chartType, ChartType.none);
    });

    test('hasChart is false for none suggestion', () {
      final result = useCase([]);
      expect(result.hasChart, isFalse);
    });

    test('hasChart is true for non-none suggestions', () {
      final columns = [_col('category', ColumnType.text)];
      final result = useCase(columns);
      expect(result.hasChart, isTrue);
    });

    test('hasChart is false for unsupported scatter suggestions', () {
      final result = ChartSuggestion(
        chartType: ChartType.scatter,
        xColumn: _col('x', ColumnType.integer),
        yColumn: _col('y', ColumnType.real),
      );

      expect(result.hasChart, isFalse);
    });

    test('suggestAll excludes unsupported scatter charts', () {
      final columns = [
        _col('x', ColumnType.integer),
        _col('y', ColumnType.real),
      ];

      final result = useCase.suggestAll(columns);

      expect(
          result.map((s) => s.chartType), isNot(contains(ChartType.scatter)));
    });
  });
}

DatasetColumn _col(String name, ColumnType type) => DatasetColumn(
      id: 0,
      datasetTableId: 0,
      originalName: name,
      dbName: name,
      declaredType: type,
      inferredType: type,
      nullable: true,
    );
