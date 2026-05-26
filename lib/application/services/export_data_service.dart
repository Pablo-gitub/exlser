import 'package:exlser/domain/entities/dataset.dart';
import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/entities/dataset_table.dart';
import 'package:exlser/domain/entities/exported_file.dart';
import 'package:exlser/domain/repositories/query_repository.dart';
import 'package:exlser/domain/repositories/schema_repository.dart';
import 'package:exlser/domain/usecases/export/export_csv_usecase.dart';
import 'package:exlser/domain/usecases/export/export_dataset_data.dart';
import 'package:exlser/domain/usecases/export/export_excel_usecase.dart';
import 'package:exlser/domain/usecases/export/export_json_usecase.dart';
import 'package:exlser/domain/usecases/export/export_pdf_usecase.dart';
import 'package:exlser/domain/usecases/export/export_sql_usecase.dart';
import 'package:exlser/domain/usecases/query/apply_filters_usecase.dart';
import 'package:exlser/domain/value_objects/dataset_filter.dart';
import 'package:exlser/domain/value_objects/dataset_sort.dart';
import 'package:exlser/domain/value_objects/export_format.dart';
import 'package:exlser/domain/value_objects/pdf_export_layout.dart';

/// Application service responsible for exporting dataset data.
///
/// It supports both complete dataset exports and current-table exports. The
/// current-table flow exports every row matching the active filters and sort,
/// but only the columns currently visible in the workspace.
class ExportDataService {
  final SchemaRepository schemaRepository;
  final QueryRepository queryRepository;
  final ApplyFiltersUseCase applyFiltersUseCase;
  final ExportCsvUseCase exportCsvUseCase;
  final ExportExcelUseCase exportExcelUseCase;
  final ExportPdfUseCase exportPdfUseCase;
  final ExportSqlUseCase exportSqlUseCase;
  final ExportJsonUseCase exportJsonUseCase;

  const ExportDataService({
    required this.schemaRepository,
    required this.queryRepository,
    required this.applyFiltersUseCase,
    required this.exportCsvUseCase,
    required this.exportExcelUseCase,
    required this.exportPdfUseCase,
    required this.exportSqlUseCase,
    required this.exportJsonUseCase,
  });

  Future<List<ExportedFile>> exportDataset({
    required Dataset dataset,
    required ExportFormat format,
    PdfExportLayout pdfLayout = PdfExportLayout.table,
  }) async {
    final data = await _loadDatasetData(dataset);

    if (data.isEmpty) {
      throw StateError('Cannot export dataset without tables');
    }

    return _exportData(
      data,
      format,
      pdfLayout: pdfLayout,
    );
  }

  Future<List<ExportedFile>> exportCurrentTable({
    required Dataset dataset,
    required DatasetTable table,
    required List<DatasetColumn> visibleColumns,
    required List<DatasetFilter> filters,
    required DatasetSort? sort,
    required ExportFormat format,
    PdfExportLayout pdfLayout = PdfExportLayout.table,
  }) async {
    return exportSelectedTables(
      dataset: dataset,
      selectedTables: [table],
      visibleColumnsByTableId: {table.id: visibleColumns},
      filtersByTableId: {table.id: filters},
      sortByTableId: {table.id: sort},
      format: format,
      pdfLayout: pdfLayout,
    );
  }

  Future<List<ExportedFile>> exportSelectedTables({
    required Dataset dataset,
    required List<DatasetTable> selectedTables,
    required Map<int, List<DatasetColumn>> visibleColumnsByTableId,
    Map<int, List<DatasetFilter>> filtersByTableId = const {},
    Map<int, DatasetSort?> sortByTableId = const {},
    required ExportFormat format,
    PdfExportLayout pdfLayout = PdfExportLayout.table,
  }) async {
    if (selectedTables.isEmpty) {
      throw StateError('Cannot export without selected sheets');
    }

    final exportTables = <ExportTableData>[];

    for (final table in selectedTables) {
      final columns = visibleColumnsByTableId[table.id] ??
          await schemaRepository.getColumnsForTable(table.id);

      if (columns.isEmpty) {
        continue;
      }

      final filters = filtersByTableId[table.id] ?? const <DatasetFilter>[];
      final sort = sortByTableId[table.id];
      final rows = await _loadTableRows(
        table: table,
        filters: filters,
        sort: sort,
      );

      exportTables.add(
        ExportTableData(
          table: table,
          columns: columns,
          rows: rows,
        ),
      );
    }

    final data = ExportDatasetData(
      dataset: dataset,
      tables: exportTables,
    );

    if (data.isEmpty) {
      throw StateError('Cannot export dataset without readable sheets');
    }

    return _exportData(
      data,
      format,
      pdfLayout: pdfLayout,
    );
  }

  Future<List<Map<String, dynamic>>> _loadTableRows({
    required DatasetTable table,
    required List<DatasetFilter> filters,
    required DatasetSort? sort,
  }) {
    if (filters.isEmpty && sort == null) {
      return queryRepository.fetchRows(tableName: table.sqlTableName);
    }

    return applyFiltersUseCase.call(
      tableName: table.sqlTableName,
      filters: filters,
      sort: sort,
    );
  }

  Future<List<ExportedFile>> _exportData(
    ExportDatasetData data,
    ExportFormat format, {
    PdfExportLayout pdfLayout = PdfExportLayout.table,
  }) async {
    switch (format) {
      case ExportFormat.csv:
        return exportCsvUseCase(data);
      case ExportFormat.excel:
        return [exportExcelUseCase(data)];
      case ExportFormat.pdf:
        return [await exportPdfUseCase(data, layout: pdfLayout)];
      case ExportFormat.sql:
        return [exportSqlUseCase(data)];
      case ExportFormat.json:
        return [exportJsonUseCase(data)];
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
