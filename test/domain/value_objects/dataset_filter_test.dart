import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/value_objects/column_type.dart';
import 'package:exel_category/domain/value_objects/dataset_filter.dart';
import 'package:exel_category/domain/value_objects/filter_operator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DatasetFilter', () {
    test('should build fallback effective id from filter values', () {
      final filter = DatasetFilter(
        column: _column(),
        operator: FilterOperator.contains,
        value: 'book',
      );

      expect(filter.effectiveId, 'product:contains:book:');
    });

    test('should prefer explicit id', () {
      final filter = DatasetFilter(
        id: 'filter-1',
        column: _column(),
        operator: FilterOperator.contains,
        value: 'book',
      );

      expect(filter.effectiveId, 'filter-1');
    });

    test('copyWith should allow nullable values to be cleared', () {
      final filter = DatasetFilter(
        column: _column(),
        operator: FilterOperator.between,
        value: 10,
        secondValue: 20,
      );

      final updatedFilter = filter.copyWith(
        operator: FilterOperator.isEmpty,
        value: null,
        secondValue: null,
      );

      expect(updatedFilter.operator, FilterOperator.isEmpty);
      expect(updatedFilter.value, isNull);
      expect(updatedFilter.secondValue, isNull);
    });
  });
}

DatasetColumn _column() {
  return const DatasetColumn(
    id: 1,
    datasetTableId: 1,
    originalName: 'Product',
    dbName: 'product',
    declaredType: ColumnType.text,
    inferredType: ColumnType.text,
    nullable: true,
  );
}
