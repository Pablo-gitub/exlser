import 'package:exel_category/application/dto/import_file.dart';
import 'package:exel_category/application/usecases/file/save_uploaded_file_usecase.dart';
import 'package:exel_category/data/datasources/file_datasource.dart';
import 'package:exel_category/domain/value_objects/dataset_file_storage_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SaveUploadedFileUseCase', () {
    late SaveUploadedFileUseCase useCase;

    setUp(() {
      useCase = const SaveUploadedFileUseCase(
        datasource: FileDatasource(),
      );
    });

    test('should prepare a path source reference', () async {
      final importedAt = DateTime(2026, 1, 2);

      final reference = await useCase(
        ImportFile.fromPath(
          fileName: 'data.csv',
          path: '/tmp/data.csv',
        ),
        importedAt: importedAt,
      );

      expect(reference.fileName, 'data.csv');
      expect(reference.storageMode, DatasetFileStorageMode.path);
      expect(reference.originalPath, '/tmp/data.csv');
      expect(reference.storedPath, isNull);
      expect(reference.importedAt, importedAt);
      expect(reference.fileSize, isNull);
    });

    test('should prepare a byte source reference', () async {
      final importedAt = DateTime(2026, 1, 2);

      final reference = await useCase(
        ImportFile.fromBytes(
          fileName: 'upload.xlsx',
          bytes: [1, 2, 3, 4],
        ),
        importedAt: importedAt,
      );

      expect(reference.fileName, 'upload.xlsx');
      expect(reference.storageMode, DatasetFileStorageMode.webTemporary);
      expect(reference.originalPath, isNull);
      expect(reference.storedPath, isNull);
      expect(reference.importedAt, importedAt);
      expect(reference.fileSize, 4);
    });
  });
}
