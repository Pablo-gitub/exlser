import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/value_objects/aggregation_type.dart';
import 'package:exel_category/domain/value_objects/chart_type.dart';
import 'package:exel_category/domain/value_objects/column_type.dart';
import 'package:exel_category/presentation/state/dataset_workspace_ui_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StoredAnalyticsChart', () {
    final columns = [
      _col('category', ColumnType.text),
      _col('amount', ColumnType.real),
      _col('date', ColumnType.date),
    ];

    test('toJson / fromJson round-trips correctly', () {
      const stored = StoredAnalyticsChart(
        id: 'chart_0',
        chartTypeName: 'bar',
        xColumnDbName: 'category',
        yColumnDbName: 'amount',
        aggregationTypeName: 'sum',
      );

      final json = stored.toJson();
      final restored = StoredAnalyticsChart.fromJson(json);

      expect(restored.id, 'chart_0');
      expect(restored.chartTypeName, 'bar');
      expect(restored.xColumnDbName, 'category');
      expect(restored.yColumnDbName, 'amount');
      expect(restored.aggregationTypeName, 'sum');
    });

    test('toJson omits null y column', () {
      const stored = StoredAnalyticsChart(
        id: 'chart_1',
        chartTypeName: 'pie',
        xColumnDbName: 'category',
      );

      final json = stored.toJson();

      expect(json.containsKey('yColumn'), isFalse);
    });

    test('toChartSuggestion returns correct suggestion', () {
      const stored = StoredAnalyticsChart(
        id: 'chart_0',
        chartTypeName: 'bar',
        xColumnDbName: 'category',
        yColumnDbName: 'amount',
        aggregationTypeName: 'sum',
      );

      final suggestion = stored.toChartSuggestion(columns);

      expect(suggestion, isNotNull);
      expect(suggestion!.chartType, ChartType.bar);
      expect(suggestion.xColumn?.dbName, 'category');
      expect(suggestion.yColumn?.dbName, 'amount');
      expect(suggestion.aggregationType, AggregationType.sum);
    });

    test('toChartSuggestion returns null when xColumn not found in columns',
        () {
      const stored = StoredAnalyticsChart(
        id: 'chart_0',
        chartTypeName: 'bar',
        xColumnDbName: 'nonexistent',
      );

      expect(stored.toChartSuggestion(columns), isNull);
    });

    test('toChartSuggestion returns null for unknown chart type', () {
      const stored = StoredAnalyticsChart(
        id: 'chart_0',
        chartTypeName: 'radar',
        xColumnDbName: 'category',
      );

      expect(stored.toChartSuggestion(columns), isNull);
    });

    test('toChartSuggestion returns null for unsupported chart type', () {
      const stored = StoredAnalyticsChart(
        id: 'chart_0',
        chartTypeName: 'scatter',
        xColumnDbName: 'amount',
        yColumnDbName: 'amount',
      );

      expect(stored.toChartSuggestion(columns), isNull);
    });

    test('toChartSuggestion sets null yColumn when yColumnDbName missing', () {
      const stored = StoredAnalyticsChart(
        id: 'chart_0',
        chartTypeName: 'pie',
        xColumnDbName: 'category',
      );

      final suggestion = stored.toChartSuggestion(columns);

      expect(suggestion, isNotNull);
      expect(suggestion!.yColumn, isNull);
    });

    test('fromJson handles missing optional fields gracefully', () {
      final stored = StoredAnalyticsChart.fromJson({
        'id': 'chart_2',
        'chartType': 'line',
        'xColumn': 'date',
      });

      expect(stored.yColumnDbName, isNull);
      expect(stored.aggregationTypeName, 'count');
    });
  });

  group('DatasetWorkspaceUiState.charts', () {
    final columns = [_col('cat', ColumnType.text)];

    test('fromJson restores charts list', () {
      final state = DatasetWorkspaceUiState.fromJson({
        'charts': [
          {
            'id': 'chart_0',
            'chartType': 'bar',
            'xColumn': 'cat',
            'aggregation': 'count',
          },
        ],
      });

      expect(state.charts.length, 1);
      expect(state.charts.first.id, 'chart_0');
    });

    test('toJson includes charts when non-empty', () {
      const state = DatasetWorkspaceUiState(
        charts: [
          StoredAnalyticsChart(
            id: 'chart_0',
            chartTypeName: 'bar',
            xColumnDbName: 'cat',
          ),
        ],
      );

      final json = state.toJson();

      expect(json.containsKey('charts'), isTrue);
      expect((json['charts'] as List).length, 1);
    });

    test('toJson omits charts key when empty', () {
      const state = DatasetWorkspaceUiState();

      final json = state.toJson();

      expect(json.containsKey('charts'), isFalse);
    });

    test('fromJson with missing charts returns empty list', () {
      final state = DatasetWorkspaceUiState.fromJson({'viewMode': 'table'});

      expect(state.charts, isEmpty);
    });

    test('chart round-trip through JSON preserves suggestion', () {
      const state = DatasetWorkspaceUiState(
        charts: [
          StoredAnalyticsChart(
            id: 'chart_0',
            chartTypeName: 'pie',
            xColumnDbName: 'cat',
            aggregationTypeName: 'count',
          ),
        ],
      );

      final restored = DatasetWorkspaceUiState.fromJsonString(
        state.toJsonString(),
      );

      final suggestion = restored.charts.first.toChartSuggestion(columns);
      expect(suggestion?.chartType, ChartType.pie);
      expect(suggestion?.xColumn?.dbName, 'cat');
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
