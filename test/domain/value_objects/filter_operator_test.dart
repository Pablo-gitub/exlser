import 'package:exel_category/domain/value_objects/column_type.dart';
import 'package:exel_category/domain/value_objects/filter_operator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FilterOperator', () {
    test('should expose value requirements', () {
      expect(FilterOperator.contains.requiresValue, isTrue);
      expect(FilterOperator.between.requiresValue, isTrue);
      expect(FilterOperator.between.requiresSecondValue, isTrue);
      expect(FilterOperator.isEmpty.requiresValue, isFalse);
      expect(FilterOperator.isTrue.requiresValue, isFalse);
    });

    test('should validate text operators', () {
      expect(FilterOperator.contains.supportsType(ColumnType.text), isTrue);
      expect(FilterOperator.startsWith.supportsType(ColumnType.text), isTrue);
      expect(FilterOperator.greaterThan.supportsType(ColumnType.text), isFalse);
    });

    test('should validate numeric operators', () {
      expect(FilterOperator.between.supportsType(ColumnType.integer), isTrue);
      expect(FilterOperator.lessOrEqual.supportsType(ColumnType.real), isTrue);
      expect(FilterOperator.contains.supportsType(ColumnType.integer), isFalse);
    });

    test('should validate date and boolean operators', () {
      expect(FilterOperator.before.supportsType(ColumnType.date), isTrue);
      expect(FilterOperator.after.supportsType(ColumnType.date), isTrue);
      expect(FilterOperator.isTrue.supportsType(ColumnType.boolean), isTrue);
      expect(FilterOperator.contains.supportsType(ColumnType.boolean), isFalse);
    });
  });
}
