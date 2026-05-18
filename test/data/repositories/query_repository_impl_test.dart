import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/value_objects/column_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:exel_category/data/repositories/query_repository_impl.dart';
import 'package:exel_category/data/datasources/drift_datasource.dart';

class MockDatasource extends Mock implements DriftDatasource {}

void main() {
  late QueryRepositoryImpl repository;
  late MockDatasource datasource;

  setUp(() {
    datasource = MockDatasource();
    repository = QueryRepositoryImpl(datasource);
  });

  group('insertBatch', () {
    test('should insert rows correctly', () async {
      final rows = [
        {'a': 1, 'b': 2},
        {'a': 3, 'b': 4},
      ];

      when(() => datasource.runInTransaction(any()))
          .thenAnswer((invocation) async {
        final callback =
            invocation.positionalArguments.first as Future<void> Function();
        await callback();
      });

      when(() => datasource.executeWithArgs(any(), any()))
          .thenAnswer((_) async {});

      await repository.insertBatch(
        tableName: 'test_table',
        rows: rows,
      );

      verify(() => datasource.runInTransaction(any())).called(1);

      verify(() => datasource.executeWithArgs(any(), any()))
          .called(rows.length);
    });

    test('should not insert when rows are empty', () async {
      await repository.insertBatch(
        tableName: 'test_table',
        rows: [],
      );

      verifyNever(() => datasource.runInTransaction(any()));
    });

    test('should throw when table name is empty', () async {
      expect(
        () => repository.insertBatch(
          tableName: '',
          rows: [
            {'a': 1}
          ],
        ),
        throwsException,
      );
    });

    test('should throw when rows structure is inconsistent', () async {
      final rows = [
        {'a': 1, 'b': 2},
        {'a': 3}, // ❌ missing column
      ];

      expect(
        () => repository.insertBatch(
          tableName: 'test_table',
          rows: rows,
        ),
        throwsException,
      );
    });
  });

  group('fetchRows', () {
    test('should fetch rows without pagination', () async {
      final expectedRows = [
        {'id': 1, 'name': 'book'},
        {'id': 2, 'name': 'pen'},
      ];

      when(() => datasource.query(any())).thenAnswer((_) async => expectedRows);

      final result = await repository.fetchRows(
        tableName: 'products',
      );

      expect(result, expectedRows);

      verify(() => datasource.query(
            'SELECT * FROM products',
          )).called(1);
    });

    test('should apply limit correctly', () async {
      when(() => datasource.query(any())).thenAnswer((_) async => []);

      await repository.fetchRows(
        tableName: 'products',
        limit: 10,
      );

      verify(() => datasource.query(
            'SELECT * FROM products LIMIT 10',
          )).called(1);
    });

    test('should apply offset correctly', () async {
      when(() => datasource.query(any())).thenAnswer((_) async => []);

      await repository.fetchRows(
        tableName: 'products',
        offset: 5,
      );

      verify(() => datasource.query(
            'SELECT * FROM products OFFSET 5',
          )).called(1);
    });

    test('should apply limit and offset together', () async {
      when(() => datasource.query(any())).thenAnswer((_) async => []);

      await repository.fetchRows(
        tableName: 'products',
        limit: 10,
        offset: 5,
      );

      verify(() => datasource.query(
            'SELECT * FROM products LIMIT 10 OFFSET 5',
          )).called(1);
    });

    test('should throw when table name is empty', () async {
      expect(
        () => repository.fetchRows(tableName: ''),
        throwsException,
      );
    });

    test('should propagate datasource errors', () async {
      when(() => datasource.query(any())).thenThrow(Exception('DB error'));

      expect(
        () => repository.fetchRows(tableName: 'products'),
        throwsException,
      );
    });
  });

  group('queryWithFilter', () {
    test('should fetch rows with where clause', () async {
      /// ARRANGE

      final expectedRows = [
        {'id': 1, 'price': 10},
      ];

      when(() => datasource.query(
            any(),
            arguments: any(named: 'arguments'),
          )).thenAnswer((_) async => expectedRows);

      /// ACT

      final result = await repository.queryWithFilter(
        tableName: 'products',
        whereClause: 'price > ?',
        arguments: [5],
      );

      /// ASSERT

      expect(result, expectedRows);

      verify(() => datasource.query(
            'SELECT * FROM products WHERE price > ?',
            arguments: [5],
          )).called(1);
    });

    test('should apply limit correctly', () async {
      when(() => datasource.query(
            any(),
            arguments: any(named: 'arguments'),
          )).thenAnswer((_) async => []);

      await repository.queryWithFilter(
        tableName: 'products',
        whereClause: 'price > ?',
        arguments: [5],
        limit: 10,
      );

      verify(() => datasource.query(
            'SELECT * FROM products WHERE price > ? LIMIT 10',
            arguments: [5],
          )).called(1);
    });

    test('should apply offset correctly', () async {
      when(() => datasource.query(
            any(),
            arguments: any(named: 'arguments'),
          )).thenAnswer((_) async => []);

      await repository.queryWithFilter(
        tableName: 'products',
        whereClause: 'price > ?',
        arguments: [5],
        offset: 5,
      );

      verify(() => datasource.query(
            'SELECT * FROM products WHERE price > ? OFFSET 5',
            arguments: [5],
          )).called(1);
    });

    test('should apply limit and offset together', () async {
      when(() => datasource.query(
            any(),
            arguments: any(named: 'arguments'),
          )).thenAnswer((_) async => []);

      await repository.queryWithFilter(
        tableName: 'products',
        whereClause: 'price > ?',
        arguments: [5],
        limit: 10,
        offset: 5,
      );

      verify(() => datasource.query(
            'SELECT * FROM products WHERE price > ? LIMIT 10 OFFSET 5',
            arguments: [5],
          )).called(1);
    });

    test('should throw when table name is empty', () async {
      expect(
        () => repository.queryWithFilter(
          tableName: '',
          whereClause: 'price > ?',
        ),
        throwsException,
      );
    });

    test('should throw when where clause is empty', () async {
      expect(
        () => repository.queryWithFilter(
          tableName: 'products',
          whereClause: '',
        ),
        throwsException,
      );
    });

    test('should propagate datasource errors', () async {
      when(() => datasource.query(
            any(),
            arguments: any(named: 'arguments'),
          )).thenThrow(Exception('DB error'));

      expect(
        () => repository.queryWithFilter(
          tableName: 'products',
          whereClause: 'price > ?',
        ),
        throwsException,
      );
    });
  });

  group('queryWithFilterAndOrder', () {
    test('should fetch rows with filter and order', () async {
      final expectedRows = [
        {'price': 20},
        {'price': 10},
      ];

      when(() => datasource.query(
            any(),
            arguments: any(named: 'arguments'),
          )).thenAnswer((_) async => expectedRows);

      final result = await repository.queryWithFilterAndOrder(
        tableName: 'products',
        whereClause: 'price > ?',
        orderBy: 'price DESC',
        arguments: [5],
      );

      expect(result, expectedRows);

      verify(() => datasource.query(
            'SELECT * FROM products WHERE price > ? ORDER BY price DESC',
            arguments: [5],
          )).called(1);
    });

    test('should apply limit and offset', () async {
      when(() => datasource.query(
            any(),
            arguments: any(named: 'arguments'),
          )).thenAnswer((_) async => []);

      await repository.queryWithFilterAndOrder(
        tableName: 'products',
        whereClause: 'price > ?',
        orderBy: 'price ASC',
        arguments: [5],
        limit: 10,
        offset: 5,
      );

      verify(() => datasource.query(
            'SELECT * FROM products WHERE price > ? ORDER BY price ASC LIMIT 10 OFFSET 5',
            arguments: [5],
          )).called(1);
    });

    test('should throw when orderBy is empty', () async {
      expect(
        () => repository.queryWithFilterAndOrder(
          tableName: 'products',
          whereClause: 'price > ?',
          orderBy: '',
        ),
        throwsException,
      );
    });
  });

  group('countRows', () {
    test('should return correct row count', () async {
      /// ---------------- ARRANGE ----------------
      ///
      /// Simulate database returning COUNT(*) result

      when(() => datasource.query(
            any(),
            arguments: any(named: 'arguments'),
          )).thenAnswer((_) async => [
            {'count': 5},
          ]);

      /// ---------------- ACT ----------------

      final result = await repository.countRows('products');

      /// ---------------- ASSERT ----------------

      expect(result, 5);

      verify(() => datasource.query(
            'SELECT COUNT(*) as count FROM products',
            arguments: null,
          )).called(1);
    });

    test('should throw when table name is empty', () async {
      expect(
        () => repository.countRows(''),
        throwsException,
      );
    });

    test('should return 0 when no rows found', () async {
      when(() => datasource.query(
            any(),
            arguments: any(named: 'arguments'),
          )).thenAnswer((_) async => []);

      final result = await repository.countRows('products');

      expect(result, 0);
    });

    test('should propagate datasource errors', () async {
      when(() => datasource.query(
            any(),
            arguments: any(named: 'arguments'),
          )).thenThrow(Exception('DB error'));

      expect(
        () => repository.countRows('products'),
        throwsException,
      );
    });
  });

  group('getDistinctValues', () {
    test('should return distinct values for a column', () async {
      /// ---------------- ARRANGE ----------------
      ///
      /// Simulate DB returning distinct values

      final column = DatasetColumn(
        id: 1,
        datasetTableId: 10,
        originalName: 'price',
        dbName: 'price',
        declaredType: ColumnType.real,
        inferredType: ColumnType.real,
        nullable: false,
        statsJson: null,
      );

      when(() => datasource.query(
            any(),
            arguments: any(named: 'arguments'),
          )).thenAnswer((_) async => [
            {'price': 10},
            {'price': 20},
          ]);

      /// ---------------- ACT ----------------

      final result = await repository.getDistinctValues(
        tableName: 'products',
        column: column,
      );

      /// ---------------- ASSERT ----------------

      expect(result, [10, 20]);

      verify(() => datasource.query(
            'SELECT DISTINCT price FROM products',
            arguments: null,
          )).called(1);
    });

    test('should return empty list when no values found', () async {
      final column = DatasetColumn(
        id: 1,
        datasetTableId: 10,
        originalName: 'price',
        dbName: 'price',
        declaredType: ColumnType.real,
        inferredType: ColumnType.real,
        nullable: false,
        statsJson: null,
      );

      when(() => datasource.query(
            any(),
            arguments: any(named: 'arguments'),
          )).thenAnswer((_) async => []);

      final result = await repository.getDistinctValues(
        tableName: 'products',
        column: column,
      );

      expect(result, isEmpty);
    });

    test('should throw when table name is empty', () async {
      final column = DatasetColumn(
        id: 1,
        datasetTableId: 10,
        originalName: 'price',
        dbName: 'price',
        declaredType: ColumnType.real,
        inferredType: ColumnType.real,
        nullable: false,
        statsJson: null,
      );

      expect(
        () => repository.getDistinctValues(
          tableName: '',
          column: column,
        ),
        throwsException,
      );
    });

    test('should throw when column dbName is empty', () async {
      final column = DatasetColumn(
        id: 1,
        datasetTableId: 10,
        originalName: 'price',
        dbName: '',
        declaredType: ColumnType.real,
        inferredType: ColumnType.real,
        nullable: false,
        statsJson: null,
      );

      expect(
        () => repository.getDistinctValues(
          tableName: 'products',
          column: column,
        ),
        throwsException,
      );
    });

    test('should propagate datasource errors', () async {
      final column = DatasetColumn(
        id: 1,
        datasetTableId: 10,
        originalName: 'price',
        dbName: 'price',
        declaredType: ColumnType.real,
        inferredType: ColumnType.real,
        nullable: false,
        statsJson: null,
      );

      when(() => datasource.query(
            any(),
            arguments: any(named: 'arguments'),
          )).thenThrow(Exception('DB error'));

      expect(
        () => repository.getDistinctValues(
          tableName: 'products',
          column: column,
        ),
        throwsException,
      );
    });
  });

  group('aggregate', () {
    test('should return correct SUM value', () async {
      /// ---------------- ARRANGE ----------------

      final column = DatasetColumn(
        id: 1,
        datasetTableId: 10,
        originalName: 'price',
        dbName: 'price',
        declaredType: ColumnType.real,
        inferredType: ColumnType.real,
        nullable: false,
        statsJson: null,
      );

      when(() => datasource.query(
            any(),
            arguments: any(named: 'arguments'),
          )).thenAnswer((_) async => [
            {'result': 30},
          ]);

      /// ---------------- ACT ----------------

      final result = await repository.aggregate(
        tableName: 'products',
        column: column,
        function: 'SUM',
      );

      /// ---------------- ASSERT ----------------

      expect(result, 30);

      verify(() => datasource.query(
            'SELECT SUM(price) as result FROM products',
            arguments: null,
          )).called(1);
    });

    test('should return correct AVG value', () async {
      final column = DatasetColumn(
        id: 1,
        datasetTableId: 10,
        originalName: 'price',
        dbName: 'price',
        declaredType: ColumnType.real,
        inferredType: ColumnType.real,
        nullable: false,
        statsJson: null,
      );

      when(() => datasource.query(
            any(),
            arguments: any(named: 'arguments'),
          )).thenAnswer((_) async => [
            {'result': 15.5},
          ]);

      final result = await repository.aggregate(
        tableName: 'products',
        column: column,
        function: 'AVG',
      );

      expect(result, 15.5);
    });

    test('should return null when no rows found', () async {
      final column = DatasetColumn(
        id: 1,
        datasetTableId: 10,
        originalName: 'price',
        dbName: 'price',
        declaredType: ColumnType.real,
        inferredType: ColumnType.real,
        nullable: false,
        statsJson: null,
      );

      when(() => datasource.query(
            any(),
            arguments: any(named: 'arguments'),
          )).thenAnswer((_) async => []);

      final result = await repository.aggregate(
        tableName: 'products',
        column: column,
        function: 'SUM',
      );

      expect(result, null);
    });

    test('should throw when table name is empty', () async {
      final column = DatasetColumn(
        id: 1,
        datasetTableId: 10,
        originalName: 'price',
        dbName: 'price',
        declaredType: ColumnType.real,
        inferredType: ColumnType.real,
        nullable: false,
        statsJson: null,
      );

      expect(
        () => repository.aggregate(
          tableName: '',
          column: column,
          function: 'SUM',
        ),
        throwsException,
      );
    });

    test('should throw when column dbName is empty', () async {
      final column = DatasetColumn(
        id: 1,
        datasetTableId: 10,
        originalName: 'price',
        dbName: '',
        declaredType: ColumnType.real,
        inferredType: ColumnType.real,
        nullable: false,
        statsJson: null,
      );

      expect(
        () => repository.aggregate(
          tableName: 'products',
          column: column,
          function: 'SUM',
        ),
        throwsException,
      );
    });

    test('should throw when function is empty', () async {
      final column = DatasetColumn(
        id: 1,
        datasetTableId: 10,
        originalName: 'price',
        dbName: 'price',
        declaredType: ColumnType.real,
        inferredType: ColumnType.real,
        nullable: false,
        statsJson: null,
      );

      expect(
        () => repository.aggregate(
          tableName: 'products',
          column: column,
          function: '',
        ),
        throwsException,
      );
    });

    test('should propagate datasource errors', () async {
      final column = DatasetColumn(
        id: 1,
        datasetTableId: 10,
        originalName: 'price',
        dbName: 'price',
        declaredType: ColumnType.real,
        inferredType: ColumnType.real,
        nullable: false,
        statsJson: null,
      );

      when(() => datasource.query(
            any(),
            arguments: any(named: 'arguments'),
          )).thenThrow(Exception('DB error'));

      expect(
        () => repository.aggregate(
          tableName: 'products',
          column: column,
          function: 'SUM',
        ),
        throwsException,
      );
    });
  });

  group('executeRawQuery', () {
    test('should execute raw query and return result', () async {
      /// ---------------- ARRANGE ----------------

      final expectedRows = [
        {'id': 1, 'name': 'test'},
      ];

      when(() => datasource.query(
            any(),
            arguments: any(named: 'arguments'),
          )).thenAnswer((_) async => expectedRows);

      /// ---------------- ACT ----------------

      final result = await repository.executeRawQuery(
        'SELECT * FROM test_table',
        null,
      );

      /// ---------------- ASSERT ----------------

      expect(result, expectedRows);

      verify(() => datasource.query(
            'SELECT * FROM test_table',
            arguments: null,
          )).called(1);
    });

    test('should pass arguments correctly', () async {
      when(() => datasource.query(
            any(),
            arguments: any(named: 'arguments'),
          )).thenAnswer((_) async => []);

      await repository.executeRawQuery(
        'SELECT * FROM test_table WHERE id = ?',
        [1],
      );

      verify(() => datasource.query(
            'SELECT * FROM test_table WHERE id = ?',
            arguments: [1],
          )).called(1);
    });

    test('should throw when SQL is empty', () async {
      expect(
        () => repository.executeRawQuery('', null),
        throwsException,
      );
    });

    test('should propagate datasource errors', () async {
      when(() => datasource.query(
            any(),
            arguments: any(named: 'arguments'),
          )).thenThrow(Exception('DB error'));

      expect(
        () => repository.executeRawQuery(
          'SELECT * FROM test',
          null,
        ),
        throwsException,
      );
    });
  });
}
