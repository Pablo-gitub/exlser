// lib/features/excel/domain/repositories/export_repository.dart

import 'package:exel_category/features/excel/domain/entities/excel_data_entity.dart';

abstract class ExportRepository {
  /// Exports the filtered data to an Excel file.
  Future<void> exportToExcel(
    List<ExcelDataEntity> filteredData,
    List<String> columnOrder,
  );

  /// Exports to PDF.
  Future<void> exportToPdf(
    List<ExcelDataEntity> filteredData,
    List<String> columnOrder,
  );
}
