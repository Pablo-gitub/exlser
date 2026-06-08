import 'package:exlser/domain/entities/dataset.dart';
import 'package:exlser/domain/repositories/datasets_repository.dart';
import 'package:exlser/domain/usecases/dataset/get_datasets_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDatasetsRepository extends Mock implements DatasetsRepository {}

void main() {
  group('GetDatasetsUseCase', () {
    late MockDatasetsRepository repository;
    late GetDatasetsUseCase useCase;

    setUp(() {
      repository = MockDatasetsRepository();
      useCase = GetDatasetsUseCase(repository: repository);
    });

    test('should return list of datasets from repository', () async {
      /// Arrange
      final datasets = [
        Dataset(
          id: 1,
          name: 'Dataset 1',
          sourceFileName: 'file1.csv',
          sourceFileHash: null,
          createdAt: 1000,
          lastOpenedAt: null,
        ),
        Dataset(
          id: 2,
          name: 'Dataset 2',
          sourceFileName: 'file2.xlsx',
          sourceFileHash: null,
          createdAt: 2000,
          lastOpenedAt: null,
        ),
      ];

      when(() => repository.getAllDatasets()).thenAnswer((_) async => datasets);

      /// Act
      final result = await useCase();

      /// Assert
      expect(result, equals(datasets));
      verify(() => repository.getAllDatasets()).called(1);
    });
  });
}
