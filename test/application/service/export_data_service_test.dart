import 'package:exel_category/application/services/export_data_service.dart';
import 'package:exel_category/domain/entities/dataset.dart';
import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/entities/dataset_table.dart';
import 'package:exel_category/domain/repositories/query_repository.dart';
import 'package:exel_category/domain/repositories/schema_repository.dart';
import 'package:exel_category/domain/usecases/export/export_csv_usecase.dart';
import 'package:exel_category/domain/usecases/export/export_excel_usecase.dart';
import 'package:exel_category/domain/usecases/export/export_pdf_usecase.dart';
import 'package:exel_category/domain/usecases/export/export_sql_usecase.dart';
import 'package:exel_category/domain/value_objects/column_type.dart';
import 'package:exel_category/domain/value_objects/export_format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSchemaRepository extends Mock implements SchemaRepository {}

class MockQueryRepository extends Mock implements QueryRepository {}

void main() {
  group('ExportDataService', () {
    late MockSchemaRepository schemaRepository;
    late MockQueryRepository queryRepository;
    late ExportDataService service;

    setUp(() {
      schemaRepository = MockSchemaRepository();
      queryRepository = MockQueryRepository();
      service = ExportDataService(
        schemaRepository: schemaRepository,
        queryRepository: queryRepository,
        exportCsvUseCase: const ExportCsvUseCase(),
        exportExcelUseCase: const ExportExcelUseCase(),
        exportPdfUseCase: const ExportPdfUseCase(),
        exportSqlUseCase: const ExportSqlUseCase(),
      );
    });

    test('loads all dataset tables and exports CSV files', () async {
      final dataset = _dataset();
      final tables = [
        _table(1, 'January', 'sales_2026'),
        _table(2, 'February', 'sales_2026_february'),
      ];
      final columns = [
        _column('Product', 'product'),
      ];

      when(() => schemaRepository.getTablesForDataset(dataset.id))
          .thenAnswer((_) async => tables);
      when(() => schemaRepository.getColumnsForTable(any()))
          .thenAnswer((_) async => columns);
      when(() => queryRepository.fetchRows(
            tableName: any(named: 'tableName'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          )).thenAnswer(
        (_) async => [
          {'product': 'Vans'},
        ],
      );

      final files = await service.exportDataset(
        dataset: dataset,
        format: ExportFormat.csv,
      );

      expect(files, hasLength(2));
      expect(files.map((file) => file.extension), ['csv', 'csv']);
      verify(() => schemaRepository.getTablesForDataset(dataset.id)).called(1);
      verify(() => schemaRepository.getColumnsForTable(1)).called(1);
      verify(() => schemaRepository.getColumnsForTable(2)).called(1);
      verify(() => queryRepository.fetchRows(
            tableName: 'sales_2026',
            limit: null,
            offset: null,
          )).called(1);
      verify(() => queryRepository.fetchRows(
            tableName: 'sales_2026_february',
            limit: null,
            offset: null,
          )).called(1);
    });

    test('rejects exporting datasets without tables', () async {
      final dataset = _dataset();
      when(() => schemaRepository.getTablesForDataset(dataset.id))
          .thenAnswer((_) async => []);

      await expectLater(
        service.exportDataset(
          dataset: dataset,
          format: ExportFormat.sql,
        ),
        throwsStateError,
      );
    });
  });
}

Dataset _dataset() {
  return const Dataset(
    id: 1,
    name: 'Sales Dataset',
    sourceFileName: 'sales.xlsx',
    createdAt: 1,
  );
}

DatasetTable _table(int id, String sheetName, String sqlTableName) {
  return DatasetTable(
    id: id,
    datasetId: 1,
    sheetNameOriginal: sheetName,
    sqlTableName: sqlTableName,
    rowCount: 1,
    colCount: 1,
  );
}

DatasetColumn _column(String originalName, String dbName) {
  return DatasetColumn(
    id: 1,
    datasetTableId: 1,
    originalName: originalName,
    dbName: dbName,
    declaredType: ColumnType.text,
    inferredType: ColumnType.text,
    nullable: false,
  );
}
