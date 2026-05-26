import 'dart:io';

import 'package:exlser/data/datasources/file_datasource.dart';
import 'package:exlser/domain/value_objects/dataset_file_storage_mode.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('FileDatasource', () {
    late FileDatasource datasource;
    Directory? tempDirectory;

    setUp(() {
      datasource = const FileDatasource();
    });

    tearDown(() async {
      final directory = tempDirectory;
      if (directory != null && await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    test('should reference a path-based import', () async {
      final importedAt = DateTime(2026, 1, 2);

      final reference = await datasource.referencePath(
        fileName: 'data.csv',
        path: '/tmp/data.csv',
        importedAt: importedAt,
      );

      expect(reference.fileName, 'data.csv');
      expect(reference.storageMode, DatasetFileStorageMode.path);
      expect(reference.originalPath, '/tmp/data.csv');
      expect(reference.storedPath, isNull);
      expect(reference.importedAt, importedAt);
      expect(reference.fileSize, isNull);
    });

    test('should reference a byte-based import as web temporary', () async {
      final importedAt = DateTime(2026, 1, 2);

      final reference = await datasource.referenceBytes(
        fileName: 'upload.xlsx',
        bytes: [1, 2, 3],
        importedAt: importedAt,
      );

      expect(reference.fileName, 'upload.xlsx');
      expect(reference.storageMode, DatasetFileStorageMode.webTemporary);
      expect(reference.originalPath, isNull);
      expect(reference.storedPath, isNull);
      expect(reference.importedAt, importedAt);
      expect(reference.fileSize, 3);
    });

    test('should copy a path-based import into app storage', () async {
      final importedAt = DateTime(2026, 1, 2);
      tempDirectory = await Directory.systemTemp.createTemp(
        'exel_category_file_datasource_',
      );
      final sourceFile = File(p.join(tempDirectory!.path, 'source.csv'));
      await sourceFile.writeAsBytes([1, 2, 3, 4]);
      final storageRoot = Directory(p.join(tempDirectory!.path, 'storage'));

      datasource = FileDatasource(
        storageRootPath: storageRoot.path,
      );

      final reference = await datasource.copyPath(
        fileName: 'data.csv',
        path: sourceFile.path,
        importedAt: importedAt,
      );

      expect(reference.fileName, 'data.csv');
      expect(reference.storageMode, DatasetFileStorageMode.pathAndCopy);
      expect(reference.originalPath, sourceFile.path);
      expect(reference.storedPath, isNotNull);
      expect(reference.importedAt, importedAt);
      expect(reference.fileSize, 4);

      final copiedFile = File(reference.storedPath!);
      expect(await copiedFile.exists(), true);
      expect(await copiedFile.readAsBytes(), [1, 2, 3, 4]);
      expect(
        reference.storedPath,
        p.join(storageRoot.path, 'imports', 'data.csv'),
      );
    });

    test('should avoid overwriting copied files with the same name', () async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'exel_category_file_datasource_',
      );
      final sourceFile = File(p.join(tempDirectory!.path, 'source.csv'));
      await sourceFile.writeAsString('content');
      final storageRoot = Directory(p.join(tempDirectory!.path, 'storage'));

      datasource = FileDatasource(
        storageRootPath: storageRoot.path,
      );

      final first = await datasource.copyPath(
        fileName: 'data.csv',
        path: sourceFile.path,
      );
      final second = await datasource.copyPath(
        fileName: 'data.csv',
        path: sourceFile.path,
      );

      expect(first.storedPath, isNot(second.storedPath));
      expect(
        second.storedPath,
        p.join(storageRoot.path, 'imports', 'data_1.csv'),
      );
    });

    test('should throw when copying a missing source file', () async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'exel_category_file_datasource_',
      );
      datasource = FileDatasource(
        storageRootPath: tempDirectory!.path,
      );

      expect(
        () => datasource.copyPath(
          fileName: 'missing.csv',
          path: p.join(tempDirectory!.path, 'missing.csv'),
        ),
        throwsException,
      );
    });
  });
}
