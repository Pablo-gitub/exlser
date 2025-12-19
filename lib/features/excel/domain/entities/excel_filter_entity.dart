// lib/features/excel/domain/entities/excel_filter_entity.dart

class ExcelFilterEntity {
  /// Map where the key = column name
  /// and the value = selected values for that column
  final Map<String, List<dynamic>> selectedFilters;

  const ExcelFilterEntity({
    required this.selectedFilters,
  });

  ExcelFilterEntity copyWith({
    Map<String, List<dynamic>>? selectedFilters,
  }) {
    return ExcelFilterEntity(
      selectedFilters: selectedFilters ?? this.selectedFilters,
    );
  }

  bool get isEmpty => selectedFilters.isEmpty;

  @override
  String toString() => 'ExcelFilterEntity(selectedFilters: $selectedFilters)';
}
