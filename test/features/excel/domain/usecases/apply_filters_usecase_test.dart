import 'package:flutter_test/flutter_test.dart';

import 'package:exel_category/features/excel/domain/entities/excel_filter_entity.dart';
import 'package:exel_category/features/excel/domain/usecases/apply_filters_usecase.dart';

void main() {
  late ApplyFiltersUseCase usecase;

  setUp(() {
    usecase = ApplyFiltersUseCase();
  });

  test('should add a filter value', () {
    const current = ExcelFilterEntity(selectedFilters: {});

    final next = usecase(ApplyFiltersParams(
      current: current,
      column: 'Type',
      value: 'Dog',
      selected: true,
    ));

    expect(next.selectedFilters['Type'], ['Dog']);
  });

  test('should remove a filter value and delete column key if empty', () {
    const current = ExcelFilterEntity(selectedFilters: {
      'Type': ['Dog']
    });

    final next = usecase(ApplyFiltersParams(
      current: current,
      column: 'Type',
      value: 'Dog',
      selected: false,
    ));

    expect(next.selectedFilters.containsKey('Type'), false);
  });
}
