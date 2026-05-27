import 'package:exlser/domain/repositories/query_repository.dart';
import 'package:exlser/domain/usecases/query/execute_read_only_query_usecase.dart';
import 'package:exlser/domain/usecases/query/read_only_sql_validator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockQueryRepository extends Mock implements QueryRepository {}

void main() {
  late MockQueryRepository repository;
  late ExecuteReadOnlyQueryUseCase useCase;

  setUp(() {
    repository = MockQueryRepository();
    useCase = ExecuteReadOnlyQueryUseCase(repository: repository);
  });

  test('executes a wrapped SELECT query with a forced limit', () async {
    when(() => repository.executeRawQuery(any(), null)).thenAnswer(
      (invocation) async {
        final sql = invocation.positionalArguments.first as String;
        if (sql.startsWith('SELECT COUNT(*)')) {
          return [
            {'__row_count': 12},
          ];
        }
        return [
          {'product': 'book'},
        ];
      },
    );

    final result = await useCase(
      sql: 'SELECT product FROM sheet',
      activeTableName: 'tbl_sales',
      allowedTableNames: {'tbl_sales'},
      limit: 50,
    );

    expect(result.rows, [
      {'product': 'book'},
    ]);
    expect(result.rowCount, 12);
    final capturedSql = verify(() => repository.executeRawQuery(
          captureAny(),
          null,
        )).captured.cast<String>();
    expect(
      capturedSql,
      contains('SELECT * FROM (SELECT product FROM tbl_sales) LIMIT 50'),
    );
    expect(
      capturedSql,
      contains(
        'SELECT COUNT(*) AS __row_count FROM (SELECT product FROM tbl_sales)',
      ),
    );
  });

  test('counts matching rows before the display limit', () async {
    when(() => repository.executeRawQuery(any(), null)).thenAnswer(
      (invocation) async {
        final sql = invocation.positionalArguments.first as String;
        if (sql.startsWith('SELECT COUNT(*)')) {
          return [
            {'__row_count': 756},
          ];
        }
        return List.generate(100, (index) => {'product': 'item_$index'});
      },
    );

    final result = await useCase(
      sql: 'SELECT product FROM sheet LIMIT 100',
      activeTableName: 'tbl_sales',
      allowedTableNames: {'tbl_sales'},
      limit: 100,
    );

    expect(result.rows.length, 100);
    expect(result.rowCount, 756);
    final capturedSql = verify(() => repository.executeRawQuery(
          captureAny(),
          null,
        )).captured.cast<String>();
    expect(
      capturedSql,
      contains(
        'SELECT COUNT(*) AS __row_count FROM (SELECT product FROM tbl_sales)',
      ),
    );
    expect(
      capturedSql,
      isNot(contains(
        'SELECT COUNT(*) AS __row_count FROM (SELECT product FROM tbl_sales LIMIT 100)',
      )),
    );
  });

  test('allows known dataset tables and rejects unknown tables', () async {
    when(() => repository.executeRawQuery(any(), null))
        .thenAnswer((_) async => []);

    await useCase(
      sql: 'SELECT * FROM "tbl_sales"',
      activeTableName: 'tbl_sales',
      allowedTableNames: {'tbl_sales', 'tbl_costs'},
      limit: 100,
    );

    expect(
      () => useCase(
        sql: 'SELECT * FROM datasets',
        activeTableName: 'tbl_sales',
        allowedTableNames: {'tbl_sales'},
        limit: 100,
      ),
      throwsA(
        isA<ReadOnlyQueryException>().having(
          (error) => error.code,
          'code',
          ReadOnlySqlValidator.unknownTableCode,
        ),
      ),
    );
  });

  test('rejects unsafe and multiple statements before execution', () async {
    for (final sql in [
      'UPDATE tbl_sales SET product = "x"',
      'SELECT * FROM tbl_sales; SELECT * FROM tbl_sales',
      'DELETE FROM tbl_sales',
      'PRAGMA table_info(tbl_sales)',
    ]) {
      expect(
        () => useCase(
          sql: sql,
          activeTableName: 'tbl_sales',
          allowedTableNames: {'tbl_sales'},
          limit: 100,
        ),
        throwsA(isA<ReadOnlyQueryException>()),
      );
    }

    verifyNever(() => repository.executeRawQuery(any(), any()));
  });

  test('rejects non-positive limits', () {
    expect(
      () => useCase(
        sql: 'SELECT * FROM sheet',
        activeTableName: 'tbl_sales',
        allowedTableNames: {'tbl_sales'},
        limit: 0,
      ),
      throwsA(
        isA<ReadOnlyQueryException>().having(
          (error) => error.code,
          'code',
          ReadOnlySqlValidator.invalidLimitCode,
        ),
      ),
    );
  });
}
