import 'package:exel_category/application/dto/import_file.dart';
import 'package:exel_category/application/exceptions/import_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ImportFile', () {
    test('fromPath should normalize file name and path', () {
      final file = ImportFile.fromPath(
        fileName: ' data.csv ',
        path: ' /tmp/data.csv ',
      );

      expect(file.fileName, 'data.csv');
      expect(file.path, '/tmp/data.csv');
      expect(file.bytes, isNull);
      expect(file.hasPath, isTrue);
      expect(file.hasBytes, isFalse);
    });

    test('fromBytes should normalize file name and protect bytes', () {
      final sourceBytes = [1, 2, 3];

      final file = ImportFile.fromBytes(
        fileName: ' upload.xlsx ',
        bytes: sourceBytes,
      );

      sourceBytes.add(4);

      expect(file.fileName, 'upload.xlsx');
      expect(file.bytes, [1, 2, 3]);
      expect(file.path, isNull);
      expect(file.hasBytes, isTrue);
      expect(file.hasPath, isFalse);
    });

    test('should throw structured error when file name is empty', () {
      expect(
        () => ImportFile.fromPath(
          fileName: ' ',
          path: '/tmp/data.csv',
        ),
        throwsA(
          isA<InvalidImportFileException>().having(
            (e) => e.code,
            'code',
            'empty_file_name',
          ),
        ),
      );
    });

    test('should throw structured error when path is empty', () {
      expect(
        () => ImportFile.fromPath(
          fileName: 'data.csv',
          path: ' ',
        ),
        throwsA(
          isA<InvalidImportFileException>().having(
            (e) => e.code,
            'code',
            'empty_file_path',
          ),
        ),
      );
    });

    test('should throw structured error when bytes are empty', () {
      expect(
        () => ImportFile.fromBytes(
          fileName: 'data.csv',
          bytes: const [],
        ),
        throwsA(
          isA<InvalidImportFileException>().having(
            (e) => e.code,
            'code',
            'empty_file_bytes',
          ),
        ),
      );
    });
  });
}
