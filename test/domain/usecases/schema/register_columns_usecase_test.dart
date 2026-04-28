import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/repositories/schema_repository.dart';
import 'package:exel_category/domain/usecases/schema/register_columns_usecase.dart';
import 'package:exel_category/domain/value_objects/column_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Mock repository used to isolate use case behavior.
class MockSchemaRepository extends Mock
    implements SchemaRepository {}

/// Fake entity required by mocktail when using `any()`.
class FakeDatasetColumn extends Fake
    implements DatasetColumn {}

void main() {

  /// Register fallback values required by mocktail.
  setUpAll(() {
    registerFallbackValue(FakeDatasetColumn());
    registerFallbackValue(<DatasetColumn>[]);
  });

  group('RegisterColumnsUseCase', () {

    late MockSchemaRepository repository;
    late RegisterColumnsUseCase useCase;

    setUp(() {

      /// Fresh mocked repository before each test.
      repository = MockSchemaRepository();

      /// Create use case with mocked dependency.
      useCase = RegisterColumnsUseCase(
        repository: repository,
      );
    });

    test(
      'should register columns correctly',
      () async {

        /// Arrange
        final columns = [
          DatasetColumn(
            id: 0,
            datasetTableId: 0,
            originalName: 'price',
            dbName: 'price',
            declaredType: ColumnType.real,
            inferredType: ColumnType.real,
            nullable: false,
            statsJson: null,
          ),
          DatasetColumn(
            id: 0,
            datasetTableId: 0,
            originalName: 'quantity',
            dbName: 'quantity',
            declaredType: ColumnType.integer,
            inferredType: ColumnType.integer,
            nullable: false,
            statsJson: null,
          ),
        ];

        when(
          () => repository.createColumns(any()),
        ).thenAnswer((_) async {});

        /// Act
        await useCase(
          datasetTableId: 10,
          columns: columns,
        );

        /// Assert
        verify(
          () => repository.createColumns(any()),
        ).called(1);
      },
    );

    test(
      'should assign datasetTableId to all columns',
      () async {

        /// Arrange
        final columns = [
          DatasetColumn(
            id: 0,
            datasetTableId: 0,
            originalName: 'price',
            dbName: 'price',
            declaredType: ColumnType.real,
            inferredType: ColumnType.real,
            nullable: false,
            statsJson: null,
          ),
        ];

        when(
          () => repository.createColumns(any()),
        ).thenAnswer((_) async {});

        /// Act
        await useCase(
          datasetTableId: 25,
          columns: columns,
        );

        /// Assert
        final captured =
            verify(
              () => repository.createColumns(
                captureAny(),
              ),
            ).captured.first as List<DatasetColumn>;

        expect(
          captured.first.datasetTableId,
          25,
        );
      },
    );

    test(
      'should preserve column metadata',
      () async {

        /// Arrange
        final columns = [
          DatasetColumn(
            id: 0,
            datasetTableId: 0,
            originalName: 'created_at',
            dbName: 'created_at',
            declaredType: ColumnType.date,
            inferredType: ColumnType.date,
            nullable: true,
            statsJson: '{"min":"2024-01-01"}',
          ),
        ];

        when(
          () => repository.createColumns(any()),
        ).thenAnswer((_) async {});

        /// Act
        await useCase(
          datasetTableId: 99,
          columns: columns,
        );

        /// Assert
        final captured =
            verify(
              () => repository.createColumns(
                captureAny(),
              ),
            ).captured.first as List<DatasetColumn>;

        expect(
          captured.first.originalName,
          'created_at',
        );

        expect(
          captured.first.declaredType,
          ColumnType.date,
        );

        expect(
          captured.first.nullable,
          true,
        );

        expect(
          captured.first.statsJson,
          '{"min":"2024-01-01"}',
        );
      },
    );
  });
}