import 'package:exel_category/data/datasources/file_datasource.dart';
import 'package:exel_category/domain/value_objects/dataset_file_storage_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FileDatasource', () {
    late FileDatasource datasource;

    setUp(() {
      datasource = const FileDatasource();
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
  });
}
