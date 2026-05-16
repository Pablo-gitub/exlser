import 'dart:io';

import 'package:exel_category/application/dto/import_file.dart';
import 'package:exel_category/application/usecases/file/save_uploaded_file_usecase.dart';
import 'package:exel_category/data/datasources/file_datasource.dart';
import 'package:exel_category/domain/value_objects/dataset_file_storage_mode.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('SaveUploadedFileUseCase', () {
    late SaveUploadedFileUseCase useCase;
    Directory? tempDirectory;

    setUp(() {
      useCase = const SaveUploadedFileUseCase(
        datasource: FileDatasource(),
      );
    });

    tearDown(() async {
      final directory = tempDirectory;
      if (directory != null && await directory.exists()) {
        await directory.delete(recursive: true);
      }
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

    test('should copy a path source reference when saveLocally is true',
        () async {
      final importedAt = DateTime(2026, 1, 2);
      tempDirectory = await Directory.systemTemp.createTemp(
        'exel_category_save_file_',
      );
      final sourceFile = File(p.join(tempDirectory!.path, 'source.csv'));
      await sourceFile.writeAsBytes([1, 2, 3]);
      final storageRoot = Directory(p.join(tempDirectory!.path, 'storage'));

      useCase = SaveUploadedFileUseCase(
        datasource: FileDatasource(
          storageRootPath: storageRoot.path,
        ),
      );

      final reference = await useCase(
        ImportFile.fromPath(
          fileName: 'data.csv',
          path: sourceFile.path,
        ),
        importedAt: importedAt,
        saveLocally: true,
      );

      expect(reference.fileName, 'data.csv');
      expect(reference.storageMode, DatasetFileStorageMode.pathAndCopy);
      expect(reference.originalPath, sourceFile.path);
      expect(reference.storedPath, isNotNull);
      expect(reference.importedAt, importedAt);
      expect(reference.fileSize, 3);
      expect(await File(reference.storedPath!).readAsBytes(), [1, 2, 3]);
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

    test(
        'should keep byte source references temporary even if saveLocally is true',
        () async {
      final reference = await useCase(
        ImportFile.fromBytes(
          fileName: 'upload.xlsx',
          bytes: [1, 2, 3, 4],
        ),
        saveLocally: true,
      );

      expect(reference.storageMode, DatasetFileStorageMode.webTemporary);
      expect(reference.storedPath, isNull);
      expect(reference.fileSize, 4);
    });
  });
}
