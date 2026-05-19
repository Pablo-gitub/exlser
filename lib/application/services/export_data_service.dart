import 'package:exel_category/domain/entities/dataset.dart';
import 'package:exel_category/domain/entities/exported_file.dart';
import 'package:exel_category/domain/repositories/query_repository.dart';
import 'package:exel_category/domain/repositories/schema_repository.dart';
import 'package:exel_category/domain/usecases/export/export_csv_usecase.dart';
import 'package:exel_category/domain/usecases/export/export_dataset_data.dart';
import 'package:exel_category/domain/usecases/export/export_excel_usecase.dart';
import 'package:exel_category/domain/usecases/export/export_pdf_usecase.dart';
import 'package:exel_category/domain/usecases/export/export_sql_usecase.dart';
import 'package:exel_category/domain/value_objects/export_format.dart';

/// Application service responsible for exporting complete datasets.
///
/// The export is intentionally independent from the current table page: it
/// exports every dataset sheet with all rows, while the UI remains free to save
/// the generated files through the platform-specific file picker/downloader.
class ExportDataService {
  final SchemaRepository schemaRepository;
  final QueryRepository queryRepository;
  final ExportCsvUseCase exportCsvUseCase;
  final ExportExcelUseCase exportExcelUseCase;
  final ExportPdfUseCase exportPdfUseCase;
  final ExportSqlUseCase exportSqlUseCase;

  const ExportDataService({
    required this.schemaRepository,
    required this.queryRepository,
    required this.exportCsvUseCase,
    required this.exportExcelUseCase,
    required this.exportPdfUseCase,
    required this.exportSqlUseCase,
  });

  Future<List<ExportedFile>> exportDataset({
    required Dataset dataset,
    required ExportFormat format,
  }) async {
    final data = await _loadDatasetData(dataset);

    if (data.isEmpty) {
      throw StateError('Cannot export dataset without tables');
    }

    switch (format) {
      case ExportFormat.csv:
        return exportCsvUseCase(data);
      case ExportFormat.excel:
        return [exportExcelUseCase(data)];
      case ExportFormat.pdf:
        return [await exportPdfUseCase(data)];
      case ExportFormat.sql:
        return [exportSqlUseCase(data)];
    }
  }

  Future<ExportDatasetData> _loadDatasetData(Dataset dataset) async {
    final tables = await schemaRepository.getTablesForDataset(dataset.id);
    final exportTables = <ExportTableData>[];

    for (final table in tables) {
      final columns = await schemaRepository.getColumnsForTable(table.id);
      final rows = await queryRepository.fetchRows(
        tableName: table.sqlTableName,
      );

      exportTables.add(
        ExportTableData(
          table: table,
          columns: columns,
          rows: rows,
        ),
      );
    }

    return ExportDatasetData(
      dataset: dataset,
      tables: exportTables,
    );
  }
}
