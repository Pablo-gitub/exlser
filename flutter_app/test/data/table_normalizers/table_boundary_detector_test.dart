//test/data/table_normalizers/table_boundary_detector_test.dart

import 'package:exlser/data/adapters/table_normalizers/table_boundary_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TableBoundaryDetector.columnToLetter', () {
    test('converts basic 0-indexed column indices to Excel letters', () {
      expect(TableBoundaryDetector.columnToLetter(0), 'A');
      expect(TableBoundaryDetector.columnToLetter(1), 'B');
      expect(TableBoundaryDetector.columnToLetter(25), 'Z');
      expect(TableBoundaryDetector.columnToLetter(26), 'AA');
      expect(TableBoundaryDetector.columnToLetter(27), 'AB');
      expect(TableBoundaryDetector.columnToLetter(51), 'AZ');
      expect(TableBoundaryDetector.columnToLetter(52), 'BA');
      expect(TableBoundaryDetector.columnToLetter(701), 'ZZ');
      expect(TableBoundaryDetector.columnToLetter(702), 'AAA');
    });
  });

  group('TableBoundaryDetector.detect', () {
    test('returns empty list for empty or whitespace-only grids', () {
      expect(TableBoundaryDetector.detect([]), isEmpty);
      expect(TableBoundaryDetector.detect([[]]), isEmpty);
      expect(
        TableBoundaryDetector.detect([
          ['', null, '   '],
          [null, ''],
        ]),
        isEmpty,
      );
    });

    test('detects a single standard table at top-left', () {
      final grid = [
        ['ID', 'Name', 'Age'],
        ['1', 'Alice', '30'],
        ['2', 'Bob', '25'],
      ];

      final blocks = TableBoundaryDetector.detect(grid);

      expect(blocks, hasLength(1));
      final table = blocks.first;
      expect(table.startRow, 0);
      expect(table.startCol, 0);
      expect(table.endRow, 2);
      expect(table.endCol, 2);
      expect(table.cellRange, 'A1:C3');
      expect(table.rowCount, 3);
      expect(table.colCount, 3);
      expect(table.detectedTitle, isNull);
      expect(table.suggestedTableName(fallbackBaseName: 'Sheet1'), 'Sheet1');
      expect(table.rows, [
        ['ID', 'Name', 'Age'],
        ['1', 'Alice', '30'],
        ['2', 'Bob', '25'],
      ]);
    });

    test('detects single table with leading empty rows and columns', () {
      final grid = [
        ['', '', '', ''],
        ['', '', '', ''],
        ['', 'Code', 'Product'],
        ['', 'P1', 'Keyboard'],
        ['', 'P2', 'Mouse'],
      ];

      final blocks = TableBoundaryDetector.detect(grid);

      expect(blocks, hasLength(1));
      final table = blocks.first;
      expect(table.startRow, 2);
      expect(table.startCol, 1);
      expect(table.endRow, 4);
      expect(table.endCol, 2);
      expect(table.cellRange, 'B3:C5');
      expect(table.rowCount, 3);
      expect(table.colCount, 2);
      expect(table.rows.first, ['Code', 'Product']);
    });

    test('detects two vertically stacked tables separated by an empty row', () {
      final grid = [
        ['ID', 'User'],
        ['1', 'Alice'],
        ['2', 'Bob'],
        ['', ''], // Blank row separator
        ['Code', 'Role'],
        ['R1', 'Admin'],
        ['R2', 'Viewer'],
      ];

      final blocks = TableBoundaryDetector.detect(grid);

      expect(blocks, hasLength(2));

      final first = blocks[0];
      expect(first.cellRange, 'A1:B3');
      expect(first.rows, [
        ['ID', 'User'],
        ['1', 'Alice'],
        ['2', 'Bob'],
      ]);

      final second = blocks[1];
      expect(second.cellRange, 'A5:B7');
      expect(second.rows, [
        ['Code', 'Role'],
        ['R1', 'Admin'],
        ['R2', 'Viewer'],
      ]);
    });

    test(
        'detects two horizontally side-by-side tables with different row counts',
        () {
      // Table 1 (cols 0-1, rows 0-4), Col 2 is empty, Table 2 (cols 3-4, rows 0-2)
      final grid = [
        ['ID', 'Item', '', 'EmpId', 'Name'],
        ['1', 'Pen', '', 'E1', 'John'],
        ['2', 'Pencil', '', 'E2', 'Sara'],
        ['3', 'Eraser', '', '', ''],
        ['4', 'Ruler', '', '', ''],
      ];

      final blocks = TableBoundaryDetector.detect(grid);

      expect(blocks, hasLength(2));

      final table1 = blocks[0];
      expect(table1.cellRange, 'A1:B5');
      expect(table1.rowCount, 5);
      expect(table1.colCount, 2);
      expect(table1.rows.first, ['ID', 'Item']);

      final table2 = blocks[1];
      expect(table2.cellRange, 'D1:E3');
      expect(table2.rowCount, 3);
      expect(table2.colCount, 2);
      expect(table2.rows.first, ['EmpId', 'Name']);
    });

    test('extracts title from isolated cell directly above a table', () {
      final grid = [
        ['Quarterly Sales', '', ''],
        ['', '', ''], // Blank row
        ['Qtr', 'Revenue', 'Profit'],
        ['Q1', '1000', '200'],
        ['Q2', '1200', '250'],
      ];

      final blocks = TableBoundaryDetector.detect(grid);

      expect(blocks, hasLength(1));
      final table = blocks.first;
      expect(table.detectedTitle, 'Quarterly Sales');
      expect(table.suggestedTableName(fallbackBaseName: 'Sheet1'),
          'Quarterly Sales');
      expect(table.startRow, 2);
      expect(table.cellRange, 'A3:C5');
      expect(table.rows.first, ['Qtr', 'Revenue', 'Profit']);
    });

    test('extracts merged banner title on the very first row of a table block',
        () {
      final grid = [
        ['Employee Directory', '', ''], // 1 cell with text, 2 empty
        ['EmpId', 'Full Name', 'Department'], // 3 cells with text
        ['E01', 'Alice Green', 'Engineering'],
        ['E02', 'Bob White', 'Marketing'],
      ];

      final blocks = TableBoundaryDetector.detect(grid);

      expect(blocks, hasLength(1));
      final table = blocks.first;
      expect(table.detectedTitle, 'Employee Directory');
      expect(table.suggestedTableName(), 'Employee Directory');
      expect(table.startRow, 1);
      expect(table.cellRange, 'A2:C4');
      expect(table.rows.first, ['EmpId', 'Full Name', 'Department']);
      expect(table.rowCount, 3);
    });

    test('retains internal empty/missing cells without splitting', () {
      final grid = [
        ['ID', 'Name', 'Notes', 'Score'],
        ['1', 'Alice', '', '95'],
        ['2', 'Bob', 'Honor', ''],
        ['3', 'Charlie', '', '88'],
      ];

      final blocks = TableBoundaryDetector.detect(grid);

      expect(blocks, hasLength(1));
      final table = blocks.first;
      expect(table.cellRange, 'A1:D4');
      expect(table.rowCount, 4);
      expect(table.colCount, 4);
      expect(table.rows[1], ['1', 'Alice', '', '95']);
      expect(table.rows[2], ['2', 'Bob', 'Honor', '']);
    });

    test('ignores isolated single-cell noise far away from tables', () {
      final grid = [
        ['ID', 'Val'],
        ['1', '10'],
        ['2', '20'],
        ['', ''],
        ['', ''],
        ['', ''],
        ['', '', '', '', 'Confidential note'], // Far away noise
      ];

      final blocks = TableBoundaryDetector.detect(grid);

      expect(blocks, hasLength(1));
      expect(blocks.first.cellRange, 'A1:B3');
    });

    test('segments a 2x2 quadrant of four distinct tables', () {
      final grid = [
        ['T1_A', 'T1_B', '', 'T2_A', 'T2_B'],
        ['1', '2', '', '10', '20'],
        ['', '', '', '', ''], // Horizontal gap
        ['T3_A', 'T3_B', '', 'T4_A', 'T4_B'],
        ['100', '200', '', '1000', '2000'],
      ];

      final blocks = TableBoundaryDetector.detect(grid);

      expect(blocks, hasLength(4));
      expect(blocks[0].cellRange, 'A1:B2');
      expect(blocks[1].cellRange, 'D1:E2');
      expect(blocks[2].cellRange, 'A4:B5');
      expect(blocks[3].cellRange, 'D4:E5');
    });

    test('pads jagged rows to consistent column count', () {
      final grid = [
        ['Col1', 'Col2', 'Col3'],
        ['A'], // Shorter row
        ['B', 'C', 'D'],
      ];

      final blocks = TableBoundaryDetector.detect(grid);

      expect(blocks, hasLength(1));
      final table = blocks.first;
      expect(table.colCount, 3);
      expect(table.rows[1], ['A', '', '']);
    });
    test(
        'segments a grid that splits on every other row without exhausting the '
        'stack', () {
      // One blank row between every pair of data rows: as a recursion this was
      // one stack frame per blank row.
      final grid = <List<dynamic>>[];
      for (var i = 0; i < 2500; i++) {
        grid.add(['row$i', i]);
        grid.add(const <dynamic>[]);
      }

      final blocks = TableBoundaryDetector.detect(grid);

      expect(blocks, isNotEmpty);
      expect(
        blocks.length,
        lessThanOrEqualTo(TableBoundaryDetector.maxDetectedBlocks),
      );
      // Content is never dropped, only grouped more coarsely once the block
      // budget is spent.
      final totalRows = blocks.fold<int>(0, (sum, b) => sum + b.rows.length);
      expect(totalRows, greaterThan(0));
    });

    test('caps the number of detected blocks on a sparse grid', () {
      // A diagonal of isolated cells would otherwise split indefinitely.
      final grid = <List<dynamic>>[];
      for (var i = 0; i < 600; i++) {
        final row = List<dynamic>.filled(600, '');
        row[i] = 'x$i';
        grid.add(row);
      }

      final blocks = TableBoundaryDetector.detect(grid);

      expect(
        blocks.length,
        lessThanOrEqualTo(TableBoundaryDetector.maxDetectedBlocks),
      );
    });
  });
}
