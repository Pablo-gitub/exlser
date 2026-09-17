import 'package:exlser/core/sql/read_only_sql_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const guard = ReadOnlySqlGuard();

  Matcher throwsReason(String reason) => throwsA(
        isA<UnsafeRawQueryException>()
            .having((e) => e.reason, 'reason', reason),
      );

  group('ReadOnlySqlGuard', () {
    test('accepts the statement shapes the app builds internally', () {
      const statements = [
        'SELECT * FROM "ds_1_sales" LIMIT 10 OFFSET 20',
        'SELECT COUNT(*) as count FROM "ds_1_sales"',
        'SELECT DISTINCT "brand" FROM "ds_1_sales"',
        'SELECT SUM("price") as result FROM "ds_1_sales"',
        'SELECT * FROM (SELECT * FROM "ds_1_sales") LIMIT 5',
        'SELECT COUNT(*) AS __row_count FROM (SELECT * FROM "ds_1_sales")',
        'SELECT "x" AS x_val, AVG(CAST("y" AS REAL)) AS y_val '
            'FROM "ds_1_sales" GROUP BY "x" ORDER BY y_val DESC',
        'SELECT a."id", b."sale_id" FROM "ds_1_sales" a '
            'INNER JOIN "ds_1_returns" b ON a."id" = b."sale_id"',
      ];

      for (final sql in statements) {
        expect(() => guard.assertSingleSelect(sql), returnsNormally,
            reason: sql);
      }
    });

    test('refuses anything that could write', () {
      for (final sql in [
        'DELETE FROM ds_1_sales',
        'UPDATE ds_1_sales SET price = 0',
        'INSERT INTO ds_1_sales (price) VALUES (1)',
        'DROP TABLE ds_1_sales',
        'PRAGMA foreign_keys = ON',
      ]) {
        expect(
          () => guard.assertSingleSelect(sql),
          throwsReason('not_read_only'),
          reason: sql,
        );
      }
    });

    test('refuses a second statement smuggled after a select', () {
      expect(
        () => guard.assertSingleSelect('SELECT 1; DROP TABLE ds_1_sales'),
        throwsReason('multiple_statements'),
      );
    });

    test('refuses a table-valued function and an extension loader', () {
      expect(
        () => guard.assertSingleSelect("SELECT * FROM pragma_table_info('x')"),
        throwsReason('table_valued_function'),
      );
      expect(
        () => guard.assertSingleSelect("SELECT load_extension('x.so')"),
        throwsReason('unsafe_function'),
      );
    });

    test('refuses empty and unparseable SQL', () {
      expect(() => guard.assertSingleSelect('  '), throwsReason('empty'));
      expect(
        () => guard.assertSingleSelect('not sql'),
        throwsReason('invalid_syntax'),
      );
    });

    test('keeps a semicolon inside a literal readable', () {
      expect(
        () => guard.assertSingleSelect(
          "SELECT * FROM ds_1_sales WHERE note = 'a;b'",
        ),
        returnsNormally,
      );
    });
  });
}
