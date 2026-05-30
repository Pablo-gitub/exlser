import 'package:exlser/application/exceptions/import_exceptions.dart';
import 'package:exlser/application/dto/import_file.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:exlser/application/services/import_data_service.dart';
import 'package:exlser/data/adapters/parsers/parser_factory.dart';
import 'package:exlser/data/adapters/parsers/spreadsheet_parser.dart';
import 'package:exlser/domain/entities/parsed_sheet.dart';
import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/usecases/schema/infer_schema_usecase.dart';
import 'package:exlser/domain/value_objects/column_type.dart';

/// ---------------- MOCKS ----------------

class MockParserFactory extends Mock implements ParserFactory {}

class MockSpreadsheetParser extends Mock implements SpreadsheetParser {}

class MockInferSchemaUseCase extends Mock implements InferSchemaUseCase {}

class FakeDatasetColumn extends Fake implements DatasetColumn {}

void main() {
  late ImportDataService service;

  late MockParserFactory parserFactory;
  late MockSpreadsheetParser parser;
  late MockInferSchemaUseCase inferSchemaUseCase;

  setUpAll(() {
    registerFallbackValue(FakeDatasetColumn());
    registerFallbackValue(<DatasetColumn>[]);
    registerFallbackValue(<int>[]);
  });

  setUp(() {
    parserFactory = MockParserFactory();
    parser = MockSpreadsheetParser();
    inferSchemaUseCase = MockInferSchemaUseCase();

    service = ImportDataService(
      parserFactory: parserFactory,
      inferSchemaUseCase: inferSchemaUseCase,
    );
  });

  test('should parse file and infer schema correctly', () async {
    /// ---------------- ARRANGE ----------------
    ///
    /// Verifies:
    /// - parser resolution
    /// - parsing execution
    /// - schema inference
    /// - result structure

    final fileName = 'test.xlsx';
    final filePath = '/tmp/uploads/test.xlsx';

    final parsedSheets = [
      ParsedSheet(
        name: 'Sheet1',
        rows: [
          {'product': 'book', 'price': '10'},
        ],
      ),
    ];

    final columns = [
      DatasetColumn(
        id: 0,
        datasetTableId: 0,
        originalName: 'product',
        dbName: 'product',
        declaredType: ColumnType.text,
        inferredType: ColumnType.text,
        nullable: false,
        statsJson: null,
      ),
    ];

    when(() => parserFactory.createParser('xlsx')).thenReturn(parser);

    when(() => parser.parsePath(filePath))
        .thenAnswer((_) async => parsedSheets);

    when(() => inferSchemaUseCase.call(any(), any())).thenReturn(columns);

    /// ---------------- ACT ----------------

    final result = await service.prepareImport(
      file: ImportFile.fromPath(
        fileName: fileName,
        path: filePath,
      ),
    );

    /// ---------------- ASSERT ----------------

    verify(() => parserFactory.createParser('xlsx')).called(1);
    verify(() => parser.parsePath(filePath)).called(1);
    verify(() => inferSchemaUseCase.call(any(), 0)).called(1);

    expect(result.fileName, 'test.xlsx');
    expect(result.fileExtension, 'xlsx');
    expect(result.sheetCount, 1);
    expect(result.sheets.first.sheet, parsedSheets.first);
    expect(result.sheets.first.inferredColumns, columns);
  });

  test('should parse in-memory bytes and infer schema correctly', () async {
    /// ---------------- ARRANGE ----------------
    ///
    /// Verifies web/upload import flow without requiring a file path.

    final fileBytes = [1, 2, 3];

    final parsedSheets = [
      ParsedSheet(
        name: 'Sheet1',
        rows: [
          {'product': 'book', 'price': '10'},
        ],
      ),
    ];

    final columns = [
      DatasetColumn(
        id: 0,
        datasetTableId: 0,
        originalName: 'product',
        dbName: 'product',
        declaredType: ColumnType.text,
        inferredType: ColumnType.text,
        nullable: false,
        statsJson: null,
      ),
    ];

    when(() => parserFactory.createParser('csv')).thenReturn(parser);

    when(() => parser.parseBytes(fileBytes))
        .thenAnswer((_) async => parsedSheets);

    when(() => inferSchemaUseCase.call(any(), any())).thenReturn(columns);

    /// ---------------- ACT ----------------

    final result = await service.prepareImport(
      file: ImportFile.fromBytes(
        fileName: 'web_upload.csv',
        bytes: fileBytes,
      ),
    );

    /// ---------------- ASSERT ----------------

    verify(() => parserFactory.createParser('csv')).called(1);
    verify(() => parser.parseBytes(fileBytes)).called(1);
    verifyNever(() => parser.parsePath(any()));
    verify(() => inferSchemaUseCase.call(any(), 0)).called(1);

    expect(result.fileName, 'web_upload.csv');
    expect(result.fileExtension, 'csv');
    expect(result.sheetCount, 1);
    expect(result.sheets.first.sheet, parsedSheets.first);
    expect(result.sheets.first.inferredColumns, columns);
  });

  test('should throw when file contains no readable sheets', () async {
    /// ---------------- ARRANGE ----------------
    ///
    /// Simulate a parser returning no sheets

    final filePath = 'data.csv';

    when(() => parserFactory.createParser('csv')).thenReturn(parser);

    when(() => parser.parsePath(filePath)).thenAnswer((_) async => []);

    /// ---------------- ACT & ASSERT ----------------

    await expectLater(
      service.prepareImport(
        file: ImportFile.fromPath(
          fileName: filePath,
          path: filePath,
        ),
      ),
      throwsA(
        isA<ParsingException>().having((e) => e.code, 'code', 'no_sheets'),
      ),
    );
  });

  test('should throw unsupported format when parser cannot be resolved',
      () async {
    /// ---------------- ARRANGE ----------------

    when(() => parserFactory.createParser('ods')).thenThrow(
      Exception('Unsupported file format: ods'),
    );

    /// ---------------- ACT & ASSERT ----------------

    await expectLater(
      service.prepareImport(
        file: ImportFile.fromPath(
          fileName: 'data.ods',
          path: '/tmp/uploads/data.ods',
        ),
      ),
      throwsA(
        isA<UnsupportedFormatException>().having(
          (e) => e.extension,
          'extension',
          'ods',
        ),
      ),
    );

    verify(() => parserFactory.createParser('ods')).called(1);
    verifyNever(() => parser.parsePath(any()));
    verifyNever(() => parser.parseBytes(any()));
  });

  test('should wrap parser errors in parsing exception', () async {
    /// ---------------- ARRANGE ----------------

    const filePath = '/tmp/uploads/broken.csv';

    when(() => parserFactory.createParser('csv')).thenReturn(parser);

    when(() => parser.parsePath(filePath)).thenThrow(
      Exception('Cannot decode CSV'),
    );

    /// ---------------- ACT & ASSERT ----------------

    await expectLater(
      service.prepareImport(
        file: ImportFile.fromPath(
          fileName: 'broken.csv',
          path: filePath,
        ),
      ),
      throwsA(
        isA<ParsingException>().having(
          (e) => e.code,
          'code',
          'parsing_failed',
        ),
      ),
    );

    verify(() => parserFactory.createParser('csv')).called(1);
    verify(() => parser.parsePath(filePath)).called(1);
    verifyNever(() => inferSchemaUseCase.call(any(), any()));
  });

  test('should throw schema inference exception when inference fails',
      () async {
    /// ---------------- ARRANGE ----------------

    const filePath = '/tmp/uploads/schema.csv';

    final parsedSheets = [
      ParsedSheet(
        name: 'Products',
        rows: [
          {'product': 'book', 'price': '10'},
        ],
      ),
    ];

    when(() => parserFactory.createParser('csv')).thenReturn(parser);

    when(() => parser.parsePath(filePath))
        .thenAnswer((_) async => parsedSheets);

    when(() => inferSchemaUseCase.call(any(), any())).thenThrow(
      Exception('Invalid schema'),
    );

    /// ---------------- ACT & ASSERT ----------------

    await expectLater(
      service.prepareImport(
        file: ImportFile.fromPath(
          fileName: 'schema.csv',
          path: filePath,
        ),
      ),
      throwsA(
        isA<SchemaInferenceException>()
            .having((e) => e.code, 'code', 'schema_failed')
            .having((e) => e.message, 'message', contains('Products')),
      ),
    );

    verify(() => parserFactory.createParser('csv')).called(1);
    verify(() => parser.parsePath(filePath)).called(1);
    verify(() => inferSchemaUseCase.call(any(), 0)).called(1);
  });

  group('currency symbol detection', () {
    test('detects dominant currency symbol in a numeric column', () async {
      final parsedSheets = [
        ParsedSheet(
          name: 'Prices',
          rows: [
            {'price': r'$3.50', 'label': 'book'},
            {'price': r'$12.00', 'label': 'pen'},
            {'price': r'$7.99', 'label': 'ruler'},
          ],
        ),
      ];

      final columns = [
        _realColumn('price'),
        _textColumn('label'),
      ];

      when(() => parserFactory.createParser('csv')).thenReturn(parser);
      when(() => parser.parsePath('/tmp/prices.csv'))
          .thenAnswer((_) async => parsedSheets);
      when(() => inferSchemaUseCase.call(any(), any())).thenReturn(columns);

      final result = await service.prepareImport(
        file: ImportFile.fromPath(
          fileName: 'prices.csv',
          path: '/tmp/prices.csv',
        ),
      );

      expect(result.sheets.first.columnCurrencySymbols, {r'price': r'$'});
    });

    test('does not detect currency on text columns', () async {
      final parsedSheets = [
        ParsedSheet(
          name: 'Sheet1',
          rows: [
            {'tag': r'$sale', 'qty': '5'},
          ],
        ),
      ];

      final columns = [
        _textColumn('tag'),
        _realColumn('qty'),
      ];

      when(() => parserFactory.createParser('csv')).thenReturn(parser);
      when(() => parser.parsePath('/tmp/data.csv'))
          .thenAnswer((_) async => parsedSheets);
      when(() => inferSchemaUseCase.call(any(), any())).thenReturn(columns);

      final result = await service.prepareImport(
        file: ImportFile.fromPath(
          fileName: 'data.csv',
          path: '/tmp/data.csv',
        ),
      );

      // 'tag' is text → not detected; 'qty' has no symbol → not detected
      expect(result.sheets.first.columnCurrencySymbols, isEmpty);
    });

    test('returns empty map when no currency symbols found', () async {
      final parsedSheets = [
        ParsedSheet(
          name: 'Sheet1',
          rows: [
            {'amount': '100', 'count': '5'},
          ],
        ),
      ];

      final columns = [_realColumn('amount'), _realColumn('count')];

      when(() => parserFactory.createParser('csv')).thenReturn(parser);
      when(() => parser.parsePath('/tmp/clean.csv'))
          .thenAnswer((_) async => parsedSheets);
      when(() => inferSchemaUseCase.call(any(), any())).thenReturn(columns);

      final result = await service.prepareImport(
        file: ImportFile.fromPath(
          fileName: 'clean.csv',
          path: '/tmp/clean.csv',
        ),
      );

      expect(result.sheets.first.columnCurrencySymbols, isEmpty);
    });

    test('rejects symbol when fewer than 50% of cells carry it', () async {
      final parsedSheets = [
        ParsedSheet(
          name: 'Sheet1',
          rows: [
            {'price': r'$10'},
            {'price': '20'},
            {'price': '30'},
            {'price': '40'},
          ],
        ),
      ];

      final columns = [_realColumn('price')];

      when(() => parserFactory.createParser('csv')).thenReturn(parser);
      when(() => parser.parsePath('/tmp/mixed.csv'))
          .thenAnswer((_) async => parsedSheets);
      when(() => inferSchemaUseCase.call(any(), any())).thenReturn(columns);

      final result = await service.prepareImport(
        file: ImportFile.fromPath(
          fileName: 'mixed.csv',
          path: '/tmp/mixed.csv',
        ),
      );

      expect(result.sheets.first.columnCurrencySymbols, isEmpty);
    });
  });

  test('should throw if file has no extension', () async {
    /// ---------------- ARRANGE ----------------

    final filePath = 'file_without_extension';

    /// ---------------- ACT & ASSERT ----------------

    await expectLater(
      service.prepareImport(
        file: ImportFile.fromPath(
          fileName: filePath,
          path: filePath,
        ),
      ),
      throwsA(isA<InvalidFileExtensionException>()),
    );
  });
}

DatasetColumn _realColumn(String name) => DatasetColumn(
      id: 0,
      datasetTableId: 0,
      originalName: name,
      dbName: name,
      declaredType: ColumnType.real,
      inferredType: ColumnType.real,
      nullable: true,
      statsJson: null,
    );

DatasetColumn _textColumn(String name) => DatasetColumn(
      id: 0,
      datasetTableId: 0,
      originalName: name,
      dbName: name,
      declaredType: ColumnType.text,
      inferredType: ColumnType.text,
      nullable: true,
      statsJson: null,
    );
