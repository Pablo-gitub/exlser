import 'package:exel_category/application/dto/confirmed_import.dart';
import 'package:exel_category/application/dto/prepared_import_result.dart';
import 'package:exel_category/application/dto/prepared_sheet.dart';
import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/entities/parsed_sheet.dart';
import 'package:exel_category/domain/entities/source_file_reference.dart';
import 'package:exel_category/domain/value_objects/column_type.dart';
import 'package:exel_category/domain/value_objects/dataset_file_storage_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConfirmedImport', () {
    test('should create confirmed import from prepared result', () {
      final sourceFileReference = SourceFileReference(
        fileName: 'sales.xlsx',
        storageMode: DatasetFileStorageMode.path,
        originalPath: '/tmp/sales.xlsx',
        importedAt: DateTime(2026, 1, 2),
      );
      final preparedResult = PreparedImportResult(
        fileName: 'sales.xlsx',
        fileExtension: 'xlsx',
        sheets: [
          PreparedSheet(
            sheet: ParsedSheet(
              name: 'Sheet1',
              rows: [
                {'product': 'book', 'price': '10'},
                {'product': 'pen', 'price': '2'},
              ],
            ),
            inferredColumns: [
              _column(originalName: 'product', dbName: 'product'),
              _column(
                originalName: 'price',
                dbName: 'price',
                type: ColumnType.real,
              ),
            ],
          ),
        ],
      );

      final confirmedImport = ConfirmedImport.fromPreparedResult(
        datasetName: 'Sales',
        preparedImport: preparedResult,
        sourceFileReference: sourceFileReference,
      );

      expect(confirmedImport.datasetName, 'Sales');
      expect(confirmedImport.sourceFileName, 'sales.xlsx');
      expect(confirmedImport.sourceFileReference, sourceFileReference);
      expect(confirmedImport.tableCount, 1);
      expect(confirmedImport.columnCount, 2);
      expect(confirmedImport.rowCount, 2);
      expect(confirmedImport.sheets.single.sheet.name, 'Sheet1');
      expect(
        confirmedImport.sheets.single.columns.map(
          (column) => column.declaredType,
        ),
        [ColumnType.text, ColumnType.real],
      );
    });
  });
}

DatasetColumn _column({
  required String originalName,
  required String dbName,
  ColumnType type = ColumnType.text,
}) {
  return DatasetColumn(
    id: 0,
    datasetTableId: 0,
    originalName: originalName,
    dbName: dbName,
    declaredType: type,
    inferredType: type,
    nullable: false,
  );
}
