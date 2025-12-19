// lib/features/excel/domain/usecases/apply_filters_usecase.dart

import 'package:exel_category/features/excel/domain/entities/excel_filter_entity.dart';

class ApplyFiltersParams {
  final ExcelFilterEntity current;
  final String column;
  final dynamic value;
  final bool selected; // true = add, false = remove

  const ApplyFiltersParams({
    required this.current,
    required this.column,
    required this.value,
    required this.selected,
  });
}

class ApplyFiltersUseCase {
  ExcelFilterEntity call(ApplyFiltersParams params) {
    final Map<String, List<dynamic>> next =
        Map<String, List<dynamic>>.from(params.current.selectedFilters);

    final list = List<dynamic>.from(next[params.column] ?? []);

    if (params.selected) {
      if (!list.contains(params.value)) list.add(params.value);
      next[params.column] = list;
    } else {
      list.remove(params.value);
      if (list.isEmpty) {
        next.remove(params.column);
      } else {
        next[params.column] = list;
      }
    }

    return ExcelFilterEntity(selectedFilters: next);
  }
}
