// lib/features/excel/domain/usecases/read_excel_usecase.dart

import 'package:exel_category/features/excel/domain/entities/excel_data_entity.dart';
import 'package:exel_category/features/excel/domain/repositories/excel_repository.dart';
import 'package:exel_category/core/usecases/usecase.dart';

class ReadExcelUseCase implements UseCase<List<ExcelDataEntity>, NoParams> {
  final ExcelRepository repository;

  const ReadExcelUseCase(this.repository);

  @override
  Future<List<ExcelDataEntity>> call(NoParams params) {
    return repository.readExcelFile();
  }
}
