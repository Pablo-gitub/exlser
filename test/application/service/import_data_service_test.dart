import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:exel_category/application/services/import_data_service.dart';
import 'package:exel_category/data/adapters/parsers/parser_factory.dart';
import 'package:exel_category/data/adapters/parsers/spreadsheet_parser.dart';
import 'package:exel_category/domain/entities/parsed_sheet.dart';

/// ---------------- MOCKS ----------------

class MockParserFactory extends Mock implements ParserFactory {}
class MockSpreadsheetParser extends Mock implements SpreadsheetParser {}

void main() {
  late ImportDataService service;
  late MockParserFactory parserFactory;
  late MockSpreadsheetParser parser;

  setUp(() {
    parserFactory = MockParserFactory();
    parser = MockSpreadsheetParser();

    service = ImportDataService(
      parserFactory: parserFactory,
    );
  });

  test('should detect extension and parse file correctly', () async {
    /// ---------------- ARRANGE ----------------
    ///
    /// This test verifies:
    /// - file extension extraction
    /// - parser resolution
    /// - parser execution

    final filePath = 'test.xlsx';

    final parsedSheets = [
      ParsedSheet(
        name: 'Sheet1',
        rows: [
          {'a': '1'}
        ],
      ),
    ];

    /// Mock parser resolution
    when(() => parserFactory.createParser('xlsx'))
        .thenReturn(parser);

    /// Mock parsing result
    when(() => parser.parse(filePath))
        .thenAnswer((_) async => parsedSheets);

    /// ---------------- ACT ----------------

    final result = await service.prepareImport(
      filePath: filePath,
    );

    /// ---------------- ASSERT ----------------

    verify(() => parserFactory.createParser('xlsx')).called(1);

    verify(() => parser.parse(filePath)).called(1);

    expect(result, parsedSheets);
  });

  test('should handle csv files correctly', () async {
    /// ---------------- ARRANGE ----------------

    final filePath = 'data.csv';

    when(() => parserFactory.createParser('csv'))
        .thenReturn(parser);

    when(() => parser.parse(filePath))
        .thenAnswer((_) async => []);

    /// ---------------- ACT ----------------

    await service.prepareImport(filePath: filePath);

    /// ---------------- ASSERT ----------------

    verify(() => parserFactory.createParser('csv')).called(1);
    verify(() => parser.parse(filePath)).called(1);
  });

  test('should throw if file has no extension', () async {
    /// ---------------- ARRANGE ----------------

    final filePath = 'file_without_extension';

    /// ---------------- ACT & ASSERT ----------------

    expect(
      () => service.prepareImport(filePath: filePath),
      throwsException,
    );
  });
}