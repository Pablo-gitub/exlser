import 'package:exel_category/domain/entities/dataset_table.dart';
import 'package:exel_category/domain/repositories/schema_repository.dart';
import 'package:exel_category/domain/usecases/schema/create_dataset_table_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Mock repository used to isolate use case behavior.
class MockSchemaRepository extends Mock
    implements SchemaRepository {}

/// Fake entity required by mocktail when using `any()`.
class FakeDatasetTable extends Fake
    implements DatasetTable {}

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
        ).thenAnswer(
          (_) async => DatasetTable(
            id: 1,
            datasetId: 10,
            sheetNameOriginal: 'Sales Report 2025',
            sqlTableName: 'sales_report_2025',
            rowCount: 50,
            colCount: 3,
          ),
        );

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
          'sales_report_2025',
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

    /// TODO:
    /// Add edge case tests:
    /// - invalid SQL characters in sheet name
    /// - SQL reserved keywords
    /// - duplicated sheet names
    /// - very long sheet names
    /// - unicode sheet names
  });
}