import 'package:exlser/domain/entities/dataset_file.dart';
import 'package:exlser/domain/entities/source_file_reference.dart';
import 'package:exlser/domain/repositories/dataset_file_repository.dart';
import 'package:exlser/domain/usecases/dataset/register_dataset_file_usecase.dart';
import 'package:exlser/domain/value_objects/dataset_file_storage_mode.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDatasetFileRepository extends Mock implements DatasetFileRepository {}

class FakeDatasetFile extends Fake implements DatasetFile {}

void main() {
  group('RegisterDatasetFileUseCase', () {
    late MockDatasetFileRepository repository;
    late RegisterDatasetFileUseCase useCase;

    setUpAll(() {
      registerFallbackValue(FakeDatasetFile());
    });

    setUp(() {
      repository = MockDatasetFileRepository();
      useCase = RegisterDatasetFileUseCase(repository: repository);
    });

    test('should register source file reference for dataset', () async {
      final importedAt = DateTime(2026, 1, 2);

      final sourceFileReference = SourceFileReference(
        fileName: 'data.csv',
        storageMode: DatasetFileStorageMode.path,
        originalPath: '/tmp/data.csv',
        importedAt: importedAt,
        fileSize: 120,
      );

      final persisted = DatasetFile(
        id: 9,
        datasetId: 4,
        storageMode: DatasetFileStorageMode.path,
        originalPath: '/tmp/data.csv',
        importedAt: importedAt,
        fileSize: 120,
      );

      when(() => repository.createDatasetFile(any()))
          .thenAnswer((_) async => persisted);

      final result = await useCase(
        datasetId: 4,
        sourceFileReference: sourceFileReference,
      );

      final captured = verify(
        () => repository.createDatasetFile(captureAny()),
      ).captured.single as DatasetFile;

      expect(captured.id, 0);
      expect(captured.datasetId, 4);
      expect(captured.storageMode, DatasetFileStorageMode.path);
      expect(captured.originalPath, '/tmp/data.csv');
      expect(captured.importedAt, importedAt);
      expect(captured.fileSize, 120);
      expect(result, persisted);
    });

    test('should throw when dataset id is invalid', () async {
      final sourceFileReference = SourceFileReference(
        fileName: 'data.csv',
        storageMode: DatasetFileStorageMode.path,
        originalPath: '/tmp/data.csv',
        importedAt: DateTime(2026, 1, 2),
      );

      expect(
        () => useCase(
          datasetId: 0,
          sourceFileReference: sourceFileReference,
        ),
        throwsException,
      );

      verifyNever(() => repository.createDatasetFile(any()));
    });
  });
}
