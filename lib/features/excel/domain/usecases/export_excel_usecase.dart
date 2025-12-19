// lib/features/excel/domain/usecases/export_excel_usecase.dart
import 'package:exel_category/features/excel/domain/entities/excel_data_entity.dart';
import 'package:exel_category/features/excel/domain/repositories/export_repository.dart';
import 'package:exel_category/core/usecases/usecase.dart';

class ExportParams {
  final List<ExcelDataEntity> filteredData;
  final List<String> columnOrder;

  const ExportParams({
    required this.filteredData,
    required this.columnOrder,
  });
}

class ExportExcelUseCase implements UseCase<void, ExportParams> {
  final ExportRepository repository;

  const ExportExcelUseCase(this.repository);

  @override
  Future<void> call(ExportParams params) {
    return repository.exportToExcel(params.filteredData, params.columnOrder);
  }
}
