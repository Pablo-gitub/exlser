import 'package:exlser/domain/repositories/datasets_repository.dart';
import 'package:exlser/domain/usecases/dataset/update_dataset_ui_state_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDatasetsRepository extends Mock implements DatasetsRepository {}

void main() {
  group('UpdateDatasetUiStateUseCase', () {
    late MockDatasetsRepository repository;
    late UpdateDatasetUiStateUseCase useCase;

    setUp(() {
      repository = MockDatasetsRepository();
      useCase = UpdateDatasetUiStateUseCase(repository: repository);
    });

    test('should update dataset ui state', () async {
      when(() => repository.updateDatasetUiState(
            datasetId: 1,
            uiStateJson: '{"viewMode":"table"}',
          )).thenAnswer((_) async {});

      await useCase(
        datasetId: 1,
        uiStateJson: '{"viewMode":"table"}',
      );

      verify(() => repository.updateDatasetUiState(
            datasetId: 1,
            uiStateJson: '{"viewMode":"table"}',
          )).called(1);
    });

    test('should reject invalid input', () {
      expect(
        () => useCase(datasetId: 0, uiStateJson: '{}'),
        throwsArgumentError,
      );
      expect(
        () => useCase(datasetId: 1, uiStateJson: ' '),
        throwsArgumentError,
      );
    });
  });
}
