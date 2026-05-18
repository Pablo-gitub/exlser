import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/repositories/query_repository.dart';
import 'package:exel_category/domain/usecases/analytics/get_column_statistics_usecase.dart';
import 'package:exel_category/domain/value_objects/column_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockQueryRepository extends Mock implements QueryRepository {}

void main() {
  late MockQueryRepository repository;
  late GetColumnStatisticsUseCase useCase;

  setUp(() {
    repository = MockQueryRepository();
    useCase = GetColumnStatisticsUseCase(repository: repository);
  });

  group('GetColumnStatisticsUseCase', () {
    test('returns statistics from query result', () async {
      final column = _col('price', ColumnType.real);
      when(() => repository.executeRawQuery(any(), any())).thenAnswer(
        (_) async => [
          {
            'total_count': 10,
            'non_null_count': 8,
            'distinct_count': 5,
            'min_val': 1.5,
            'max_val': 99.9,
            'avg_val': 42.0,
            'sum_val': 336.0,
          }
        ],
      );

      final stats = await useCase(tableName: 'my_table', column: column);

      expect(stats.totalRows, 10);
      expect(stats.nullCount, 2);
      expect(stats.nonNullCount, 8);
      expect(stats.distinctCount, 5);
      expect(stats.min, 1.5);
      expect(stats.max, 99.9);
      expect(stats.avg, 42.0);
      expect(stats.sum, 336.0);
      expect(stats.hasNumericStats, isTrue);
    });

    test('returns zero-stats when result is empty', () async {
      final column = _col('name', ColumnType.text);
      when(() => repository.executeRawQuery(any(), any()))
          .thenAnswer((_) async => []);

      final stats = await useCase(tableName: 'my_table', column: column);

      expect(stats.totalRows, 0);
      expect(stats.nullCount, 0);
      expect(stats.distinctCount, 0);
      expect(stats.min, isNull);
      expect(stats.max, isNull);
    });

    test('passes whereClause and arguments to repository', () async {
      final column = _col('price', ColumnType.real);
      when(() => repository.executeRawQuery(any(), any()))
          .thenAnswer((_) async => [
                {
                  'total_count': 3,
                  'non_null_count': 3,
                  'distinct_count': 3,
                  'min_val': 5.0,
                  'max_val': 20.0,
                  'avg_val': 10.0,
                  'sum_val': 30.0,
                }
              ]);

      await useCase(
        tableName: 'my_table',
        column: column,
        whereClause: 'category = ?',
        whereArguments: ['books'],
      );

      final captured =
          verify(() => repository.executeRawQuery(captureAny(), captureAny()))
              .captured;

      expect(captured[0], contains('WHERE category = ?'));
      expect(captured[1], ['books']);
    });

    test('omits WHERE when whereClause is null', () async {
      final column = _col('price', ColumnType.real);
      when(() => repository.executeRawQuery(any(), any()))
          .thenAnswer((_) async => [
                {
                  'total_count': 5,
                  'non_null_count': 5,
                  'distinct_count': 2,
                  'min_val': null,
                  'max_val': null,
                  'avg_val': null,
                  'sum_val': null,
                }
              ]);

      await useCase(tableName: 'my_table', column: column);

      final captured =
          verify(() => repository.executeRawQuery(captureAny(), any()))
              .captured;

      expect(captured[0], isNot(contains('WHERE')));
    });

    test('does not cast non-numeric columns to numeric statistics', () async {
      final column = _col('brand', ColumnType.text);
      when(() => repository.executeRawQuery(any(), any()))
          .thenAnswer((_) async => [
                {
                  'total_count': 4,
                  'non_null_count': 3,
                  'distinct_count': 2,
                }
              ]);

      final stats = await useCase(tableName: 'my_table', column: column);

      final captured =
          verify(() => repository.executeRawQuery(captureAny(), any()))
              .captured;

      expect(captured[0], isNot(contains('CAST')));
      expect(stats.totalRows, 4);
      expect(stats.nullCount, 1);
      expect(stats.distinctCount, 2);
      expect(stats.min, isNull);
      expect(stats.max, isNull);
      expect(stats.avg, isNull);
      expect(stats.sum, isNull);
      expect(stats.hasNumericStats, isFalse);
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
