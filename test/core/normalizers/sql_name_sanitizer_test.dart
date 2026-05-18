import 'package:exel_category/core/normalizers/sql_name_sanitizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SqlNameSanitizer', () {
    group('sanitizeColumnName', () {
      test('should convert to lowercase and trim spaces', () {
        final result =
            SqlNameSanitizer.sanitizeColumnName('  My Column Name  ');
        expect(result, 'my_column_name');
      });

      test('should replace non-alphanumeric characters with underscores', () {
        final result1 = SqlNameSanitizer.sanitizeColumnName('Price (€)');
        final result2 = SqlNameSanitizer.sanitizeColumnName('User@Email!#');

        expect(result1,
            'price'); // Notice trailing/leading underscores are removed
        expect(result2, 'user_email');
      });

      test(
          'should handle consecutive special characters with a single underscore',
          () {
        final result = SqlNameSanitizer.sanitizeColumnName('product!!!price');
        expect(result, 'product_price');
      });

      test('should remove leading and trailing underscores', () {
        final result =
            SqlNameSanitizer.sanitizeColumnName('___hidden_field___');
        expect(result, 'hidden_field');
      });

      test(
          'should use fallback prefix if name becomes empty after sanitization',
          () {
        expect(SqlNameSanitizer.sanitizeColumnName(''), 'col');
        expect(SqlNameSanitizer.sanitizeColumnName('   '), 'col');
        expect(
            SqlNameSanitizer.sanitizeColumnName('🚀🚀'), 'col'); // Emojis only
        expect(SqlNameSanitizer.sanitizeColumnName('!@#\$'),
            'col'); // Special chars only
      });

      test('should add prefix if name starts with a number', () {
        expect(
            SqlNameSanitizer.sanitizeColumnName('1st_place'), 'col_1st_place');
        expect(SqlNameSanitizer.sanitizeColumnName('2023_Sales'),
            'col_2023_sales');
      });

      test('should append prefix if name is an SQL reserved keyword', () {
        expect(SqlNameSanitizer.sanitizeColumnName('Select'), 'select_col');
        expect(SqlNameSanitizer.sanitizeColumnName('TABLE'), 'table_col');
        expect(SqlNameSanitizer.sanitizeColumnName('group'), 'group_col');
      });

      test('should avoid duplicates by appending a counter', () {
        final existingNames = ['my_column', 'my_column_1', 'select_col'];

        // Base collision
        expect(
          SqlNameSanitizer.sanitizeColumnName('My Column',
              existingNames: existingNames),
          'my_column_2',
        );

        // Keyword collision
        expect(
          SqlNameSanitizer.sanitizeColumnName('select',
              existingNames: existingNames),
          'select_col_1',
        );
      });

      test('should handle completely chaotic inputs resolving to unique names',
          () {
        final existingNames = ['col', 'col_1'];
        expect(
          SqlNameSanitizer.sanitizeColumnName('🎉',
              existingNames: existingNames),
          'col_2',
        );
      });
    });

    group('sanitizeTableName', () {
      test('should use "tbl" fallback prefix for empty names', () {
        expect(SqlNameSanitizer.sanitizeTableName(''), 'tbl');
        expect(SqlNameSanitizer.sanitizeTableName('🚀'), 'tbl');
      });

      test('should prepend "tbl" if name starts with a number', () {
        expect(
            SqlNameSanitizer.sanitizeTableName('2023_Data'), 'tbl_2023_data');
      });

      test('should append "tbl" if name is a reserved keyword', () {
        expect(SqlNameSanitizer.sanitizeTableName('Where'), 'where_tbl');
      });
    });
  });
}
