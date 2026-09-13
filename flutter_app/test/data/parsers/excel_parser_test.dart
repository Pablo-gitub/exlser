import 'dart:io';

import 'package:exlser/data/adapters/parsers/excel_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExcelParser', () {
    late ExcelParser parser;

    setUp(() {
      parser = ExcelParser();
    });

    test(
      'should correctly parse a simple excel file',
      () async {
        final sheets = await parser.parsePath(
          'test/fixtures/excel/simple.xlsx',
        );

        expect(sheets.length, 1);

        final sheet = sheets.first;

        expect(sheet.name, 'Foglio1');

        expect(sheet.rows.length, 6);

        expect(sheet.rows.first['product'], 'book');
        expect(sheet.rows.first['price'], '10');
        expect(sheet.rows.first['quantity'], '20');
        expect(sheet.rows.first['brand'], 'mondadori');
      },
    );

    test(
      'should correctly parse excel bytes',
      () async {
        final bytes =
            await File('test/fixtures/excel/simple.xlsx').readAsBytes();

        final sheets = await parser.parseBytes(bytes);

        expect(sheets.length, 1);
        expect(sheets.first.name, 'Foglio1');
        expect(sheets.first.rows.length, 6);
        expect(sheets.first.rows.first['product'], 'book');
      },
    );

    test(
      'should correctly preserve column names',
      () async {
        final sheets = await parser.parsePath(
          'test/fixtures/excel/simple.xlsx',
        );

        final firstRow = sheets.first.rows.first;

        expect(firstRow.keys.contains('product'), true);
        expect(firstRow.keys.contains('price'), true);
        expect(firstRow.keys.contains('quantity'), true);
        expect(firstRow.keys.contains('brand'), true);
      },
    );

    test(
      'should correctly parse multiple sheets',
      () async {
        final sheets = await parser.parsePath(
          'test/fixtures/excel/multi_sheet.xlsx',
        );

        expect(sheets.length, 3);

        expect(sheets[0].rows.isNotEmpty, true);
        expect(sheets[1].rows.isNotEmpty, true);
        expect(sheets[2].rows.isNotEmpty, true);
      },
    );

    test(
      'should parse absolute workbook relationship targets',
      () async {
        final bytes = await File(
          'test/fixtures/excel/absolute_relationship_targets.xlsx',
        ).readAsBytes();
        final sheets = await parser.parseBytes(bytes);

        expect(
          sheets.map((sheet) => sheet.name),
          ['Sales', 'Products', 'Regions'],
        );
        expect(sheets.first.rows, hasLength(6));
      },
    );

    test(
      'should preserve sheet names',
      () async {
        final sheets = await parser.parsePath(
          'test/fixtures/excel/multi_sheet.xlsx',
        );

        expect(sheets[0].name, 'Foglio1');
        expect(sheets[1].name, 'Foglio2');
        expect(sheets[2].name, 'Foglio3');
      },
    );

    test(
      'should throw when excel file is empty',
      () async {
        expect(
          () => parser.parsePath(
            'test/fixtures/excel/empty.xlsx',
          ),
          throwsException,
        );
      },
    );

    test(
      'should throw when excel file does not exist',
      () async {
        expect(
          () => parser.parsePath(
            'test/fixtures/excel/not_existing.xlsx',
          ),
          throwsException,
        );
      },
    );

    test(
      'should populate sourceSheetName and cellRange metadata on parsed sheets',
      () async {
        final sheets = await parser.parsePath(
          'test/fixtures/excel/simple.xlsx',
        );

        final sheet = sheets.first;
        expect(sheet.sourceSheetName, 'Foglio1');
        expect(sheet.cellRange, isNotNull);
        expect(sheet.cellRange, startsWith('A'));
      },
    );

    test(
      'should parse as single table per sheet when detectMultipleTables is false',
      () async {
        final sheets = await parser.parsePath(
          'test/fixtures/excel/simple.xlsx',
          detectMultipleTables: false,
        );

        final sheet = sheets.first;
        expect(sheet.name, 'Foglio1');
        expect(sheet.sourceSheetName, 'Foglio1');
        expect(sheet.cellRange, isNull);
      },
    );

    test(
      'should detect multiple tables separated by blank rows with titles in a real excel file',
      () async {
        final sheets = await parser.parsePath(
          'test/fixtures/excel/multi_table_same_sheet.xlsx',
          detectMultipleTables: true,
        );

        expect(sheets.length, 2);

        final customersTable = sheets[0];
        expect(customersTable.name, 'Customers');
        expect(customersTable.sourceSheetName, 'Dashboard');
        expect(customersTable.cellRange, 'A2:C5');
        expect(customersTable.rows.length, 3);
        expect(customersTable.rows[0]['id'], '1');
        expect(customersTable.rows[0]['name'], 'Alice');
        expect(customersTable.rows[0]['city'], 'Rome');

        final ordersTable = sheets[1];
        expect(ordersTable.name, 'Orders');
        expect(ordersTable.sourceSheetName, 'Dashboard');
        expect(ordersTable.cellRange, 'A9:D12');
        expect(ordersTable.rows.length, 3);
        expect(ordersTable.rows[0]['order_id'], '101');
        expect(ordersTable.rows[0]['customer_id'], '1');
        expect(ordersTable.rows[0]['amount'], '250.50');
      },
    );

    test(
      'should parse real cross-tab matrix excel file',
      () async {
        final sheets = await parser.parsePath(
          'test/fixtures/excel/matrix_cross_tab.xlsx',
        );

        expect(sheets.length, 1);
        final sheet = sheets.first;
        expect(sheet.name, 'SalesByMonth');
        expect(sheet.rows.length, 3);
        expect(sheet.rows[0]['Department'], 'Electronics');
        expect(sheet.rows[0]['Jan'], '10000');
        expect(sheet.rows[0]['Jun'], '16000');
      },
    );
  });
}
