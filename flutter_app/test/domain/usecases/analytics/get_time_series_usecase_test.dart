import 'package:exlser/application/dto/chart_data.dart';
import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/repositories/query_repository.dart';
import 'package:exlser/domain/usecases/analytics/get_time_series_usecase.dart';
import 'package:exlser/domain/value_objects/aggregation_type.dart';
import 'package:exlser/domain/value_objects/chart_type.dart';
import 'package:exlser/domain/value_objects/column_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockQueryRepository extends Mock implements QueryRepository {}

void main() {
  late MockQueryRepository repository;
  late GetTimeSeriesUseCase useCase;

  setUp(() {
    repository = MockQueryRepository();
    useCase = GetTimeSeriesUseCase(repository: repository);
  });

  group('GetTimeSeriesUseCase', () {
    test('returns parsed time series points', () async {
      final xCol = _col('date', ColumnType.date);
      final yCol = _col('sales', ColumnType.real);
      when(() => repository.executeRawQuery(any(), any())).thenAnswer(
        (_) async => [
          {'x_val': '2024-01-01', 'y_val': 100.0},
          {'x_val': '2024-02-01', 'y_val': 200.0},
        ],
      );

      final result = await useCase(
        tableName: 'orders',
        xColumn: xCol,
        yColumn: yCol,
      );

      expect(result, isA<TimeSeriesChartData>());
      expect(result.points.length, 2);
      expect(result.points.first.x, DateTime(2024, 1, 1));
      expect(result.points.first.y, 100.0);
      expect(result.points.last.x, DateTime(2024, 2, 1));
    });

    test('skips rows with null x_val', () async {
      final xCol = _col('date', ColumnType.date);
      final yCol = _col('sales', ColumnType.real);
      when(() => repository.executeRawQuery(any(), any())).thenAnswer(
        (_) async => [
          {'x_val': null, 'y_val': 50.0},
          {'x_val': '2024-03-01', 'y_val': 75.0},
        ],
      );

      final result = await useCase(
        tableName: 'orders',
        xColumn: xCol,
        yColumn: yCol,
      );

      expect(result.points.length, 1);
      expect(result.points.first.x, DateTime(2024, 3, 1));
    });

    test('skips rows with unparseable dates', () async {
      final xCol = _col('date', ColumnType.date);
      final yCol = _col('sales', ColumnType.real);
      when(() => repository.executeRawQuery(any(), any())).thenAnswer(
        (_) async => [
          {'x_val': 'not-a-date', 'y_val': 50.0},
          {'x_val': '2024-04-01', 'y_val': 30.0},
        ],
      );

      final result = await useCase(
        tableName: 'orders',
        xColumn: xCol,
        yColumn: yCol,
      );

      expect(result.points.length, 1);
    });

    test('uses 0.0 for null y_val', () async {
      final xCol = _col('date', ColumnType.date);
      final yCol = _col('sales', ColumnType.real);
      when(() => repository.executeRawQuery(any(), any())).thenAnswer(
        (_) async => [
          {'x_val': '2024-05-01', 'y_val': null},
        ],
      );

      final result = await useCase(
        tableName: 'orders',
        xColumn: xCol,
        yColumn: yCol,
      );

      expect(result.points.first.y, 0.0);
    });

    test('includes aggregation function in yLabel', () async {
      final xCol = _col('date', ColumnType.date);
      final yCol = _col('revenue', ColumnType.real);
      when(() => repository.executeRawQuery(any(), any()))
          .thenAnswer((_) async => []);

      final result = await useCase(
        tableName: 'orders',
        xColumn: xCol,
        yColumn: yCol,
        aggregationType: AggregationType.avg,
      );

      expect(result.yLabel, contains('AVG'));
      expect(result.yLabel, contains('revenue'));
    });

    test('passes WHERE clause to repository', () async {
      final xCol = _col('date', ColumnType.date);
      final yCol = _col('sales', ColumnType.real);
      when(() => repository.executeRawQuery(any(), any()))
          .thenAnswer((_) async => []);

      await useCase(
        tableName: 'orders',
        xColumn: xCol,
        yColumn: yCol,
        whereClause: 'region = ?',
        whereArguments: ['north'],
      );

      final captured =
          verify(() => repository.executeRawQuery(captureAny(), captureAny()))
              .captured;
      expect(captured[0], contains('WHERE region = ?'));
      expect(captured[1], ['north']);
    });

    test('returns empty chart type as line', () async {
      final xCol = _col('date', ColumnType.date);
      final yCol = _col('sales', ColumnType.real);
      when(() => repository.executeRawQuery(any(), any()))
          .thenAnswer((_) async => []);

      final result = await useCase(
        tableName: 'orders',
        xColumn: xCol,
        yColumn: yCol,
      );

      expect(result.chartType, ChartType.line);
    });

    test('parses DD/MM/YYYY date format (common spreadsheet export)', () async {
      final xCol = _col('date', ColumnType.date);
      final yCol = _col('sales', ColumnType.real);
      when(() => repository.executeRawQuery(any(), any())).thenAnswer(
        (_) async => [
          {'x_val': '15/10/2017', 'y_val': 100.0},
          {'x_val': '16/08/2016', 'y_val': 200.0},
          {'x_val': '21/05/2015', 'y_val': 300.0},
        ],
      );

      final result = await useCase(
        tableName: 'people',
        xColumn: xCol,
        yColumn: yCol,
      );

      expect(result.points.length, 3);
      expect(result.points[0].x, DateTime(2015, 5, 21));
      expect(result.points[1].x, DateTime(2016, 8, 16));
      expect(result.points[2].x, DateTime(2017, 10, 15));
    });

    test('skips rows with unrecognised date formats', () async {
      final xCol = _col('date', ColumnType.date);
      final yCol = _col('sales', ColumnType.real);
      when(() => repository.executeRawQuery(any(), any())).thenAnswer(
        (_) async => [
          {'x_val': 'not-a-date', 'y_val': 50.0},
          {'x_val': '15/10/2017', 'y_val': 75.0},
          {'x_val': '2024-06-01', 'y_val': 90.0},
        ],
      );

      final result = await useCase(
        tableName: 'people',
        xColumn: xCol,
        yColumn: yCol,
      );

      expect(result.points.length, 2);
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
