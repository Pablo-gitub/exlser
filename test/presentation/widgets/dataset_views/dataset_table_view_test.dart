import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/value_objects/column_type.dart';
import 'package:exlser/presentation/widgets/dataset_views/dataset_table_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DatasetTableView', () {
    testWidgets('shows column headers and row values', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: DatasetTableView(
            columns: [
              _column(originalName: 'Product', dbName: 'product'),
              _column(originalName: 'Price', dbName: 'price'),
            ],
            rows: const [
              {'product': 'Notebook', 'price': 12.5},
              {'product': 'Pen', 'price': 1},
            ],
          ),
        ),
      );

      expect(find.text('Product'), findsOneWidget);
      expect(find.text('Price'), findsOneWidget);
      expect(find.text('Notebook'), findsOneWidget);
      expect(find.text('12.5'), findsOneWidget);
      expect(find.text('Pen'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('does not render null or blank values as text', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: DatasetTableView(
            columns: [
              _column(originalName: 'Product', dbName: 'product'),
              _column(originalName: 'Notes', dbName: 'notes'),
            ],
            rows: const [
              {'product': null, 'notes': '   '},
            ],
          ),
        ),
      );

      expect(find.text('null'), findsNothing);
      expect(find.text('   '), findsNothing);
    });

    testWidgets('enables horizontal and vertical scrolling', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: SizedBox(
            width: 320,
            height: 280,
            child: DatasetTableView(
              columns: [
                for (var index = 0; index < 12; index++)
                  _column(
                    id: index,
                    originalName: 'Column $index',
                    dbName: 'column_$index',
                  ),
              ],
              rows: [
                for (var rowIndex = 0; rowIndex < 40; rowIndex++)
                  {
                    for (var columnIndex = 0; columnIndex < 12; columnIndex++)
                      'column_$columnIndex': 'R$rowIndex C$columnIndex',
                  },
              ],
            ),
          ),
        ),
      );

      final horizontalScroll = tester.widget<SingleChildScrollView>(
        find.byKey(DatasetTableView.horizontalScrollKey),
      );
      final verticalScroll = tester.widget<SingleChildScrollView>(
        find.byKey(DatasetTableView.verticalScrollKey),
      );

      expect(horizontalScroll.controller!.position.maxScrollExtent,
          greaterThan(0));
      expect(
          verticalScroll.controller!.position.maxScrollExtent, greaterThan(0));
    });
  });

  group('currency symbol display', () {
    testWidgets('appends symbol to column header when currency is set',
        (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: DatasetTableView(
            columns: [
              _column(originalName: 'Price', dbName: 'price'),
              _column(originalName: 'Name', dbName: 'name'),
            ],
            rows: const [
              {'price': '9.99', 'name': 'Book'},
            ],
            columnCurrencySymbols: const {'price': r'$'},
          ),
        ),
      );

      expect(find.text(r'Price ($)'), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);
    });

    testWidgets('strips raw symbol from stored value and appends canonical one',
        (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: DatasetTableView(
            columns: [
              _column(originalName: 'Price', dbName: 'price'),
            ],
            rows: const [
              {'price': r'$44.5'},
            ],
            columnCurrencySymbols: const {r'price': r'$'},
          ),
        ),
      );

      // Raw value is "$44.5"; after stripping and appending the symbol from
      // uiState, the cell should show "44.5 $" — not "44.5$ $".
      expect(find.text(r'44.5 $'), findsOneWidget);
      expect(find.text(r'$44.5'), findsNothing);
    });

    testWidgets('shows clean numeric value when no currency set',
        (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: DatasetTableView(
            columns: [
              _column(originalName: 'Price', dbName: 'price'),
            ],
            rows: const [
              {'price': '44.5'},
            ],
          ),
        ),
      );

      expect(find.text('44.5'), findsOneWidget);
    });

    testWidgets('header has no parenthetical when no currency set',
        (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: DatasetTableView(
            columns: [
              _column(originalName: 'Amount', dbName: 'amount'),
            ],
            rows: const [
              {'amount': '100'},
            ],
          ),
        ),
      );

      expect(find.text('Amount'), findsOneWidget);
      expect(find.textContaining('('), findsNothing);
    });
  });
}

class _TestApp extends StatelessWidget {
  final Widget child;

  const _TestApp({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }
}

DatasetColumn _column({
  int id = 1,
  String originalName = 'Column',
  String dbName = 'column',
}) {
  return DatasetColumn(
    id: id,
    datasetTableId: 1,
    originalName: originalName,
    dbName: dbName,
    declaredType: ColumnType.text,
    inferredType: ColumnType.text,
    nullable: true,
  );
}
