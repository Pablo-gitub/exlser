// lib/features/excel/domain/usecases/get_filtered_data_usecase.dart
import 'package:exel_category/features/excel/domain/entities/excel_data_entity.dart';
import 'package:exel_category/features/excel/domain/entities/excel_filter_entity.dart';
import 'package:exel_category/features/excel/domain/repositories/excel_repository.dart';
import 'package:exel_category/core/usecases/usecase.dart';

class GetFilteredDataParams {
  final ExcelFilterEntity filters;
  final List<ExcelDataEntity> allElements;

  const GetFilteredDataParams({
    required this.filters,
    required this.allElements,
  });
}

class GetFilteredDataUseCase
    implements UseCase<List<ExcelDataEntity>, GetFilteredDataParams> {
  final ExcelRepository repository;

  const GetFilteredDataUseCase(this.repository);

  @override
  Future<List<ExcelDataEntity>> call(GetFilteredDataParams params) {
    return repository.getFilteredData(params.filters, params.allElements);
  }
}
