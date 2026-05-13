import 'package:exel_category/domain/entities/source_file_reference.dart';
import 'package:exel_category/domain/value_objects/dataset_file_storage_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('should convert source file reference to dataset file metadata', () {
    final importedAt = DateTime(2026, 1, 2, 3, 4, 5);

    final reference = SourceFileReference(
      fileName: 'data.csv',
      storageMode: DatasetFileStorageMode.path,
      originalPath: '/tmp/data.csv',
      importedAt: importedAt,
      fileSize: 120,
    );

    final datasetFile = reference.toDatasetFile(datasetId: 42);

    expect(datasetFile.id, 0);
    expect(datasetFile.datasetId, 42);
    expect(datasetFile.storageMode, DatasetFileStorageMode.path);
    expect(datasetFile.originalPath, '/tmp/data.csv');
    expect(datasetFile.storedPath, isNull);
    expect(datasetFile.importedAt, importedAt);
    expect(datasetFile.fileSize, 120);
  });
}
