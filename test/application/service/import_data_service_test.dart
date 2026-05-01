import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:exel_category/application/services/import_data_service.dart';
import 'package:exel_category/data/adapters/parsers/parser_factory.dart';
import 'package:exel_category/data/adapters/parsers/spreadsheet_parser.dart';
import 'package:exel_category/domain/entities/parsed_sheet.dart';
import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/usecases/schema/infer_schema_usecase.dart';
import 'package:exel_category/domain/value_objects/column_type.dart';

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

    final filePath = 'test.xlsx';

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

    when(() => parserFactory.createParser('xlsx'))
        .thenReturn(parser);

    when(() => parser.parse(filePath))
        .thenAnswer((_) async => parsedSheets);

    when(() => inferSchemaUseCase.call(any(), any()))
        .thenReturn(columns);

    /// ---------------- ACT ----------------

    final result = await service.prepareImport(
      filePath: filePath,
    );

    /// ---------------- ASSERT ----------------

    verify(() => parserFactory.createParser('xlsx')).called(1);
    verify(() => parser.parse(filePath)).called(1);
    verify(() => inferSchemaUseCase.call(any(), 0)).called(1);

    expect(result.length, 1);
    expect(result.first.sheet, parsedSheets.first);
    expect(result.first.columns, columns);
  });

  test('should handle csv files correctly', () async {
    /// ---------------- ARRANGE ----------------

    final filePath = 'data.csv';

    when(() => parserFactory.createParser('csv'))
        .thenReturn(parser);

    when(() => parser.parse(filePath))
        .thenAnswer((_) async => []);

    /// Anche senza righe, inferSchema non viene chiamato
    /// perché non ci sono sheet

    /// ---------------- ACT ----------------

    final result = await service.prepareImport(
      filePath: filePath,
    );

    /// ---------------- ASSERT ----------------

    verify(() => parserFactory.createParser('csv')).called(1);
    verify(() => parser.parse(filePath)).called(1);

    expect(result, isEmpty);
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