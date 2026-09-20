import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:exlser/domain/entities/dataset_table.dart';
import 'package:exlser/presentation/state/dataset_bloc.dart';
import 'package:exlser/presentation/state/dataset_event.dart';
import 'package:exlser/presentation/state/dataset_state.dart';
import 'package:exlser/presentation/views/dataset/widgets/sheet_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeDatasetBloc extends Fake implements DatasetBloc {
  final List<DatasetEvent> events = [];
  final _controller = StreamController<DatasetState>.broadcast();

  @override
  Stream<DatasetState> get stream => _controller.stream;

  @override
  DatasetState get state => const DatasetInitialState();

  @override
  void add(DatasetEvent event) {
    events.add(event);
  }

  @override
  Future<void> close() => _controller.close();
}

DatasetTable _table({
  required int id,
  required String name,
  String? sourceSheetName,
}) {
  return DatasetTable(
    id: id,
    datasetId: 1,
    sheetNameOriginal: name,
    sourceSheetName: sourceSheetName,
    sqlTableName: 'tbl_$id',
    rowCount: 10,
    colCount: 3,
  );
}

Future<void> _pumpSheetSelector(
  WidgetTester tester, {
  required List<DatasetTable> tables,
  required DatasetTable activeTable,
  required _FakeDatasetBloc bloc,
  double width = 800,
  double height = 600,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();

  await tester.runAsync(() async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        child: BlocProvider<DatasetBloc>.value(
          value: bloc,
          child: Builder(
            builder: (context) => MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: Scaffold(
                body: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SheetSelector(
                    tables: tables,
                    activeTable: activeTable,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  group('SheetSelector', () {
    late _FakeDatasetBloc bloc;

    setUp(() {
      bloc = _FakeDatasetBloc();
    });

    tearDown(() {
      bloc.close();
    });

    testWidgets('renders single dropdown when each sheet has only one table',
        (tester) async {
      final t1 = _table(id: 1, name: 'Sheet1');
      final t2 = _table(id: 2, name: 'Sheet2');

      await _pumpSheetSelector(
        tester,
        tables: [t1, t2],
        activeTable: t1,
        bloc: bloc,
      );

      // Only sheet selector dropdown is rendered
      expect(find.byKey(const ValueKey('sheet_selector_dropdown')),
          findsOneWidget);
      expect(
          find.byKey(const ValueKey('table_selector_dropdown')), findsNothing);

      // Tap to change sheet
      await tester.tap(find.byKey(const ValueKey('sheet_selector_dropdown')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sheet2').last);
      await tester.pumpAndSettle();

      final tableIds =
          bloc.events.whereType<ChangeSheetEvent>().map((e) => e.tableId);
      expect(tableIds, contains(2));
    });

    testWidgets(
        'renders both sheet and table dropdowns when multiple tables exist per sheet',
        (tester) async {
      final t1 = _table(id: 1, name: 'Orders', sourceSheetName: 'Sales');
      final t2 = _table(id: 2, name: 'Returns', sourceSheetName: 'Sales');
      final t3 = _table(id: 3, name: 'Products', sourceSheetName: 'Inventory');

      await _pumpSheetSelector(
        tester,
        tables: [t1, t2, t3],
        activeTable: t1,
        bloc: bloc,
      );

      // Both dropdowns are rendered
      expect(find.byKey(const ValueKey('sheet_selector_dropdown')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('table_selector_dropdown')),
          findsOneWidget);

      // Active sheet is Sales (2 tables)
      expect(find.text('Sales (2)'), findsOneWidget);
      // Active table is Orders
      expect(find.text('Orders'), findsOneWidget);

      // Switch table to Returns
      await tester.tap(find.byKey(const ValueKey('table_selector_dropdown')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Returns').last);
      await tester.pumpAndSettle();

      final tableIdsAfterTableChange =
          bloc.events.whereType<ChangeSheetEvent>().map((e) => e.tableId);
      expect(tableIdsAfterTableChange, contains(2));

      // Switch sheet to Inventory
      await tester.tap(find.byKey(const ValueKey('sheet_selector_dropdown')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Inventory').last);
      await tester.pumpAndSettle();

      // Switching sheet dispatches ChangeSheetEvent for the first table in Inventory (t3)
      final tableIdsAfterSheetChange =
          bloc.events.whereType<ChangeSheetEvent>().map((e) => e.tableId);
      expect(tableIdsAfterSheetChange, contains(3));
    });

    testWidgets('adapts layout responsively to narrow and wide screens',
        (tester) async {
      final t1 = _table(id: 1, name: 'Orders', sourceSheetName: 'Sales');
      final t2 = _table(id: 2, name: 'Returns', sourceSheetName: 'Sales');

      // Wide screen: should lay out in a Row
      await _pumpSheetSelector(
        tester,
        tables: [t1, t2],
        activeTable: t1,
        bloc: bloc,
        width: 800,
      );

      expect(find.byType(Row), findsWidgets);

      // Narrow screen: should lay out in a Column
      await _pumpSheetSelector(
        tester,
        tables: [t1, t2],
        activeTable: t1,
        bloc: bloc,
        width: 400,
      );

      expect(find.byType(Column), findsWidgets);
    });
  });
}
