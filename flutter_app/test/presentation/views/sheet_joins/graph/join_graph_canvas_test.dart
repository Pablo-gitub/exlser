import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:exlser/application/services/multi_sheet_analysis_service.dart';
import 'package:exlser/core/constants/app_strings.dart';
import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/entities/dataset_relationship.dart';
import 'package:exlser/domain/entities/dataset_table.dart';
import 'package:exlser/domain/value_objects/column_type.dart';
import 'package:exlser/domain/value_objects/multi_sheet_join.dart';
import 'package:exlser/domain/value_objects/multi_sheet_query_spec.dart';
import 'package:exlser/domain/value_objects/sheet_join_type.dart';
import 'package:exlser/presentation/views/sheet_joins/graph/join_graph_canvas.dart';
import 'package:exlser/presentation/views/sheet_joins/graph/join_table_node_card.dart';
import 'package:exlser/presentation/views/sheet_joins/multi_sheet_join_controller.dart';

class MockMultiSheetAnalysisService extends Mock
    implements MultiSheetAnalysisService {}

DatasetColumn _col(int id, int tableId, String name) {
  return DatasetColumn(
    id: id,
    datasetTableId: tableId,
    originalName: name,
    dbName: name.toLowerCase(),
    declaredType: ColumnType.text,
    inferredType: ColumnType.text,
    nullable: true,
  );
}

