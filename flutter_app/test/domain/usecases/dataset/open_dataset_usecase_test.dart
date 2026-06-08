import 'package:exlser/domain/entities/dataset.dart';
import 'package:exlser/domain/repositories/datasets_repository.dart';
import 'package:exlser/domain/usecases/dataset/open_dataset_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDatasetsRepository extends Mock implements DatasetsRepository {}

void main() {
  group('OpenDatasetUseCase', () {
    late MockDatasetsRepository repository;
    late OpenDatasetUseCase useCase;

    setUp(() {
      repository = MockDatasetsRepository();
      useCase = OpenDatasetUseCase(repository: repository);
    });

    test('should mark dataset as opened and return it', () async {
      final openedDataset = _dataset(lastOpenedAt: 2000);

      when(() => repository.markDatasetOpened(1)).thenAnswer((_) async {});
      when(() => repository.getDatasetById(1))
          .thenAnswer((_) async => openedDataset);

      final result = await useCase(1);

      expect(result, openedDataset);
      verifyInOrder([
        () => repository.markDatasetOpened(1),
        () => repository.getDatasetById(1),
      ]);
    });

    test('should throw when dataset id is invalid', () async {
      expect(
        () => useCase(0),
        throwsArgumentError,
      );

      verifyNever(() => repository.markDatasetOpened(any()));
      verifyNever(() => repository.getDatasetById(any()));
    });

    test('should throw when dataset is not found after opening', () async {
      when(() => repository.markDatasetOpened(1)).thenAnswer((_) async {});
      when(() => repository.getDatasetById(1)).thenAnswer((_) async => null);

      expect(
        () => useCase(1),
        throwsStateError,
      );
    });
  });
}

Dataset _dataset({
  int lastOpenedAt = 1000,
}) {
  return Dataset(
    id: 1,
    name: 'Sales',
    sourceFileName: 'sales.csv',
    createdAt: 500,
    lastOpenedAt: lastOpenedAt,
  );
}
