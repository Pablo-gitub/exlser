// lib/features/excel/domain/usecases/export_pdf_usecase.dart
import 'package:exel_category/features/excel/domain/repositories/export_repository.dart';
import 'package:exel_category/core/usecases/usecase.dart';
import 'export_excel_usecase.dart'; // reuse ExportParams

class ExportPdfUseCase implements UseCase<void, ExportParams> {
  final ExportRepository repository;

  const ExportPdfUseCase(this.repository);

  @override
  Future<void> call(ExportParams params) {
    return repository.exportToPdf(params.filteredData, params.columnOrder);
  }
}
