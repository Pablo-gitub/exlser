import 'package:exlser/domain/usecases/query/read_only_sql_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validator = ReadOnlySqlValidator();

  ReadOnlySqlValidation validate(
    String sql, {
    Set<String> allowed = const {'ds_1_sales', 'ds_1_returns'},
    String activeTable = 'ds_1_sales',
    int limit = 100,
  }) {
    return validator.validate(
      sql: sql,
      allowedTableNames: allowed,
      activeTableName: activeTable,
      limit: limit,
    );
  }

  Matcher throwsCode(String code) => throwsA(
        isA<ReadOnlyQueryException>().having((e) => e.code, 'code', code),
      );

  group('ReadOnlySqlValidator accepted queries', () {
    test('wraps a select on the sheet alias with the row limit', () {
      final result = validate('SELECT product FROM sheet', limit: 50);

      expect(result.normalizedSql, 'SELECT product FROM ds_1_sales');
      expect(
        result.executableSql,
        'SELECT * FROM (SELECT product FROM ds_1_sales) LIMIT 50',
      );
    });

    test('replaces a quoted sheet alias too', () {
      final result = validate('SELECT * FROM "sheet"');

      expect(result.normalizedSql, 'SELECT * FROM ds_1_sales');
    });

    test('accepts a join between two allowed tables', () {
      expect(
        validate(
          'SELECT * FROM ds_1_sales JOIN ds_1_returns '
          'ON ds_1_sales.id = ds_1_returns.sale_id',
        ).normalizedSql,
        contains('JOIN ds_1_returns'),
      );
    });

    test('matches allowed table names case-insensitively', () {
      expect(validate('SELECT * FROM DS_1_SALES').normalizedSql, isNotEmpty);
    });

    test('accepts a compound select over allowed tables', () {
      expect(
        validate('SELECT id FROM ds_1_sales UNION SELECT id FROM ds_1_returns')
            .normalizedSql,
        isNotEmpty,
      );
    });

    test('accepts a CTE whose body reads an allowed table', () {
      expect(
        validate('WITH recent AS (SELECT * FROM sheet) SELECT * FROM recent')
            .normalizedSql,
        contains('ds_1_sales'),
      );
    });
  });

  group('ReadOnlySqlValidator no longer rejects safe text', () {
    test('a string literal containing a blocked keyword', () {
      // The keyword denylist used to reject this outright.
      expect(
        validate("SELECT * FROM sheet WHERE note = 'update'").normalizedSql,
        "SELECT * FROM ds_1_sales WHERE note = 'update'",
      );
      expect(
        validate("SELECT * FROM sheet WHERE note = 'drop table x'")
            .normalizedSql,
        isNotEmpty,
      );
    });

    test('a string literal containing a semicolon or comment markers', () {
      expect(
        validate("SELECT * FROM sheet WHERE code = 'a;b'").normalizedSql,
        isNotEmpty,
      );
      expect(
        validate("SELECT * FROM sheet WHERE code = 'a -- b'").normalizedSql,
        isNotEmpty,
      );
    });

    test('a trailing comment', () {
      expect(
        validate('SELECT * FROM sheet -- only the first rows').normalizedSql,
        isNotEmpty,
      );
    });

    test('a trailing semicolon', () {
      expect(validate('SELECT * FROM sheet;').normalizedSql, isNotEmpty);
    });
  });

  group('ReadOnlySqlValidator closed bypasses', () {
    test('rejects a comma-joined table outside the allowlist', () {
      expect(
        () => validate('SELECT * FROM sheet, ds_99_other'),
        throwsCode(ReadOnlySqlValidator.unknownTableCode),
      );
    });

    test('rejects sqlite_master reached through a comma join', () {
      expect(
        () => validate('SELECT name, sql FROM sheet, sqlite_master'),
        throwsCode(ReadOnlySqlValidator.unknownTableCode),
      );
    });

    test('rejects a foreign table inside a subquery', () {
      expect(
        () => validate(
          'SELECT * FROM sheet WHERE id IN (SELECT id FROM ds_99_other)',
        ),
        throwsCode(ReadOnlySqlValidator.unknownTableCode),
      );
    });

    test('rejects a foreign table inside a CTE body', () {
      expect(
        () => validate(
          'WITH leak AS (SELECT * FROM sqlite_master) SELECT * FROM leak',
        ),
        throwsCode(ReadOnlySqlValidator.unknownTableCode),
      );
    });

    test('rejects a table-valued function used as a source', () {
      expect(
        () => validate("SELECT * FROM pragma_table_info('ds_1_sales')"),
        throwsCode(ReadOnlySqlValidator.unsafeStatementCode),
      );
    });

    test('rejects a function that reaches outside the database', () {
      expect(
        () => validate("SELECT load_extension('evil.so') FROM sheet"),
        throwsCode(ReadOnlySqlValidator.unsafeStatementCode),
      );
    });
  });

  group('ReadOnlySqlValidator rejected statements', () {
    test('rejects data and schema changes', () {
      for (final sql in [
        'DELETE FROM sheet',
        'UPDATE sheet SET product = 1',
        'INSERT INTO sheet (product) VALUES (1)',
        'DROP TABLE ds_1_sales',
        'CREATE TABLE x (id INTEGER)',
        'ALTER TABLE ds_1_sales RENAME TO x',
        'PRAGMA writable_schema = 1',
        'VACUUM',
        'BEGIN TRANSACTION',
      ]) {
        expect(
          () => validate(sql),
          throwsCode(ReadOnlySqlValidator.unsafeStatementCode),
          reason: sql,
        );
      }
    });

    test('rejects more than one statement', () {
      expect(
        () => validate('SELECT * FROM sheet; DROP TABLE ds_1_sales'),
        throwsCode(ReadOnlySqlValidator.multipleStatementsCode),
      );
      expect(
        () => validate('SELECT 1; SELECT 2'),
        throwsCode(ReadOnlySqlValidator.multipleStatementsCode),
      );
    });

    test('reports unparseable input as a syntax problem', () {
      expect(
        () => validate('this is not sql'),
        throwsCode(ReadOnlySqlValidator.invalidSyntaxCode),
      );
      expect(
        () => validate('SELECT * FROM'),
        throwsCode(ReadOnlySqlValidator.invalidSyntaxCode),
      );
    });

    test('rejects an empty query', () {
      expect(() => validate('   '), throwsCode(ReadOnlySqlValidator.emptyCode));
    });

    test('rejects a non-positive limit', () {
      expect(
        () => validate('SELECT * FROM sheet', limit: 0),
        throwsCode(ReadOnlySqlValidator.invalidLimitCode),
      );
    });

    test('rejects an active table that is not allowed', () {
      expect(
        () => validate('SELECT * FROM sheet', activeTable: 'ds_2_other'),
        throwsCode(ReadOnlySqlValidator.unknownTableCode),
      );
      expect(
        () => validate('SELECT * FROM sheet', activeTable: '  '),
        throwsCode(ReadOnlySqlValidator.unknownTableCode),
      );
    });
  });
}
