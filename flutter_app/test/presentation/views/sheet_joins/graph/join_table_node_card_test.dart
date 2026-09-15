import 'package:easy_localization/easy_localization.dart';
import 'package:exlser/domain/value_objects/column_type.dart';
import 'package:exlser/presentation/views/sheet_joins/graph/join_graph_models.dart';
import 'package:exlser/presentation/views/sheet_joins/graph/join_table_node_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  GraphTableLayout createTable({
    bool isBase = false,
  }) {
    return GraphTableLayout(
      tableId: 1,
      tableName: 'Customers',
      isBase: isBase,
      rowCount: 42,
      position: Offset.zero,
      size: const Size(220, 150),
      columns: const [
        GraphColumnLayout(
          columnId: 1,
          columnDbName: 'id',
          columnName: 'ID',
          columnType: ColumnType.integer,
          isConnected: true,
          leftAnchor: Offset.zero,
          rightAnchor: Offset.zero,
        ),
      ],
    );
  }

  Future<void> pumpCard(WidgetTester tester, Widget card) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en')],
          path: 'assets/i18n',
          fallbackLocale: const Locale('en'),
          startLocale: const Locale('en'),
          child: Builder(
            builder: (context) => MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: Scaffold(body: Center(child: card)),
            ),
          ),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 150));
    });
    await tester.pumpAndSettle();
  }

  group('JoinTableNodeCard', () {
    testWidgets(
        'shows grab cursor when not dragging and grabbing cursor when dragging',
        (tester) async {
      await pumpCard(
        tester,
        JoinTableNodeCard(
          table: createTable(),
          isDragging: false,
        ),
      );

      final inkWellFinder = find.byType(InkWell);
      expect(inkWellFinder, findsOneWidget);
      final inkWellWidget = tester.widget<InkWell>(inkWellFinder);
      expect(inkWellWidget.mouseCursor, equals(SystemMouseCursors.grab));

      // Rebuild with isDragging: true
      await pumpCard(
        tester,
        JoinTableNodeCard(
          table: createTable(),
          isDragging: true,
        ),
      );

      final draggingInkWell = tester.widget<InkWell>(inkWellFinder);
      expect(draggingInkWell.mouseCursor, equals(SystemMouseCursors.grabbing));
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      await pumpCard(
        tester,
        JoinTableNodeCard(
          table: createTable(),
          onTap: () => tapped = true,
        ),
      );

      await tester.tap(find.byType(JoinTableNodeCard));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('calls onHeaderTap as fallback if onTap is not provided',
        (tester) async {
      bool headerTapped = false;
      await pumpCard(
        tester,
        JoinTableNodeCard(
          table: createTable(),
          onHeaderTap: () => headerTapped = true,
        ),
      );

      await tester.tap(find.byType(JoinTableNodeCard));
      await tester.pumpAndSettle();

      expect(headerTapped, isTrue);
    });
  });
}
