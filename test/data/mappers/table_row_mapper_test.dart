import 'package:exel_category/data/adapters/mappers/table_row_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TableRowMapper', () {
    test('maps rows using non-empty headers', () {
      final result = TableRowMapper.map([
        ['product', 'price'],
        ['Vans', '120'],
      ]);

      expect(result, [
        {'product': 'Vans', 'price': '120'},
      ]);
    });

    test('ignores columns with blank headers', () {
      final result = TableRowMapper.map([
        ['', 'product', 'price'],
        ['', 'Vans', '120'],
      ]);

      expect(result, [
        {'product': 'Vans', 'price': '120'},
      ]);
      expect(result.first.containsKey(''), isFalse);
    });

    test('returns no rows when all headers are blank', () {
      final result = TableRowMapper.map([
        ['', ' '],
        ['ignored', 'ignored'],
      ]);

      expect(result, isEmpty);
    });
  });
}
