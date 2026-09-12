import 'package:exlser/domain/usecases/schema/detect_matrix_table_usecase.dart';
import 'package:exlser/domain/value_objects/column_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DetectMatrixTableUseCase detector;

  setUp(() {
    detector = DetectMatrixTableUseCase();
  });

  group('DetectMatrixTableUseCase', () {
    test('should return null for tables with fewer than 3 columns or 2 rows',
        () {
      expect(detector([]), isNull);
      expect(
          detector([
            {'a': '1'}
          ]),
          isNull);
      expect(
          detector([
            {'a': '1', 'b': '2'},
            {'a': '3', 'b': '4'},
          ]),
          isNull);
    });

    test('should detect monthly cross-tab matrix', () {
      final rows = [
        {'Product': 'Apples', 'Jan': '100', 'Feb': '120', 'Mar': '95'},
        {'Product': 'Bananas', 'Jan': '200', 'Feb': '210', 'Mar': '180'},
        {'Product': 'Oranges', 'Jan': '80', 'Feb': '90', 'Mar': '85'},
      ];

      final result = detector(rows);

      expect(result, isNotNull);
      expect(result!.idColumnNames, ['Product']);
      expect(result.valueColumnNames, ['Jan', 'Feb', 'Mar']);
      expect(result.suggestedDimensionName, 'Month');
      expect(result.suggestedValueName, 'Value');
      expect(result.inferredValueType, ColumnType.integer);
    });

    test('should detect yearly cross-tab matrix with real decimal numbers', () {
      final rows = [
        {'Country': 'Italy', '2020': '10.5', '2021': '12.3', '2022': '14.0'},
        {'Country': 'France', '2020': '15.2', '2021': '16.1', '2022': '18.4'},
      ];

      final result = detector(rows);

      expect(result, isNotNull);
      expect(result!.idColumnNames, ['Country']);
      expect(result.valueColumnNames, ['2020', '2021', '2022']);
      expect(result.suggestedDimensionName, 'Year');
      expect(result.inferredValueType, ColumnType.real);
    });

    test('should detect quarterly matrix with multi-column ID prefix', () {
      final rows = [
        {
          'Region': 'North',
          'Product': 'A',
          'Q1': '50',
          'Q2': '60',
          'Q3': '70',
          'Q4': '80'
        },
        {
          'Region': 'North',
          'Product': 'B',
          'Q1': '30',
          'Q2': '35',
          'Q3': '40',
          'Q4': '45'
        },
        {
          'Region': 'South',
          'Product': 'A',
          'Q1': '20',
          'Q2': '25',
          'Q3': '22',
          'Q4': '30'
        },
      ];

      final result = detector(rows);

      expect(result, isNotNull);
      expect(result!.idColumnNames, ['Region', 'Product']);
      expect(result.valueColumnNames, ['Q1', 'Q2', 'Q3', 'Q4']);
      expect(result.suggestedDimensionName, 'Quarter');
      expect(result.inferredValueType, ColumnType.integer);
    });

    test('should detect matrix with boolean values', () {
      final rows = [
        {
          'Feature': 'Dark Mode',
          'iOS': 'true',
          'Android': 'true',
          'Web': 'false'
        },
        {
          'Feature': 'Offline Sync',
          'iOS': 'true',
          'Android': 'false',
          'Web': 'false'
        },
      ];

      final result = detector(rows);

      expect(result, isNotNull);
      expect(result!.idColumnNames, ['Feature']);
      expect(result.valueColumnNames, ['iOS', 'Android', 'Web']);
      expect(result.inferredValueType, ColumnType.boolean);
    });

    test('should not trigger on regular relational tables', () {
      final rows = [
        {'id': '1', 'name': 'Alice', 'city': 'Rome', 'age': '28'},
        {'id': '2', 'name': 'Bob', 'city': 'Milan', 'age': '34'},
        {'id': '3', 'name': 'Charlie', 'city': 'Turin', 'age': '45'},
      ];

      final result = detector(rows);

      expect(result, isNull);
    });
  });
}
