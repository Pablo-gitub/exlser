import 'package:exel_category/domain/entities/dataset.dart';
import 'package:exel_category/domain/repositories/datasets_repository.dart';
import 'package:exel_category/domain/usecases/dataset/create_dataset_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Mock repository used to isolate the use case behavior.
class MockDatasetsRepository extends Mock
    implements DatasetsRepository {}

/// Fake entity required by mocktail when using `any()`.
class FakeDataset extends Fake implements Dataset {}

void main() {

  /// Register fallback values required by mocktail.
  setUpAll(() {
    registerFallbackValue(FakeDataset());
  });

  group('CreateDatasetUseCase', () {

    late MockDatasetsRepository repository;
    late CreateDatasetUseCase useCase;

    setUp(() {

      /// Fresh repository instance before each test.
      repository = MockDatasetsRepository();

      /// Create use case with mocked dependency.
      useCase = CreateDatasetUseCase(
        repository: repository,
      );
    });

    test(
      'should create dataset correctly',
      () async {

        /// Arrange
        /// Repository returns persisted dataset with generated id.
        when(() => repository.createDataset(any()))
            .thenAnswer(
          (_) async => Dataset(
            id: 1,
            name: 'Sales Report',
            sourceFileName: 'sales.xlsx',
            sourceFileHash: null,
            createdAt: 123456789,
            lastOpenedAt: null,
          ),
        );

        /// Act
        final result = await useCase(
          datasetName: 'Sales Report',
          sourceFileName: 'sales.xlsx',
        );

        /// Assert
        expect(result.id, 1);
        expect(result.name, 'Sales Report');
      },
    );

    test(
      'should trim dataset name',
      () async {
        final dataset = Dataset(
          id: 1,
          name: 'Sales Report',
          sourceFileName: 'sales.xlsx',
          sourceFileHash: null,
          createdAt: 123456789,
          lastOpenedAt: null,
        );

        when(
          () => repository.createDataset(any()),
        ).thenAnswer((_) async => dataset);

        final result = await useCase(
          datasetName: '   Sales Report   ',
          sourceFileName: 'sales.xlsx',
        );

        expect(result.name, 'Sales Report');

        final captured =
            verify(
              () => repository.createDataset(
                captureAny(),
              ),
            ).captured.single as Dataset;

        expect(captured.name, 'Sales Report');
      },
    );

    test(
      'should throw exception when dataset name is empty',
      () async {
        expect(
          () => useCase(
            datasetName: '   ',
            sourceFileName: 'sales.xlsx',
          ),
          throwsException,
        );
      },
    );

    test(
      'should call repository createDataset once',
      () async {
        final dataset = Dataset(
          id: 1,
          name: 'Sales Report',
          sourceFileName: 'sales.xlsx',
          sourceFileHash: null,
          createdAt: 123456789,
          lastOpenedAt: null,
        );

        when(
          () => repository.createDataset(any()),
        ).thenAnswer((_) async => dataset);

        await useCase(
          datasetName: 'Sales Report',
          sourceFileName: 'sales.xlsx',
        );

        verify(
          () => repository.createDataset(any()),
        ).called(1);
      },
    );

    /// TODO:
    /// Add edge case tests:
    /// - empty dataset name
    /// - whitespace-only dataset name
    /// - empty source file name
    /// - unicode dataset names
    /// - very long dataset names
    /// - duplicated dataset names
  });
}