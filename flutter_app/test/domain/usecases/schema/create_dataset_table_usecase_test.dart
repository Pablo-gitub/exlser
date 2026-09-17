import 'package:exlser/domain/entities/dataset_table.dart';
import 'package:exlser/domain/repositories/schema_repository.dart';
import 'package:exlser/domain/usecases/schema/create_dataset_table_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Mock repository used to isolate use case behavior.
class MockSchemaRepository extends Mock implements SchemaRepository {}

/// Fake entity required by mocktail when using `any()`.
class FakeDatasetTable extends Fake implements DatasetTable {}

void main() {
  /// Register fallback values required by mocktail.
  setUpAll(() {
    registerFallbackValue(FakeDatasetTable());
  });

  group('CreateDatasetTableUseCase', () {
    late MockSchemaRepository repository;
    late CreateDatasetTableUseCase useCase;

    setUp(() {
      /// Fresh mocked repository before each test.
      repository = MockSchemaRepository();

      /// Create use case with mocked dependency.
      useCase = CreateDatasetTableUseCase(
        repository: repository,
      );

      /// The use case reads the dataset's tables to keep names unique.
      when(() => repository.getTablesForDataset(any()))
          .thenAnswer((_) async => []);
    });

    test(
      'should create dataset table correctly',
      () async {
        /// Arrange
        /// Repository returns persisted table metadata.
        when(
          () => repository.createDatasetTable(any()),
        ).thenAnswer(
          (_) async => DatasetTable(
            id: 1,
            datasetId: 10,
            sheetNameOriginal: 'Sales',
            sqlTableName: 'sales',
            rowCount: 100,
            colCount: 4,
          ),
        );

        /// Act
        final result = await useCase(
          datasetId: 10,
          sheetName: 'Sales',
          rowCount: 100,
          colCount: 4,
        );

        /// Assert
        expect(result.id, 1);
        expect(result.datasetId, 10);
        expect(result.sheetNameOriginal, 'Sales');
        expect(result.sqlTableName, 'sales');
        expect(result.rowCount, 100);
        expect(result.colCount, 4);
      },
    );

    test(
      'should sanitize sql table name',
      () async {
        /// Arrange
        when(
          () => repository.createDatasetTable(any()),
        ).thenAnswer((invocation) async {
          final table = invocation.positionalArguments.first as DatasetTable;
          return table.copyWith(id: 1);
        });

        /// Act
        final result = await useCase(
          datasetId: 10,
          sheetName: 'Sales Report 2025',
          rowCount: 50,
          colCount: 3,
        );

        /// Assert
        expect(
          result.sqlTableName,
          'ds_10_sales_report_2025',
        );
      },
    );

    test(
      'should call repository createDatasetTable once',
      () async {
        /// Arrange
        when(
          () => repository.createDatasetTable(any()),
        ).thenAnswer(
          (_) async => DatasetTable(
            id: 1,
            datasetId: 10,
            sheetNameOriginal: 'Sales',
            sqlTableName: 'sales',
            rowCount: 100,
            colCount: 4,
          ),
        );

        /// Act
        await useCase(
          datasetId: 10,
          sheetName: 'Sales',
          rowCount: 100,
          colCount: 4,
        );

        /// Assert
        verify(
          () => repository.createDatasetTable(any()),
        ).called(1);
      },
    );

    test('suffixes a name that collides with an existing table', () async {
      when(() => repository.getTablesForDataset(10)).thenAnswer(
        (_) async => [
          DatasetTable(
            id: 1,
            datasetId: 10,
            sheetNameOriginal: 'Sales 2024',
            sqlTableName: 'ds_10_sales_2024',
            rowCount: 10,
            colCount: 2,
          ),
        ],
      );
      when(() => repository.createDatasetTable(any())).thenAnswer(
        (invocation) async =>
            (invocation.positionalArguments.first as DatasetTable)
                .copyWith(id: 2),
      );

      // Sanitizes to the same identifier as the stored one.
      final result = await useCase(
        datasetId: 10,
        sheetName: 'Sales-2024',
        rowCount: 5,
        colCount: 2,
      );

      expect(result.sqlTableName, 'ds_10_sales_2024_1');
      expect(result.sheetNameOriginal, 'Sales-2024');
    });

    test('strips invalid characters and keeps the name usable unquoted',
        () async {
      when(() => repository.createDatasetTable(any())).thenAnswer(
        (invocation) async =>
            (invocation.positionalArguments.first as DatasetTable)
                .copyWith(id: 1),
      );

      final result = await useCase(
        datasetId: 3,
        sheetName: 'Prezzi (€) "2024"; DROP TABLE x--',
        rowCount: 1,
        colCount: 1,
      );

      expect(result.sqlTableName, matches(RegExp(r'^[a-z][a-z0-9_]*$')));
      expect(result.sqlTableName, startsWith('ds_3_prezzi'));
    });

    test('keeps a unicode or emoji-only sheet name addressable', () async {
      when(() => repository.createDatasetTable(any())).thenAnswer(
        (invocation) async =>
            (invocation.positionalArguments.first as DatasetTable)
                .copyWith(id: 1),
      );

      final result = await useCase(
        datasetId: 4,
        sheetName: '📊',
        rowCount: 1,
        colCount: 1,
      );

      expect(result.sqlTableName, 'ds_4');
      expect(result.sheetNameOriginal, '📊');
    });

    test('rejects an empty sheet name before touching the repository',
        () async {
      expect(
        () => useCase(
          datasetId: 1,
          sheetName: '   ',
          rowCount: 1,
          colCount: 1,
        ),
        throwsA(isA<Exception>()),
      );
      verifyNever(() => repository.createDatasetTable(any()));
    });
  });
}
