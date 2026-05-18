import 'package:exel_category/domain/value_objects/column_type.dart';

enum FilterOperator {
  contains,
  equals,
  notEquals,
  startsWith,
  endsWith,
  greaterThan,
  greaterOrEqual,
  lessThan,
  lessOrEqual,
  between,
  on,
  before,
  after,
  isEmpty,
  isNotEmpty,
  isTrue,
  isFalse;

  bool get requiresValue {
    return switch (this) {
      FilterOperator.isEmpty ||
      FilterOperator.isNotEmpty ||
      FilterOperator.isTrue ||
      FilterOperator.isFalse =>
        false,
      FilterOperator.between => true,
      _ => true,
    };
  }

  bool get requiresSecondValue => this == FilterOperator.between;

  bool supportsType(ColumnType type) {
    return switch (type) {
      ColumnType.text => _textOperators.contains(this),
      ColumnType.integer || ColumnType.real => _numericOperators.contains(this),
      ColumnType.date => _dateOperators.contains(this),
      ColumnType.boolean => _booleanOperators.contains(this),
    };
  }
}

const _textOperators = {
  FilterOperator.contains,
  FilterOperator.equals,
  FilterOperator.notEquals,
  FilterOperator.startsWith,
  FilterOperator.endsWith,
  FilterOperator.isEmpty,
  FilterOperator.isNotEmpty,
};

const _numericOperators = {
  FilterOperator.equals,
  FilterOperator.notEquals,
  FilterOperator.greaterThan,
  FilterOperator.greaterOrEqual,
  FilterOperator.lessThan,
  FilterOperator.lessOrEqual,
  FilterOperator.between,
  FilterOperator.isEmpty,
  FilterOperator.isNotEmpty,
};

const _dateOperators = {
  FilterOperator.equals,
  FilterOperator.notEquals,
  FilterOperator.on,
  FilterOperator.before,
  FilterOperator.after,
  FilterOperator.between,
  FilterOperator.isEmpty,
  FilterOperator.isNotEmpty,
};

const _booleanOperators = {
  FilterOperator.equals,
  FilterOperator.isTrue,
  FilterOperator.isFalse,
  FilterOperator.isEmpty,
  FilterOperator.isNotEmpty,
};
