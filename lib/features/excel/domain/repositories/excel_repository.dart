// lib/features/excel/domain/repositories/excel_repository.dart

import 'package:exel_category/features/excel/domain/entities/excel_data_entity.dart';
import 'package:exel_category/features/excel/domain/entities/excel_filter_entity.dart';

abstract class ExcelRepository {
  /// Reads and parses an Excel file, converting it into a list of entities.
  Future<List<ExcelDataEntity>> readExcelFile();

  /// Returns a list of filtered entities based on the filter criteria.
  Future<List<ExcelDataEntity>> getFilteredData(
    ExcelFilterEntity filters,
    List<ExcelDataEntity> allElements,
  );
}
