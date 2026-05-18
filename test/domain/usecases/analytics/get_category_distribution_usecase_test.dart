import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/repositories/query_repository.dart';
import 'package:exel_category/domain/usecases/analytics/get_category_distribution_usecase.dart';
import 'package:exel_category/domain/value_objects/aggregation_type.dart';
import 'package:exel_category/domain/value_objects/chart_type.dart';
import 'package:exel_category/domain/value_objects/column_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockQueryRepository extends Mock implements QueryRepository {}

void main() {
  late MockQueryRepository repository;
  late GetCategoryDistributionUseCase useCase;

  setUp(() {
    repository = MockQueryRepository();
    useCase = GetCategoryDistributionUseCase(repository: repository);
  });

  group('GetCategoryDistributionUseCase', () {
    test('returns pie chart data for ≤8 categories', () async {
      final column = _col('category', ColumnType.text);
      when(() => repository.executeRawQuery(any(), any())).thenAnswer(
        (_) async => [
          {'label': 'A', 'value': 10.0},
          {'label': 'B', 'value': 5.0},
        ],
      );

      final result = await useCase(tableName: 'tbl', xColumn: column);

      expect(result.chartType, ChartType.pie);
      expect(result.points.length, 2);
      expect(result.points.first.label, 'A');
      expect(result.points.first.value, 10.0);
    });

    test('returns bar chart data for >8 categories', () async {
      final column = _col('country', ColumnType.text);
      when(() => repository.executeRawQuery(any(), any())).thenAnswer(
        (_) async => List.generate(
          9,
          (i) => {'label': 'Country$i', 'value': (i + 1).toDouble()},
        ),
      );

      final result = await useCase(tableName: 'tbl', xColumn: column);

      expect(result.chartType, ChartType.bar);
    });

    test('filters out null labels', () async {
      final column = _col('status', ColumnType.text);
      when(() => repository.executeRawQuery(any(), any())).thenAnswer(
        (_) async => [
          {'label': 'active', 'value': 8.0},
          {'label': null, 'value': 3.0},
        ],
      );

      final result = await useCase(tableName: 'tbl', xColumn: column);

      expect(result.points.length, 1);
      expect(result.points.first.label, 'active');
    });

    test('formats boolean labels (1 → True, 0 → False)', () async {
      final column = _col('active', ColumnType.boolean);
      when(() => repository.executeRawQuery(any(), any())).thenAnswer(
        (_) async => [
          {'label': 1, 'value': 7.0},
          {'label': 0, 'value': 3.0},
        ],
      );

      final result = await useCase(tableName: 'tbl', xColumn: column);

      expect(result.points.first.label, 'True');
      expect(result.points.last.label, 'False');
    });

    test('uses COUNT(*) when no yColumn provided', () async {
      final column = _col('category', ColumnType.text);
      when(() => repository.executeRawQuery(any(), any()))
          .thenAnswer((_) async => []);

      await useCase(tableName: 'tbl', xColumn: column);

      final captured =
          verify(() => repository.executeRawQuery(captureAny(), any()))
              .captured;
      expect(captured[0], contains('COUNT(*)'));
    });

    test('uses aggregation function when yColumn provided', () async {
      final xCol = _col('category', ColumnType.text);
      final yCol = _col('amount', ColumnType.real);
      when(() => repository.executeRawQuery(any(), any()))
          .thenAnswer((_) async => []);

      await useCase(
        tableName: 'tbl',
        xColumn: xCol,
        yColumn: yCol,
        aggregationType: AggregationType.sum,
      );

      final captured =
          verify(() => repository.executeRawQuery(captureAny(), any()))
              .captured;
      expect(captured[0], contains('SUM'));
      expect(captured[0], contains('amount'));
    });

    test('passes WHERE clause to query', () async {
      final column = _col('category', ColumnType.text);
      when(() => repository.executeRawQuery(any(), any()))
          .thenAnswer((_) async => []);

      await useCase(
        tableName: 'tbl',
        xColumn: column,
        whereClause: 'status = ?',
        whereArguments: ['active'],
      );

      final captured =
          verify(() => repository.executeRawQuery(captureAny(), captureAny()))
              .captured;
      expect(captured[0], contains('WHERE status = ?'));
      expect(captured[1], ['active']);
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
