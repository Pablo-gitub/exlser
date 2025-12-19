// lib/features/excel/domain/entities/excel_data_entity.dart

class ExcelDataEntity {
  final Map<String, dynamic> values;

  const ExcelDataEntity({
    required this.values,
  });

  dynamic operator [](String key) => values[key];

  ExcelDataEntity copyWith({
    Map<String, dynamic>? values,
  }) {
    return ExcelDataEntity(
      values: values ?? this.values,
    );
  }

  @override
  String toString() => 'ExcelDataEntity(values: $values)';
}
