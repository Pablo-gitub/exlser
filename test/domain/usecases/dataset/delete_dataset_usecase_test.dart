import 'package:exel_category/domain/repositories/datasets_repository.dart';
import 'package:exel_category/domain/repositories/schema_repository.dart';
import 'package:exel_category/domain/usecases/dataset/delete_dataset_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDatasetsRepository extends Mock implements DatasetsRepository {}

class MockSchemaRepository extends Mock implements SchemaRepository {}

void main() {
  group('DeleteDatasetUseCase', () {
    late MockDatasetsRepository datasetsRepository;
    late MockSchemaRepository schemaRepository;
    late DeleteDatasetUseCase useCase;

    setUp(() {
      datasetsRepository = MockDatasetsRepository();
      schemaRepository = MockSchemaRepository();
      useCase = DeleteDatasetUseCase(
        datasetsRepository: datasetsRepository,
        schemaRepository: schemaRepository,
      );
    });

    test('should delete schema and then dataset from repositories', () async {
      /// Arrange
      const datasetId = 123;

      when(() => schemaRepository.deleteSchemaForDataset(any()))
          .thenAnswer((_) async {});
      when(() => datasetsRepository.deleteDataset(any()))
          .thenAnswer((_) async {});

      /// Act
      await useCase(datasetId);

      /// Assert
      // Verifichiamo che entrambi i metodi vengano chiamati con l'ID corretto
      verify(() => schemaRepository.deleteSchemaForDataset(datasetId))
          .called(1);
      verify(() => datasetsRepository.deleteDataset(datasetId)).called(1);

      // Opzionale ma consigliato: assicurarsi che vengano chiamati in questo preciso ordine (non lasciare file "orfani")
      // Tuttavia, in questo caso l'assenza di eccezioni convalida implicitamente che siano eseguiti.
    });

    /// TODO:
    /// Test per gestire cosa succede se l'eliminazione dello schema fallisce (es. DatabaseException)
  });
}
