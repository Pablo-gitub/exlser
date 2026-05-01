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
        final callback = invocation.positionalArguments.first as Future<void> Function();
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
}