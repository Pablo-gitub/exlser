import 'package:flutter_test/flutter_test.dart';
import 'package:exel_category/data/adapters/parsers/csv_parser.dart';

void main() {
  group('CsvParser', () {

    late CsvParser parser;

    setUp(() {
      parser = CsvParser();
    });

    test(
      'should correctly parse a valid csv file',
      () async {

        final rows = await parser.parse(
          'test/fixtures/csv/simple.csv',
        );

        /// verify rows count
        expect(rows.length, 6);

        /// verify first row
        expect(rows.first['product'], 'book');
        expect(rows.first['price'], '10');
        expect(rows.first['quantity'], '20');
        expect(rows.first['date'], '2024-01-14');

        /// verify structure
        expect(rows.first, isA<Map<String, dynamic>>());

      },
    );

    test(
      'should correctly map column names',
      () async {

        final rows = await parser.parse(
          'test/fixtures/csv/simple.csv',
        );

        final firstRow = rows.first;

        expect(firstRow.keys.contains('product'), true);
        expect(firstRow.keys.contains('price'), true);
        expect(firstRow.keys.contains('quantity'), true);
        expect(firstRow.keys.contains('date'), true);

      },
    );

    test(
      'should throw an error when csv file is empty',
      () async {

        expect(
          () => parser.parse(
            'test/fixtures/csv/empty.csv',
          ),
          throwsException,
        );

      },
    );
  });
}