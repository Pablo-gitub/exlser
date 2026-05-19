import 'package:exel_category/application/services/export_data_service.dart';
import 'package:exel_category/domain/entities/dataset.dart';
import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/entities/dataset_table.dart';
import 'package:exel_category/domain/repositories/query_repository.dart';
import 'package:exel_category/domain/repositories/schema_repository.dart';
import 'package:exel_category/domain/usecases/export/export_csv_usecase.dart';
import 'package:exel_category/domain/usecases/export/export_excel_usecase.dart';
import 'package:exel_category/domain/usecases/export/export_json_usecase.dart';
import 'package:exel_category/domain/usecases/export/export_pdf_usecase.dart';
import 'package:exel_category/domain/usecases/export/export_sql_usecase.dart';
import 'package:exel_category/domain/usecases/query/apply_filters_usecase.dart';
import 'package:exel_category/domain/value_objects/column_type.dart';
import 'package:exel_category/domain/value_objects/dataset_filter.dart';
import 'package:exel_category/domain/value_objects/export_format.dart';
import 'package:exel_category/domain/value_objects/filter_operator.dart';
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
        applyFiltersUseCase: ApplyFiltersUseCase(repository: queryRepository),
        exportCsvUseCase: const ExportCsvUseCase(),
        exportExcelUseCase: const ExportExcelUseCase(),
        exportPdfUseCase: const ExportPdfUseCase(),
        exportSqlUseCase: const ExportSqlUseCase(),
        exportJsonUseCase: const ExportJsonUseCase(),
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

    test('exports current filtered table using visible columns only', () async {
      final dataset = _dataset();
      final table = _table(1, 'January', 'sales_2026');
      final productColumn = _column('Product', 'product');
      final brandColumn = _column('Brand', 'brand');

      when(() => queryRepository.queryWithFilter(
            tableName: any(named: 'tableName'),
            whereClause: any(named: 'whereClause'),
            arguments: any(named: 'arguments'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          )).thenAnswer(
        (invocation) async {
          final tableName = invocation.namedArguments[#tableName] as String;
          if (tableName == 'sales_2026_february') {
            return [
              {'product': 'Dunk', 'brand': 'Nike'},
            ];
          }

          return [
            {'product': 'Sk8-Hi', 'brand': 'Vans'},
          ];
        },
      );

      final files = await service.exportCurrentTable(
        dataset: dataset,
        table: table,
        visibleColumns: [brandColumn],
        filters: [
          DatasetFilter(
            column: productColumn,
            operator: FilterOperator.contains,
            value: 'Sk8',
          ),
        ],
        sort: null,
        format: ExportFormat.csv,
      );

      final csv = String.fromCharCodes(files.single.bytes);
      expect(csv, contains('Brand'));
      expect(csv, contains('Vans'));
      expect(csv, isNot(contains('Product')));
      expect(csv, isNot(contains('Sk8-Hi')));
      verify(() => queryRepository.queryWithFilter(
            tableName: 'sales_2026',
            whereClause: "(product LIKE ? ESCAPE '\\')",
            arguments: ['%Sk8%'],
            limit: null,
            offset: null,
          )).called(1);
    });

    test('exports selected sheets and applies each sheet filter state',
        () async {
      final dataset = _dataset();
      final januaryTable = _table(1, 'January', 'sales_2026');
      final otherTable = _table(2, 'February', 'sales_2026_february');
      final productColumn = _column('Product', 'product');
      final brandColumn = _column('Brand', 'brand');

      when(() => queryRepository.queryWithFilter(
            tableName: any(named: 'tableName'),
            whereClause: any(named: 'whereClause'),
            arguments: any(named: 'arguments'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          )).thenAnswer(
        (invocation) async {
          final tableName = invocation.namedArguments[#tableName] as String;

          if (tableName == otherTable.sqlTableName) {
            return [
              {'product': 'Dunk', 'brand': 'Nike'},
            ];
          }

          return [
            {'product': 'Sk8-Hi', 'brand': 'Vans'},
          ];
        },
      );

      final files = await service.exportSelectedTables(
        dataset: dataset,
        selectedTables: [januaryTable, otherTable],
        visibleColumnsByTableId: {
          januaryTable.id: [brandColumn],
          otherTable.id: [productColumn],
        },
        filtersByTableId: {
          januaryTable.id: [
            DatasetFilter(
              column: productColumn,
              operator: FilterOperator.contains,
              value: 'Sk8',
            ),
          ],
          otherTable.id: [
            DatasetFilter(
              column: brandColumn,
              operator: FilterOperator.contains,
              value: 'Nike',
            ),
          ],
        },
        format: ExportFormat.json,
      );

      final json = String.fromCharCodes(files.single.bytes);

      expect(files.single.extension, 'json');
      expect(json, contains('"January"'));
      expect(json, contains('"Brand": "Vans"'));
      expect(json, isNot(contains('"Product": "Sk8-Hi"')));
      expect(json, contains('"February"'));
      expect(json, contains('"Product": "Dunk"'));
      verify(() => queryRepository.queryWithFilter(
            tableName: 'sales_2026',
            whereClause: "(product LIKE ? ESCAPE '\\')",
            arguments: ['%Sk8%'],
            limit: null,
            offset: null,
          )).called(1);
      verify(() => queryRepository.queryWithFilter(
            tableName: 'sales_2026_february',
            whereClause: "(brand LIKE ? ESCAPE '\\')",
            arguments: ['%Nike%'],
            limit: null,
            offset: null,
          )).called(1);
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
