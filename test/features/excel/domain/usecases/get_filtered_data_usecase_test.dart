import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:exel_category/features/excel/domain/entities/excel_data_entity.dart';
import 'package:exel_category/features/excel/domain/entities/excel_filter_entity.dart';
import 'package:exel_category/features/excel/domain/repositories/excel_repository.dart';
import 'package:exel_category/features/excel/domain/usecases/get_filtered_data_usecase.dart';

class MockExcelRepository extends Mock implements ExcelRepository {}

void main() {
  late MockExcelRepository repo;
  late GetFilteredDataUseCase usecase;

  setUp(() {
    repo = MockExcelRepository();
    usecase = GetFilteredDataUseCase(repo);
  });

  test('should get filtered data via repository', () async {
    const filters = ExcelFilterEntity(selectedFilters: {
      'Type': ['Dog']
    });

    final all = [
      const ExcelDataEntity(values: {'Type': 'Dog'}),
      const ExcelDataEntity(values: {'Type': 'Cat'}),
    ];

    final filtered = [
      const ExcelDataEntity(values: {'Type': 'Dog'}),
    ];

    when(() => repo.getFilteredData(filters, all))
        .thenAnswer((_) async => filtered);

    final result = await usecase(GetFilteredDataParams(
      filters: filters,
      allElements: all,
    ));

    expect(result, filtered);
    verify(() => repo.getFilteredData(filters, all)).called(1);
  });
}
