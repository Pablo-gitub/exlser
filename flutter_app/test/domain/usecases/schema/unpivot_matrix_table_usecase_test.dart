import 'package:exlser/domain/entities/parsed_sheet.dart';
import 'package:exlser/domain/usecases/schema/detect_matrix_table_usecase.dart';
import 'package:exlser/domain/usecases/schema/unpivot_matrix_table_usecase.dart';
import 'package:exlser/domain/value_objects/column_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late UnpivotMatrixTableUseCase unpivotUseCase;

  setUp(() {
    unpivotUseCase = const UnpivotMatrixTableUseCase();
  });

  group('UnpivotMatrixTableUseCase', () {
    test('should transform wide matrix rows into long relational rows', () {
      final rows = [
        {'Product': 'Apples', 'Jan': '100', 'Feb': '120'},
        {'Product': 'Bananas', 'Jan': '200', 'Feb': '210'},
      ];

      final result = unpivotUseCase(
        rows: rows,
        idColumnNames: ['Product'],
        valueColumnNames: ['Jan', 'Feb'],
        dimensionColumnName: 'Month',
        valueColumnName: 'Quantity',
      );

      expect(result.length, 4);
      expect(
          result[0], {'Product': 'Apples', 'Month': 'Jan', 'Quantity': '100'});
      expect(
          result[1], {'Product': 'Apples', 'Month': 'Feb', 'Quantity': '120'});
      expect(
          result[2], {'Product': 'Bananas', 'Month': 'Jan', 'Quantity': '200'});
      expect(
          result[3], {'Product': 'Bananas', 'Month': 'Feb', 'Quantity': '210'});
    });

    test('should skip null and empty values when skipEmptyValues is true', () {
      final rows = [
        {'Product': 'Apples', 'Jan': '100', 'Feb': '', 'Mar': null},
        {'Product': 'Bananas', 'Jan': null, 'Feb': '210', 'Mar': '180'},
      ];

      final result = unpivotUseCase(
        rows: rows,
        idColumnNames: ['Product'],
        valueColumnNames: ['Jan', 'Feb', 'Mar'],
        dimensionColumnName: 'Month',
        valueColumnName: 'Quantity',
        skipEmptyValues: true,
      );

      expect(result.length, 3);
      expect(
          result[0], {'Product': 'Apples', 'Month': 'Jan', 'Quantity': '100'});
      expect(
          result[1], {'Product': 'Bananas', 'Month': 'Feb', 'Quantity': '210'});
      expect(
          result[2], {'Product': 'Bananas', 'Month': 'Mar', 'Quantity': '180'});
    });

    test('should preserve multi-column IDs', () {
      final rows = [
        {'Region': 'North', 'Product': 'A', '2020': '10', '2021': '15'},
      ];

      final result = unpivotUseCase(
        rows: rows,
        idColumnNames: ['Region', 'Product'],
        valueColumnNames: ['2020', '2021'],
        dimensionColumnName: 'Year',
        valueColumnName: 'Amount',
      );

      expect(result.length, 2);
      expect(result[0],
          {'Region': 'North', 'Product': 'A', 'Year': '2020', 'Amount': '10'});
      expect(result[1],
          {'Region': 'North', 'Product': 'A', 'Year': '2021', 'Amount': '15'});
    });

    test('should unpivot a ParsedSheet preserving sheet metadata', () {
      const originalSheet = ParsedSheet(
        name: 'SalesMatrix',
        sourceSheetName: 'Foglio1',
        cellRange: 'A1:C3',
        rows: [
          {'Item': 'Widget', 'Q1': '5', 'Q2': '10'},
        ],
      );

      const candidate = MatrixCandidate(
        idColumnNames: ['Item'],
        valueColumnNames: ['Q1', 'Q2'],
        suggestedDimensionName: 'Quarter',
        suggestedValueName: 'Revenue',
        inferredValueType: ColumnType.integer,
      );

      final unpivotedSheet = unpivotUseCase.unpivotSheet(
        originalSheet,
        candidate: candidate,
      );

      expect(unpivotedSheet.name, 'SalesMatrix');
      expect(unpivotedSheet.sourceSheetName, 'Foglio1');
      expect(unpivotedSheet.cellRange, 'A1:C3');
      expect(unpivotedSheet.rows.length, 2);
      expect(unpivotedSheet.rows.first['Quarter'], 'Q1');
      expect(unpivotedSheet.rows.first['Revenue'], '5');
    });
  });
}
