import 'dart:io';

import 'package:exlser/data/adapters/parsers/csv_parser.dart';
import 'package:exlser/domain/entities/parsed_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CsvParser', () {
    late CsvParser parser;

    setUp(() {
      parser = CsvParser();
    });

    test(
      'should correctly parse a valid csv file',
      () async {
        final sheets = await parser.parsePath(
          'test/fixtures/csv/simple.csv',
        );

        /// Verify sheet count.
        expect(sheets.length, 1);

        final sheet = sheets.first;

        /// Verify ParsedSheet type.
        expect(sheet, isA<ParsedSheet>());

        /// Verify sheet name.
        expect(sheet.name, 'Sheet1');

        /// Verify rows count.
        expect(sheet.rows.length, 6);

        /// Verify first row values.
        final firstRow = sheet.rows.first;

        expect(firstRow['product'], 'book');
        expect(firstRow['price'], '10');
        expect(firstRow['quantity'], '20');
        expect(firstRow['date'], '2024-01-14');

        /// Verify structure.
        expect(firstRow, isA<Map<String, dynamic>>());
      },
    );

    test(
      'should correctly parse csv bytes',
      () async {
        final bytes = await File('test/fixtures/csv/simple.csv').readAsBytes();

        final sheets = await parser.parseBytes(bytes);

        expect(sheets.length, 1);
        expect(sheets.first.name, 'Sheet1');
        expect(sheets.first.rows.length, 6);
        expect(sheets.first.rows.first['product'], 'book');
      },
    );

    test(
      'should correctly map column names',
      () async {
        final sheets = await parser.parsePath(
          'test/fixtures/csv/simple.csv',
        );

        final firstRow = sheets.first.rows.first;

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
          () => parser.parsePath(
            'test/fixtures/csv/empty.csv',
          ),
          throwsException,
        );
      },
    );

    test(
      'should throw an error when csv bytes are empty',
      () async {
        expect(
          () => parser.parseBytes(const []),
          throwsException,
        );
      },
    );
  });
}
