import 'dart:convert';

import 'package:excel_community/excel_community.dart';
import 'package:exel_category/domain/entities/dataset.dart';
import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/entities/dataset_table.dart';
import 'package:exel_category/domain/usecases/export/export_csv_usecase.dart';
import 'package:exel_category/domain/usecases/export/export_dataset_data.dart';
import 'package:exel_category/domain/usecases/export/export_excel_usecase.dart';
import 'package:exel_category/domain/usecases/export/export_json_usecase.dart';
import 'package:exel_category/domain/usecases/export/export_pdf_usecase.dart';
import 'package:exel_category/domain/usecases/export/export_sql_usecase.dart';
import 'package:exel_category/domain/value_objects/column_type.dart';
import 'package:exel_category/domain/value_objects/export_format.dart';
import 'package:exel_category/domain/value_objects/pdf_export_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('export use cases', () {
    test('exports one CSV file for each dataset table', () {
      final result = const ExportCsvUseCase()(_exportData());

      expect(result, hasLength(2));
      expect(result.first.name, 'sales_dataset_january');
      expect(result.first.extension, ExportFormat.csv.extension);
      expect(utf8.decode(result.first.bytes), contains('Product,Total'));
      expect(utf8.decode(result.first.bytes), contains('Vans,120.5'));
    });

    test('exports Excel workbook with dataset sheets', () {
      final result = const ExportExcelUseCase()(_exportData());

      expect(result.extension, ExportFormat.excel.extension);
      expect(result.bytes, isNotEmpty);

      final workbook = Excel.decodeBytes(result.bytes);
      expect(workbook.tables.keys, containsAll(['January', 'February']));
    });

    test('exports PDF bytes', () async {
      final result = await const ExportPdfUseCase()(_exportData());

      expect(result.extension, ExportFormat.pdf.extension);
      expect(utf8.decode(result.bytes.take(4).toList()), '%PDF');
    });

    test('exports PDF card layout bytes', () async {
      final result = await const ExportPdfUseCase()(
        _exportData(),
        layout: PdfExportLayout.cards,
      );

      expect(result.extension, ExportFormat.pdf.extension);
      expect(utf8.decode(result.bytes.take(4).toList()), '%PDF');
    });

    test('exports SQL schema and rows', () {
      final result = const ExportSqlUseCase()(_exportData(
        rows: [
          {'product': "O'Hara", 'total': 10},
        ],
      ));
      final sql = utf8.decode(result.bytes);

      expect(result.extension, ExportFormat.sql.extension);
      expect(sql, contains('CREATE TABLE "sales_2026"'));
      expect(sql, contains('"product" TEXT'));
      expect(sql, contains("'O''Hara'"));
    });

    test('exports JSON grouped by sheet name', () {
      final result = const ExportJsonUseCase()(_exportData());
      final json = jsonDecode(utf8.decode(result.bytes));

      expect(result.extension, ExportFormat.json.extension);
      expect(json['January'], isA<List<dynamic>>());
      expect(json['January'].first['Product'], 'Vans');
      expect(json['January'].first['Total'], 120.5);
      expect(json['February'].first['Product'], 'Nike');
    });
  });
}

ExportDatasetData _exportData({
  List<Map<String, dynamic>>? rows,
}) {
  final dataset = Dataset(
    id: 1,
    name: 'Sales Dataset',
    sourceFileName: 'sales.xlsx',
    createdAt: 1,
  );

  final columns = [
    _column('Product', 'product', ColumnType.text),
    _column('Total', 'total', ColumnType.real),
  ];

  return ExportDatasetData(
    dataset: dataset,
    tables: [
      ExportTableData(
        table: _table(1, 'January', 'sales_2026'),
        columns: columns,
        rows: rows ??
            [
              {'product': 'Vans', 'total': 120.5},
            ],
      ),
      ExportTableData(
        table: _table(2, 'February', 'sales_2026_february'),
        columns: columns,
        rows: [
          {'product': 'Nike', 'total': 90.0},
        ],
      ),
    ],
  );
}

DatasetTable _table(int id, String sheetName, String sqlTableName) {
  return DatasetTable(
    id: id,
    datasetId: 1,
    sheetNameOriginal: sheetName,
    sqlTableName: sqlTableName,
    rowCount: 1,
    colCount: 2,
  );
}

DatasetColumn _column(String originalName, String dbName, ColumnType type) {
  return DatasetColumn(
    id: 1,
    datasetTableId: 1,
    originalName: originalName,
    dbName: dbName,
    declaredType: type,
    inferredType: type,
    nullable: false,
  );
}
