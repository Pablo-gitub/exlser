import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/repositories/query_repository.dart';
import 'package:exel_category/domain/usecases/query/apply_filters_usecase.dart';
import 'package:exel_category/domain/value_objects/column_type.dart';
import 'package:exel_category/domain/value_objects/dataset_filter.dart';
import 'package:exel_category/domain/value_objects/dataset_sort.dart';
import 'package:exel_category/domain/value_objects/filter_operator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockQueryRepository extends Mock implements QueryRepository {}

void main() {
  group('ApplyFiltersUseCase', () {
    late MockQueryRepository repository;
    late ApplyFiltersUseCase useCase;

    setUp(() {
      repository = MockQueryRepository();
      useCase = ApplyFiltersUseCase(repository: repository);
    });

    test('should fetch rows when no filters or sorting are provided', () async {
      final expectedRows = [
        {'product': 'book'},
      ];
      when(() => repository.fetchRows(
            tableName: any(named: 'tableName'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          )).thenAnswer((_) async => expectedRows);

      final result = await useCase(
        tableName: 'products',
        limit: 20,
        offset: 0,
      );

      expect(result, expectedRows);
      verify(() => repository.fetchRows(
            tableName: 'products',
            limit: 20,
            offset: 0,
          )).called(1);
    });

    test('should build composed text and numeric filters', () async {
      when(() => repository.queryWithFilter(
            tableName: any(named: 'tableName'),
            whereClause: any(named: 'whereClause'),
            arguments: any(named: 'arguments'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          )).thenAnswer((_) async => []);

      await useCase(
        tableName: 'products',
        filters: [
          DatasetFilter(
            column: _column(
              dbName: 'product',
              type: ColumnType.text,
            ),
            operator: FilterOperator.contains,
            value: 'book',
          ),
          DatasetFilter(
            column: _column(
              dbName: 'price',
              type: ColumnType.integer,
            ),
            operator: FilterOperator.between,
            value: 10,
            secondValue: 20,
          ),
        ],
        limit: 50,
      );

      final captured = verify(() => repository.queryWithFilter(
            tableName: 'products',
            whereClause: captureAny(named: 'whereClause'),
            arguments: captureAny(named: 'arguments'),
            limit: 50,
            offset: null,
          )).captured;

      expect(
        captured[0],
        "(product LIKE ? ESCAPE '\\') AND (price BETWEEN ? AND ?)",
      );
      expect(captured[1], ['%book%', 10, 20]);
    });

    test('should combine filters and sorting', () async {
      when(() => repository.queryWithFilterAndOrder(
            tableName: any(named: 'tableName'),
            whereClause: any(named: 'whereClause'),
            orderBy: any(named: 'orderBy'),
            arguments: any(named: 'arguments'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          )).thenAnswer((_) async => []);

      final priceColumn = _column(
        dbName: 'price',
        type: ColumnType.real,
      );

      await useCase(
        tableName: 'products',
        filters: [
          DatasetFilter(
            column: priceColumn,
            operator: FilterOperator.greaterThan,
            value: 5.5,
          ),
        ],
        sort: DatasetSort(
          column: priceColumn,
          direction: SortDirection.descending,
        ),
      );

      final captured = verify(() => repository.queryWithFilterAndOrder(
            tableName: 'products',
            whereClause: captureAny(named: 'whereClause'),
            orderBy: captureAny(named: 'orderBy'),
            arguments: captureAny(named: 'arguments'),
            limit: null,
            offset: null,
          )).captured;

      expect(captured[0], '(price > ?)');
      expect(captured[1], 'price DESC');
      expect(captured[2], [5.5]);
    });

    test('should execute sorted raw query when sorting without filters',
        () async {
      when(() => repository.executeRawQuery(any(), any()))
          .thenAnswer((_) async => []);

      await useCase(
        tableName: 'products',
        sort: DatasetSort(
          column: _column(
            dbName: 'price',
            type: ColumnType.integer,
          ),
          direction: SortDirection.ascending,
        ),
        limit: 10,
        offset: 5,
      );

      verify(() => repository.executeRawQuery(
            'SELECT * FROM products ORDER BY price ASC LIMIT 10 OFFSET 5',
            null,
          )).called(1);
    });

    test('should normalize boolean filters', () async {
      when(() => repository.queryWithFilter(
            tableName: any(named: 'tableName'),
            whereClause: any(named: 'whereClause'),
            arguments: any(named: 'arguments'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          )).thenAnswer((_) async => []);

      await useCase(
        tableName: 'products',
        filters: [
          DatasetFilter(
            column: _column(
              dbName: 'available',
              type: ColumnType.boolean,
            ),
            operator: FilterOperator.equals,
            value: true,
          ),
        ],
      );

      final captured = verify(() => repository.queryWithFilter(
            tableName: 'products',
            whereClause: captureAny(named: 'whereClause'),
            arguments: captureAny(named: 'arguments'),
            limit: null,
            offset: null,
          )).captured;

      expect(captured[0], '(available = ?)');
      expect(captured[1], [1]);
    });

    test('should reject operators not supported by column type', () async {
      await expectLater(
        useCase(
          tableName: 'products',
          filters: [
            DatasetFilter(
              column: _column(
                dbName: 'price',
                type: ColumnType.integer,
              ),
              operator: FilterOperator.contains,
              value: '10',
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('should reject missing values for value-based operators', () async {
      await expectLater(
        useCase(
          tableName: 'products',
          filters: [
            DatasetFilter(
              column: _column(
                dbName: 'product',
                type: ColumnType.text,
              ),
              operator: FilterOperator.contains,
              value: ' ',
            ),
          ],
        ),
        throwsArgumentError,
      );
    });
  });
}

DatasetColumn _column({
  required String dbName,
  required ColumnType type,
}) {
  return DatasetColumn(
    id: 0,
    datasetTableId: 0,
    originalName: dbName,
    dbName: dbName,
    declaredType: type,
    inferredType: type,
    nullable: true,
  );
}
