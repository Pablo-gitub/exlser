// ignore_for_file: deprecated_member_use_from_same_package

import 'package:exlser/domain/entities/chart_suggestion.dart';
import 'package:exlser/domain/entities/dataset.dart';
import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/entities/dataset_table.dart';
import 'package:exlser/domain/value_objects/aggregation_type.dart';
import 'package:exlser/domain/value_objects/chart_type.dart';
import 'package:exlser/domain/value_objects/column_type.dart';
import 'package:exlser/domain/value_objects/dataset_query_mode.dart';
import 'package:exlser/domain/value_objects/dataset_read_query.dart';
import 'package:exlser/domain/value_objects/filter_operator.dart';
import 'package:exlser/presentation/state/dataset_state.dart';
import 'package:exlser/presentation/state/dataset_workspace_ui_state.dart';
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

  group('DatasetWorkspaceUiState', () {
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

    test('fromJson restores pagination values', () {
      final state = DatasetWorkspaceUiState.fromJson({
        'rowLimit': 250,
        'pageIndex': 3,
      });

      expect(state.rowLimit, 250);
      expect(state.pageIndex, 3);
    });

    test('fromJson falls back for invalid pagination values', () {
      final state = DatasetWorkspaceUiState.fromJson({
        'rowLimit': -1,
        'pageIndex': -2,
      });

      expect(state.rowLimit, DatasetWorkspaceUiState.defaultRowLimit);
      expect(state.pageIndex, 0);
    });

    test('fromJson restores hidden columns and filters unknown columns', () {
      final state = DatasetWorkspaceUiState.fromJson({
        'hiddenColumnDbNames': ['cat', 'missing'],
      });

      expect(state.hiddenColumnDbNames, ['cat', 'missing']);
      expect(
        state.restoreHiddenColumnDbNames([
          _col('cat', ColumnType.text),
          _col('amount', ColumnType.real),
        ]),
        ['cat'],
      );
    });

    test('restoreHiddenColumnDbNames does not hide every column', () {
      const state = DatasetWorkspaceUiState(
        hiddenColumnDbNames: ['cat'],
      );

      expect(state.restoreHiddenColumnDbNames([_col('cat', ColumnType.text)]),
          isEmpty);
    });

    test('toJson includes hidden columns when non-empty', () {
      const state = DatasetWorkspaceUiState(
        hiddenColumnDbNames: ['cat'],
      );

      final json = state.toJson();

      expect(json['hiddenColumnDbNames'], ['cat']);
    });

    test('restores table-specific filters and hidden columns', () {
      final state = DatasetWorkspaceUiState.fromJson({
        'filters': [
          {
            'columnDbName': 'cat',
            'operator': 'contains',
            'value': 'legacy',
          }
        ],
        'tableStates': {
          '2': {
            'hiddenColumnDbNames': ['amount'],
            'filters': [
              {
                'columnDbName': 'cat',
                'operator': 'startsWith',
                'value': 'book',
              }
            ],
          },
        },
      });

      final restoreColumns = [
        _col('cat', ColumnType.text),
        _col('amount', ColumnType.real),
      ];
      final filters = state.restoreFilters(restoreColumns, tableId: 2);

      expect(filters.single.column.dbName, 'cat');
      expect(filters.single.operator, FilterOperator.startsWith);
      expect(filters.single.value, 'book');
      expect(
        state.restoreHiddenColumnDbNames(restoreColumns, tableId: 2),
        ['amount'],
      );
      expect(
        state.restoreFilters(restoreColumns).single.value,
        'legacy',
      );
    });

    test('toJson includes table states when present', () {
      const state = DatasetWorkspaceUiState(
        tableStates: {
          1: StoredTableWorkspaceState(
            hiddenColumnDbNames: ['cat'],
          ),
        },
      );

      final json = state.toJson();

      expect(json['tableStates'], isA<Map<String, dynamic>>());
      expect(json['tableStates']['1']['hiddenColumnDbNames'], ['cat']);
    });

    test('fromJson restores table-specific charts', () {
      final state = DatasetWorkspaceUiState.fromJson({
        'tableStates': {
          '2': {
            'charts': [
              {
                'id': 'chart_2',
                'chartType': 'bar',
                'xColumn': 'cat',
                'aggregation': 'count',
              },
            ],
          },
        },
      });

      final charts = state.restoreCharts(tableId: 2);

      expect(charts.length, 1);
      expect(charts.single.id, 'chart_2');
      expect(state.restoreCharts(tableId: 1), isEmpty);
    });

    test('restoreCharts falls back to legacy top-level charts', () {
      final state = DatasetWorkspaceUiState.fromJson({
        'charts': [
          {
            'id': 'legacy_chart',
            'chartType': 'pie',
            'xColumn': 'cat',
            'aggregation': 'count',
          },
        ],
      });

      expect(state.restoreCharts(tableId: 2).single.id, 'legacy_chart');
    });

    test('round-trips table query state and query charts', () {
      const state = DatasetWorkspaceUiState(
        tableStates: {
          1: StoredTableWorkspaceState(
            queryMode: DatasetQueryMode.sql,
            readOnlyQuery: DatasetReadQuery(
              sql: 'SELECT product FROM sheet',
              limit: 250,
            ),
            queryCharts: [
              StoredAnalyticsChart(
                id: 'query_chart',
                chartTypeName: 'bar',
                xColumnDbName: 'product',
              ),
            ],
          ),
        },
      );

      final restored = DatasetWorkspaceUiState.fromJsonString(
        state.toJsonString(),
      );

      expect(restored.restoreQueryMode(tableId: 1), DatasetQueryMode.sql);
      expect(restored.restoreReadOnlyQuery(tableId: 1).sql,
          'SELECT product FROM sheet');
      expect(restored.restoreReadOnlyQuery(tableId: 1).limit, 250);
      expect(restored.restoreQueryCharts(tableId: 1).single.id, 'query_chart');
    });

    test('fromLoadedState stores analytics charts under active table', () {
      final column = _col('cat', ColumnType.text);
      final state = DatasetWorkspaceUiState.fromLoadedState(
        DatasetLoadedState(
          dataset: _dataset(),
          tables: [_table()],
          activeTable: _table(),
          columns: [column],
          rows: const [],
          viewMode: DatasetViewMode.table,
          rowLimit: 100,
          pageIndex: 0,
          totalRowCount: 0,
          analyticsState: DatasetAnalyticsLoadedState(
            charts: [
              AnalyticsChart(
                id: 'chart_0',
                suggestion: ChartSuggestion(
                  chartType: ChartType.bar,
                  xColumn: column,
                ),
              ),
            ],
          ),
        ),
      );

      final json = state.toJson();
      final tableState = json['tableStates']['1'] as Map<String, dynamic>;

      expect(json.containsKey('charts'), isFalse);
      expect((tableState['charts'] as List).single['id'], 'chart_0');
    });

    test('fromLoadedState stores query analytics separately from table charts',
        () {
      final column = _col('cat', ColumnType.text);
      final state = DatasetWorkspaceUiState.fromLoadedState(
        DatasetLoadedState(
          dataset: _dataset(),
          tables: [_table()],
          activeTable: _table(),
          columns: [column],
          rows: const [],
          viewMode: DatasetViewMode.table,
          rowLimit: 100,
          pageIndex: 0,
          totalRowCount: 0,
          queryMode: DatasetQueryMode.sql,
          readOnlyQuery: const DatasetReadQuery(
            sql: 'SELECT cat FROM sheet',
            limit: 50,
          ),
          analyticsState: DatasetAnalyticsLoadedState(
            charts: [
              AnalyticsChart(
                id: 'query_chart',
                suggestion: ChartSuggestion(
                  chartType: ChartType.bar,
                  xColumn: column,
                ),
              ),
            ],
          ),
        ),
      );

      expect(state.restoreCharts(tableId: 1), isEmpty);
      expect(state.restoreQueryCharts(tableId: 1).single.id, 'query_chart');
      expect(state.restoreReadOnlyQuery(tableId: 1).limit, 50);
    });

    test('fromLoadedState preserves previous table charts when analytics idle',
        () {
      final previous = DatasetWorkspaceUiState(
        tableStates: {
          1: const StoredTableWorkspaceState(
            charts: [
              StoredAnalyticsChart(
                id: 'previous_chart',
                chartTypeName: 'bar',
                xColumnDbName: 'cat',
              ),
            ],
          ),
        },
      );
      final state = DatasetWorkspaceUiState.fromLoadedState(
        DatasetLoadedState(
          dataset: _dataset(uiStateJson: previous.toJsonString()),
          tables: [_table()],
          activeTable: _table(),
          columns: [_col('cat', ColumnType.text)],
          rows: const [],
          viewMode: DatasetViewMode.table,
          rowLimit: 100,
          pageIndex: 0,
          totalRowCount: 0,
        ),
      );

      expect(state.restoreCharts(tableId: 1).single.id, 'previous_chart');
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

  group('StoredTableWorkspaceState.columnCurrencySymbols', () {
    test('toJson / fromJson round-trips correctly', () {
      const state = StoredTableWorkspaceState(
        columnCurrencySymbols: {'price': r'$', 'salary': '€'},
      );

      final json = state.toJson();
      final restored = StoredTableWorkspaceState.fromJson(json);

      expect(restored.columnCurrencySymbols, {r'price': r'$', 'salary': '€'});
    });

    test('toJson omits key when map is empty', () {
      const state = StoredTableWorkspaceState();
      final json = state.toJson();
      expect(json.containsKey('columnCurrencySymbols'), isFalse);
    });

    test('fromJson returns empty map when key is absent', () {
      final json = <String, dynamic>{};
      final state = StoredTableWorkspaceState.fromJson(json);
      expect(state.columnCurrencySymbols, isEmpty);
    });

    test('restoreColumnCurrencySymbols returns symbols for the active table',
        () {
      final uiState = DatasetWorkspaceUiState(
        tableStates: {
          7: const StoredTableWorkspaceState(
            columnCurrencySymbols: {'amount': '£'},
          ),
        },
      );

      expect(
        uiState.restoreColumnCurrencySymbols(tableId: 7),
        {'amount': '£'},
      );
    });

    test('restoreColumnCurrencySymbols returns empty map for unknown table',
        () {
      const uiState = DatasetWorkspaceUiState();
      expect(uiState.restoreColumnCurrencySymbols(tableId: 99), isEmpty);
    });

    test(
        'fromLoadedState preserves columnCurrencySymbols from previous state',
        () {
      final previous = const StoredTableWorkspaceState(
        columnCurrencySymbols: {'revenue': '¥'},
      );

      final state = DatasetWorkspaceUiState.fromJsonString(null);
      expect(state.tableStates, isEmpty);

      final restoredFromPrevious = StoredTableWorkspaceState.fromLoadedState(
        _minimalLoadedState(),
        previousState: previous,
      );

      expect(restoredFromPrevious.columnCurrencySymbols, {'revenue': '¥'});
    });
  });
}

Dataset _dataset({String? uiStateJson}) => Dataset(
      id: 1,
      name: 'Dataset',
      sourceFileName: 'source.csv',
      createdAt: 1,
      lastOpenedAt: 1,
      uiStateJson: uiStateJson,
    );

DatasetTable _table() => const DatasetTable(
      id: 1,
      datasetId: 1,
      sheetNameOriginal: 'Sheet1',
      sqlTableName: 'sheet1',
      rowCount: 0,
      colCount: 1,
    );

DatasetColumn _col(String name, ColumnType type) => DatasetColumn(
      id: 0,
      datasetTableId: 0,
      originalName: name,
      dbName: name,
      declaredType: type,
      inferredType: type,
      nullable: true,
    );

DatasetLoadedState _minimalLoadedState() => DatasetLoadedState(
      dataset: _dataset(),
      tables: [_table()],
      activeTable: _table(),
      columns: const [],
      rows: const [],
      viewMode: DatasetViewMode.table,
      rowLimit: 100,
      pageIndex: 0,
      totalRowCount: 0,
    );
