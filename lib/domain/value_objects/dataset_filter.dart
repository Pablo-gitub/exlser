import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/value_objects/filter_operator.dart';

class DatasetFilter {
  final String id;
  final DatasetColumn column;
  final FilterOperator operator;
  final Object? value;
  final Object? secondValue;

  const DatasetFilter({
    this.id = '',
    required this.column,
    required this.operator,
    this.value,
    this.secondValue,
  });

  String get effectiveId {
    if (id.trim().isNotEmpty) {
      return id;
    }

    return [
      column.dbName,
      operator.name,
      value?.toString() ?? '',
      secondValue?.toString() ?? '',
    ].join(':');
  }

  bool get isValueMissing => _isMissing(value);

  bool get isSecondValueMissing => _isMissing(secondValue);

  DatasetFilter copyWith({
    String? id,
    DatasetColumn? column,
    FilterOperator? operator,
    Object? value = _notProvided,
    Object? secondValue = _notProvided,
  }) {
    return DatasetFilter(
      id: id ?? this.id,
      column: column ?? this.column,
      operator: operator ?? this.operator,
      value: identical(value, _notProvided) ? this.value : value,
      secondValue:
          identical(secondValue, _notProvided) ? this.secondValue : secondValue,
    );
  }
}

const Object _notProvided = Object();

bool _isMissing(Object? value) {
  if (value == null) {
    return true;
  }

  if (value is String) {
    return value.trim().isEmpty;
  }

  return false;
}
