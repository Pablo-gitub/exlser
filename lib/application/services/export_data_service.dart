import 'package:exel_category/domain/entities/dataset.dart';
import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/entities/dataset_table.dart';
import 'package:exel_category/domain/entities/exported_file.dart';
import 'package:exel_category/domain/repositories/query_repository.dart';
import 'package:exel_category/domain/repositories/schema_repository.dart';
import 'package:exel_category/domain/usecases/export/export_csv_usecase.dart';
import 'package:exel_category/domain/usecases/export/export_dataset_data.dart';
import 'package:exel_category/domain/usecases/export/export_excel_usecase.dart';
import 'package:exel_category/domain/usecases/export/export_pdf_usecase.dart';
import 'package:exel_category/domain/usecases/export/export_sql_usecase.dart';
import 'package:exel_category/domain/usecases/query/apply_filters_usecase.dart';
import 'package:exel_category/domain/value_objects/dataset_filter.dart';
import 'package:exel_category/domain/value_objects/dataset_sort.dart';
import 'package:exel_category/domain/value_objects/export_format.dart';

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

  const ExportDataService({
    required this.schemaRepository,
    required this.queryRepository,
    required this.applyFiltersUseCase,
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

    return _exportData(data, format);
  }

  Future<List<ExportedFile>> exportCurrentTable({
    required Dataset dataset,
    required DatasetTable table,
    required List<DatasetColumn> visibleColumns,
    required List<DatasetFilter> filters,
    required DatasetSort? sort,
    required ExportFormat format,
  }) async {
    if (visibleColumns.isEmpty) {
      throw StateError('Cannot export without visible columns');
    }

    final rows = filters.isEmpty && sort == null
        ? await queryRepository.fetchRows(tableName: table.sqlTableName)
        : await applyFiltersUseCase.call(
            tableName: table.sqlTableName,
            filters: filters,
            sort: sort,
          );

    final data = ExportDatasetData(
      dataset: dataset,
      tables: [
        ExportTableData(
          table: table,
          columns: visibleColumns,
          rows: rows,
        ),
      ],
    );

    return _exportData(data, format);
  }

  Future<List<ExportedFile>> _exportData(
    ExportDatasetData data,
    ExportFormat format,
  ) async {
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