MultiSheetSheetInfo _sheet(int id, String name, List<String> cols) {
  return MultiSheetSheetInfo(
    table: DatasetTable(
      id: id,
      datasetId: 1,
      sheetNameOriginal: name,
      sqlTableName: 'tbl_$id',
      rowCount: 10,
      colCount: cols.length,
    ),
    columns: [
      for (var i = 0; i < cols.length; i++) _col(id * 100 + i, id, cols[i]),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  group('JoinGraphCanvas', () {
    late MockMultiSheetAnalysisService mockService;
    late MultiSheetJoinController controller;

    setUp(() {
      mockService = MockMultiSheetAnalysisService();
      when(() => mockService.loadSheets(any())).thenAnswer((_) async => []);
      when(() => mockService.loadRelationships(any()))
          .thenAnswer((_) async => []);
      when(() => mockService.listSavedQueries(any()))
          .thenAnswer((_) async => []);
      controller = MultiSheetJoinController(
        service: mockService,
        datasetId: 1,
      );
    });

    Future<void> pumpCanvas(
      WidgetTester tester,
      MultiSheetJoinState state,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
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
            child: Builder(
              builder: (context) => MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: Scaffold(
                  body: JoinGraphCanvas(
                    state: state,
                    controller: controller,
                  ),
                ),
              ),
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 150));
      });
      await tester.pumpAndSettle();
    }

    testWidgets(
        'renders fallback message when fewer than 2 sheets are selected',
        (tester) async {
      final state = MultiSheetJoinState(
        sheets: [
          _sheet(1, 'Sales', ['id'])
        ],
        spec: const MultiSheetQuerySpec(selectedTableIds: [1]),
      );

      await pumpCanvas(tester, state);

      expect(find.text(AppStrings.datasetJoinsErrorNotEnoughTables.tr()),
          findsOneWidget);
      expect(find.byType(InteractiveViewer), findsNothing);
    });

    testWidgets(
        'renders InteractiveViewer, table cards, zoom controls and connection badges',
        (tester) async {
      final s1 = _sheet(1, 'Customers', ['id', 'name']);
      final s2 = _sheet(2, 'Orders', ['order_id', 'cust_id', 'total']);

      const rel = DatasetRelationship(
        id: 42,
        datasetId: 1,
        endpointATableId: 1,
        endpointAColumnDbName: 'id',
        endpointBTableId: 2,
        endpointBColumnDbName: 'cust_id',
        relationshipConfidence: 0.9,
      );

      final state = MultiSheetJoinState(
        sheets: [s1, s2],
        spec: MultiSheetQuerySpec(
          selectedTableIds: const [1, 2],
          baseTableId: 1,
          joins: [
            MultiSheetJoin(
              relationshipId: 42,
              joinType: SheetJoinType.inner,
            ),
          ],
        ),
        relationshipsById: {42: rel},
      );

      await pumpCanvas(tester, state);

      // InteractiveViewer is rendered
      expect(find.byType(InteractiveViewer), findsOneWidget);

      // Both table cards are displayed
      expect(find.byType(JoinTableNodeCard), findsNWidgets(2));
      expect(find.text('Customers'), findsOneWidget);
      expect(find.text('Orders'), findsOneWidget);

      // Zoom toolbar buttons
      expect(find.byKey(const ValueKey('graph_zoom_in_btn')), findsOneWidget);
      expect(find.byKey(const ValueKey('graph_zoom_out_btn')), findsOneWidget);
      expect(
          find.byKey(const ValueKey('graph_zoom_reset_btn')), findsOneWidget);

      // Connection badge for relationship 42
      expect(find.byKey(const ValueKey('join_badge_42')), findsOneWidget);
      expect(find.text('INNER'), findsOneWidget);
    });

    testWidgets(
        'tapping zoom in, zoom out, and reset buttons triggers transformation changes',
        (tester) async {
      final s1 = _sheet(1, 'Customers', ['id']);
      final s2 = _sheet(2, 'Orders', ['id']);

      final state = MultiSheetJoinState(
        sheets: [s1, s2],
        spec: const MultiSheetQuerySpec(
          selectedTableIds: [1, 2],
          baseTableId: 1,
        ),
      );

      await pumpCanvas(tester, state);

      final viewerFinder = find.byType(InteractiveViewer);
      final initialViewer = tester.widget<InteractiveViewer>(viewerFinder);
      final initialMatrix =
          initialViewer.transformationController!.value.clone();

      // Zoom in
      await tester.tap(find.byKey(const ValueKey('graph_zoom_in_btn')));
      await tester.pumpAndSettle();
      final zoomedInMatrix = initialViewer.transformationController!.value;
      expect(zoomedInMatrix.getMaxScaleOnAxis(),
          greaterThan(initialMatrix.getMaxScaleOnAxis()));

      // Zoom out
      await tester.tap(find.byKey(const ValueKey('graph_zoom_out_btn')));
      await tester.pumpAndSettle();

      // Reset
      await tester.tap(find.byKey(const ValueKey('graph_zoom_reset_btn')));
      await tester.pumpAndSettle();
      final resetMatrix = initialViewer.transformationController!.value;
      expect(resetMatrix, equals(Matrix4.identity()));
    });

    testWidgets('tapping connection badge opens details modal bottom sheet',
        (tester) async {
      final s1 = _sheet(1, 'Customers', ['id', 'name']);
      final s2 = _sheet(2, 'Orders', ['order_id', 'cust_id', 'total']);

      const rel = DatasetRelationship(
        id: 42,
        datasetId: 1,
        endpointATableId: 1,
        endpointAColumnDbName: 'id',
        endpointBTableId: 2,
        endpointBColumnDbName: 'cust_id',
        relationshipConfidence: 0.9,
      );

      final state = MultiSheetJoinState(
        sheets: [s1, s2],
        spec: MultiSheetQuerySpec(
          selectedTableIds: const [1, 2],
          baseTableId: 1,
          joins: [
            MultiSheetJoin(
              relationshipId: 42,
              joinType: SheetJoinType.inner,
            ),
          ],
        ),
        relationshipsById: {42: rel},
      );

      await pumpCanvas(tester, state);

      // Tap on connection badge
      await tester.tap(find.byKey(const ValueKey('join_badge_42')));
      await tester.pumpAndSettle();

      // Modal bottom sheet should be displayed with title and explanation
      expect(find.text(AppStrings.datasetJoinsGraphExplanationTitle.tr()),
          findsOneWidget);
      expect(find.text(AppStrings.datasetJoinsGraphRuleInner.tr()),
          findsOneWidget);
    });

    testWidgets(
        'dragging a table card moves node and displays reset layout button',
        (tester) async {
      final s1 = _sheet(1, 'Customers', ['id', 'name']);
      final s2 = _sheet(2, 'Orders', ['order_id', 'cust_id', 'total']);

      final state = MultiSheetJoinState(
        sheets: [s1, s2],
        spec: const MultiSheetQuerySpec(
          selectedTableIds: [1, 2],
          baseTableId: 1,
        ),
      );

      await pumpCanvas(tester, state);

      // Reset layout button is initially not visible
      expect(
          find.byKey(const ValueKey('graph_reset_layout_btn')), findsNothing);

      // Drag the Orders node card
      await tester.drag(find.text('Orders'), const Offset(80, 50));
      await tester.pumpAndSettle();

      // Reset layout button is now visible
      expect(
          find.byKey(const ValueKey('graph_reset_layout_btn')), findsOneWidget);

      // Tap reset layout button to restore
      await tester.tap(find.byKey(const ValueKey('graph_reset_layout_btn')));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const ValueKey('graph_reset_layout_btn')), findsNothing);
    });

    testWidgets(
        'dragging a table card upwards moves it freely without freezing at top limit',
        (tester) async {
      final s1 = _sheet(1, 'Customers', ['id', 'name']);
      final s2 = _sheet(2, 'Orders', ['order_id', 'cust_id', 'total']);

      final state = MultiSheetJoinState(
        sheets: [s1, s2],
        spec: const MultiSheetQuerySpec(
          selectedTableIds: [1, 2],
          baseTableId: 1,
        ),
      );

      await pumpCanvas(tester, state);

      // Drag Orders upwards and diagonally
      await tester.drag(find.text('Orders'), const Offset(80, -30));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const ValueKey('graph_reset_layout_btn')), findsOneWidget);
    });

    testWidgets('pointer scroll event over canvas zooms in/out via controller',
        (tester) async {
      final s1 = _sheet(1, 'Customers', ['id', 'name']);
      final s2 = _sheet(2, 'Orders', ['order_id', 'cust_id', 'total']);

      final state = MultiSheetJoinState(
        sheets: [s1, s2],
        spec: const MultiSheetQuerySpec(
          selectedTableIds: [1, 2],
          baseTableId: 1,
        ),
      );

      await pumpCanvas(tester, state);

      final viewerFinder = find.byType(InteractiveViewer);
      final initialViewer = tester.widget<InteractiveViewer>(viewerFinder);
      final initialScale =
          initialViewer.transformationController!.value.getMaxScaleOnAxis();

      // Dispatch a PointerScrollEvent over the canvas (scroll up = zoom in)
      final center = tester.getCenter(viewerFinder);
      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      pointer.hover(center);
      await tester.sendEventToBinding(pointer.scroll(const Offset(0, -100)));
      await tester.pumpAndSettle();

      final scaledViewer = tester.widget<InteractiveViewer>(viewerFinder);
      final newScale =
          scaledViewer.transformationController!.value.getMaxScaleOnAxis();
      expect(newScale, greaterThan(initialScale));
    });

    testWidgets('hovering over a table card or badge disables panEnabled',
        (tester) async {
      final s1 = _sheet(1, 'Customers', ['id', 'name']);
      final s2 = _sheet(2, 'Orders', ['order_id', 'cust_id', 'total']);

      final state = MultiSheetJoinState(
        sheets: [s1, s2],
        spec: MultiSheetQuerySpec(
          selectedTableIds: [1, 2],
          baseTableId: 1,
          joins: [
            MultiSheetJoin(
              relationshipId: 42,
              joinType: SheetJoinType.inner,
            ),
          ],
        ),
        relationshipsById: {
          42: const DatasetRelationship(
            id: 42,
            datasetId: 1,
            endpointATableId: 1,
            endpointAColumnDbName: 'id',
            endpointBTableId: 2,
            endpointBColumnDbName: 'cust_id',
          ),
        },
      );

      await pumpCanvas(tester, state);

      final viewerFinder = find.byType(InteractiveViewer);
      var viewer = tester.widget<InteractiveViewer>(viewerFinder);
      expect(viewer.panEnabled, isTrue);

      // Hover over Orders table card
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      await gesture.moveTo(tester.getCenter(find.text('Orders')));
      await tester.pumpAndSettle();

      viewer = tester.widget<InteractiveViewer>(viewerFinder);
      expect(viewer.panEnabled, isFalse);

      // Hover over connection badge
      await gesture.moveTo(
          tester.getCenter(find.byKey(const ValueKey('join_badge_42'))));
      await tester.pumpAndSettle();

      viewer = tester.widget<InteractiveViewer>(viewerFinder);
      expect(viewer.panEnabled, isFalse);

      // Move to empty canvas background
      await gesture
          .moveTo(tester.getTopLeft(viewerFinder) + const Offset(10, 10));
      await tester.pumpAndSettle();

      viewer = tester.widget<InteractiveViewer>(viewerFinder);
      expect(viewer.panEnabled, isTrue);
    });
  });
}
