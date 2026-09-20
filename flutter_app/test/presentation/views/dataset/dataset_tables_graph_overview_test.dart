import 'package:easy_localization/easy_localization.dart';
import 'package:exlser/application/services/multi_sheet_analysis_service.dart';
import 'package:exlser/core/constants/app_strings.dart';
import 'package:exlser/domain/entities/dataset.dart';
import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/entities/dataset_relationship.dart';
import 'package:exlser/domain/entities/dataset_table.dart';
import 'package:exlser/domain/value_objects/column_type.dart';
import 'package:exlser/domain/usecases/multisheet/manage_dataset_relationships_usecases.dart';
import 'package:exlser/domain/value_objects/sheet_join_relationship.dart';
import 'package:exlser/domain/value_objects/sheet_relationship_suggestion.dart';
import 'dart:async';
import 'package:exlser/presentation/providers/service_providers.dart';
import 'package:exlser/presentation/state/dataset_bloc.dart';
import 'package:exlser/presentation/state/dataset_event.dart';
import 'package:exlser/presentation/state/dataset_state.dart';
import 'package:exlser/presentation/views/dataset/widgets/dataset_tables_graph_overview.dart';
import 'package:exlser/presentation/views/sheet_joins/graph/join_connectors_painter.dart';
import 'package:exlser/presentation/views/sheet_joins/graph/join_graph_models.dart';
import 'package:exlser/presentation/views/sheet_joins/graph/join_table_node_card.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockService extends Mock implements MultiSheetAnalysisService {}

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

DatasetColumn _col(String name, int tableId) => DatasetColumn(
      id: '$tableId$name'.hashCode,
      datasetTableId: tableId,
      originalName: name,
      dbName: name.toLowerCase(),
      declaredType: ColumnType.text,
      inferredType: ColumnType.text,
      nullable: true,
    );

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
    colCount: 2,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    registerFallbackValue(const DatasetRelationship(
      datasetId: 0,
      endpointATableId: 0,
      endpointAColumnDbName: '',
      endpointBTableId: 0,
      endpointBColumnDbName: '',
    ));
    registerFallbackValue(<DatasetRelationship>[]);
  });

  late MockService service;
  late Dataset dataset;
  late List<DatasetTable> tables;
  late DatasetTable activeTable;
  late Map<int, List<DatasetColumn>> columnsByTableId;

  setUp(() {
    service = MockService();
    // Every mount reads the dataset's stored relationships to draw them.
    when(() => service.loadRelationships(any())).thenAnswer((_) async => []);
    dataset = const Dataset(
      id: 1,
      name: 'Test Dataset',
      sourceFileName: 'test.xlsx',
      createdAt: 1000,
    );

    final t1 = _table(id: 1, name: 'Orders', sourceSheetName: 'Sheet1');
    final t2 = _table(id: 2, name: 'Details', sourceSheetName: 'Sheet1');
    final t3 = _table(id: 3, name: 'Customers', sourceSheetName: 'Sheet2');
    tables = [t1, t2, t3];
    activeTable = t1;
    columnsByTableId = {
      1: [_col('id', 1), _col('cust_id', 1)],
      2: [_col('id', 2), _col('order_id', 2)],
      3: [_col('id', 3), _col('name', 3)],
    };
  });

  Future<void> pumpOverview(
    WidgetTester tester, {
    required ProviderContainer container,
    DatasetBloc? bloc,
    Map<int, Offset> savedNodePositions = const {},
  }) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en')],
          path: 'assets/i18n',
          fallbackLocale: const Locale('en'),
          startLocale: const Locale('en'),
          child: UncontrolledProviderScope(
            container: container,
            child: Builder(
              builder: (context) => MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: Scaffold(
                  body: BlocProvider<DatasetBloc>.value(
                    value: bloc ?? _FakeDatasetBloc(),
                    child: SingleChildScrollView(
                      child: DatasetTablesGraphOverview(
                        dataset: dataset,
                        tables: tables,
                        activeTable: activeTable,
                        columnsByTableId: columnsByTableId,
                        savedNodePositions: savedNodePositions,
                      ),
                    ),
                  ),
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

  testWidgets('renders all tables initially with scope allSheets',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        multiSheetAnalysisServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    await pumpOverview(tester, container: container);

    expect(find.byKey(const ValueKey('graph_scope_segmented_button')),
        findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Customers'), findsOneWidget);
    expect(find.byKey(const ValueKey('graph_generate_connections_btn')),
        findsOneWidget);
  });

  testWidgets('filters tables when switching scope to singleSheet',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        multiSheetAnalysisServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    await pumpOverview(tester, container: container);

    // Initial all sheets: Customers is present
    expect(find.text('Customers'), findsOneWidget);

    // Switch to singleSheet (Orders and Details are on Sheet1, Customers is on Sheet2)
    final singleSheetBtn =
        find.text(AppStrings.datasetWorkspaceGraphSingleSheet.tr());
    expect(singleSheetBtn, findsOneWidget);
    await tester.tap(singleSheetBtn);
    await tester.pumpAndSettle();

    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Customers'), findsNothing);
  });

  testWidgets('collapses and expands graph canvas', (tester) async {
    final container = ProviderContainer(
      overrides: [
        multiSheetAnalysisServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    await pumpOverview(tester, container: container);

    expect(find.text('Orders'), findsOneWidget);

    final collapseBtn = find.byKey(const ValueKey('graph_collapse_toggle_btn'));
    expect(collapseBtn, findsOneWidget);

    // Collapse
    await tester.tap(collapseBtn);
    await tester.pumpAndSettle();

    expect(find.text('Orders'), findsNothing);

    // Expand
    await tester.tap(collapseBtn);
    await tester.pumpAndSettle();

    expect(find.text('Orders'), findsOneWidget);
  });

  testWidgets('generates connections and allows saving relationships',
      (tester) async {
    final suggestion = SheetRelationshipSuggestion(
      relationship: const SheetJoinRelationship(
        leftTableId: 1,
        leftColumnDbName: 'cust_id',
        rightTableId: 3,
        rightColumnDbName: 'id',
      ),
      score: 0.95,
      confidence: SuggestionConfidence.high,
      reasons: const [RelationshipReason.commonIdentifier],
      sampleSize: 10,
      cardinality: JoinCardinality.manyToOne,
      cardinalityConfidence: 0.9,
    );

    when(() => service.suggestRelationships(
          sheets: any(named: 'sheets'),
          selectedTableIds: any(named: 'selectedTableIds'),
        )).thenAnswer((_) async => [suggestion]);

    when(() => service.createRelationships(
          datasetId: any(named: 'datasetId'),
          relationships: any(named: 'relationships'),
        )).thenAnswer((inv) async {
      final requested = inv.namedArguments[const Symbol('relationships')]
          as List<DatasetRelationship>;
      return CreateDatasetRelationshipsResult(
        created: [
          for (var i = 0; i < requested.length; i++)
            requested[i].copyWith(id: 42 + i),
        ],
      );
    });

    final container = ProviderContainer(
      overrides: [
        multiSheetAnalysisServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    await pumpOverview(tester, container: container);

    // Click Genera collegamenti
    final genBtn = find.byKey(const ValueKey('graph_generate_connections_btn'));
    await tester.tap(genBtn);
    await tester.pump();
    await tester.pumpAndSettle();

    verify(() => service.suggestRelationships(
          sheets: any(named: 'sheets'),
          selectedTableIds: any(named: 'selectedTableIds'),
        )).called(1);

    // Now Save and Edit buttons should be present
    final saveBtn = find.byKey(const ValueKey('graph_save_connections_btn'));
    final editBtn = find.byKey(const ValueKey('graph_edit_connections_btn'));
    expect(saveBtn, findsOneWidget);
    expect(editBtn, findsOneWidget);

    // Click Salva
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();

    // One batch call for the whole set, not one call per suggestion.
    verify(() => service.createRelationships(
          datasetId: 1,
          relationships: any(named: 'relationships'),
        )).called(1);
    // The saved suggestions are re-read so they render as confirmed edges.
    verify(() => service.loadRelationships(1)).called(2);
    expect(find.text('Connections saved successfully'), findsOneWidget);
    expect(saveBtn, findsNothing);
  });

  testWidgets('shows snackbar when no connections are found', (tester) async {
    when(() => service.suggestRelationships(
          sheets: any(named: 'sheets'),
          selectedTableIds: any(named: 'selectedTableIds'),
        )).thenAnswer((_) async => []);

    final container = ProviderContainer(
      overrides: [
        multiSheetAnalysisServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    await pumpOverview(tester, container: container);

    final genBtn = find.byKey(const ValueKey('graph_generate_connections_btn'));
    await tester.tap(genBtn);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('zoom controls do not throw', (tester) async {
    final container = ProviderContainer(
      overrides: [
        multiSheetAnalysisServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    await pumpOverview(tester, container: container);

    final zoomIn = find.byKey(const ValueKey('graph_overview_zoom_in_btn'));
    final zoomOut = find.byKey(const ValueKey('graph_overview_zoom_out_btn'));
    final zoomReset =
        find.byKey(const ValueKey('graph_overview_zoom_reset_btn'));

    expect(zoomIn, findsOneWidget);
    expect(zoomOut, findsOneWidget);
    expect(zoomReset, findsOneWidget);

    await tester.tap(zoomIn);
    await tester.pumpAndSettle();

    await tester.tap(zoomOut);
    await tester.pumpAndSettle();

    await tester.tap(zoomReset);
    await tester.pumpAndSettle();
  });

  testWidgets(
      'when sheets have only one table each, scope toggle is omitted and all tables are shown',
      (tester) async {
    final oneToOneTables = [
      _table(id: 1, name: 'Products', sourceSheetName: 'Products'),
      _table(id: 2, name: 'Regions', sourceSheetName: 'Regions'),
      _table(id: 3, name: 'Sales', sourceSheetName: 'Sales'),
    ];

    final container = ProviderContainer(
      overrides: [
        multiSheetAnalysisServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en')],
          path: 'assets/i18n',
          fallbackLocale: const Locale('en'),
          startLocale: const Locale('en'),
          child: UncontrolledProviderScope(
            container: container,
            child: Builder(
              builder: (context) => MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: Scaffold(
                  body: SingleChildScrollView(
                    child: DatasetTablesGraphOverview(
                      dataset: dataset,
                      tables: oneToOneTables,
                      activeTable: oneToOneTables.first,
                      columnsByTableId: columnsByTableId,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('graph_scope_segmented_button')),
        findsNothing);
    expect(find.text('Products'), findsOneWidget);
    expect(find.text('Regions'), findsOneWidget);
    expect(find.text('Sales'), findsOneWidget);
  });

  testWidgets(
      'when all tables belong to a single sheet, scope toggle is omitted and all tables are shown',
      (tester) async {
    final singleSheetTables = [
      _table(id: 1, name: 'Customers', sourceSheetName: 'Dashboard'),
      _table(id: 2, name: 'Orders', sourceSheetName: 'Dashboard'),
    ];

    final container = ProviderContainer(
      overrides: [
        multiSheetAnalysisServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en')],
          path: 'assets/i18n',
          fallbackLocale: const Locale('en'),
          startLocale: const Locale('en'),
          child: UncontrolledProviderScope(
            container: container,
            child: Builder(
              builder: (context) => MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: Scaffold(
                  body: SingleChildScrollView(
                    child: DatasetTablesGraphOverview(
                      dataset: dataset,
                      tables: singleSheetTables,
                      activeTable: singleSheetTables.first,
                      columnsByTableId: columnsByTableId,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('graph_scope_segmented_button')),
        findsNothing);
    expect(find.text('Customers'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);
  });

  testWidgets(
      'when multiple sheets each have multiple tables, scope toggle is shown and filters by active sheet',
      (tester) async {
    final multiSheetTables = [
      _table(id: 1, name: 'Orders', sourceSheetName: 'Sales'),
      _table(id: 2, name: 'Returns', sourceSheetName: 'Sales'),
      _table(id: 3, name: 'Products', sourceSheetName: 'Inventory'),
      _table(id: 4, name: 'Suppliers', sourceSheetName: 'Inventory'),
    ];

    final container = ProviderContainer(
      overrides: [
        multiSheetAnalysisServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en')],
          path: 'assets/i18n',
          fallbackLocale: const Locale('en'),
          startLocale: const Locale('en'),
          child: UncontrolledProviderScope(
            container: container,
            child: Builder(
              builder: (context) => MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: Scaffold(
                  body: BlocProvider<DatasetBloc>.value(
                    value: _FakeDatasetBloc(),
                    child: SingleChildScrollView(
                      child: DatasetTablesGraphOverview(
                        dataset: dataset,
                        tables: multiSheetTables,
                        activeTable: multiSheetTables.first, // Orders on Sales
                        columnsByTableId: columnsByTableId,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pumpAndSettle();

    // Toggle must be present
    expect(find.byKey(const ValueKey('graph_scope_segmented_button')),
        findsOneWidget);

    // Initially with allSheets: all 4 tables are present
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Returns'), findsOneWidget);
    expect(find.text('Products'), findsOneWidget);
    expect(find.text('Suppliers'), findsOneWidget);

    // Switch to singleSheet
    await tester.tap(find.text('Current sheet'));
    await tester.pumpAndSettle();

    // Now only Sales tables (Orders, Returns) are displayed
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Returns'), findsOneWidget);
    expect(find.text('Products'), findsNothing);
    expect(find.text('Suppliers'), findsNothing);
  });

  testWidgets('tapping a table card dispatches ChangeSheetEvent',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        multiSheetAnalysisServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    final bloc = _FakeDatasetBloc();
    await pumpOverview(tester, container: container, bloc: bloc);

    // Initial state: activeTable is t1 (Orders, id: 1)
    // Tapping on 'Details' (table id: 2)
    await tester.tap(find.text('Details'));
    await tester.pumpAndSettle();

    expect(bloc.events, hasLength(1));
    expect((bloc.events.first as ChangeSheetEvent).tableId, 2);

    // Tapping on 'Customers' (table id: 3)
    await tester.tap(find.text('Customers'));
    await tester.pumpAndSettle();

    expect(bloc.events, hasLength(2));
    expect((bloc.events.last as ChangeSheetEvent).tableId, 3);

    // Tapping on 'Orders' (which is already active table id: 1) does not dispatch an event
    final eventsCount = bloc.events.length;
    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();

    expect(bloc.events.length, eventsCount);
  });

  testWidgets(
      'dragging table node moves it without panning canvas and displays reset layout button',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        multiSheetAnalysisServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    await pumpOverview(tester, container: container);

    // Reset layout button is initially not visible
    expect(find.byKey(const ValueKey('graph_overview_reset_layout_btn')),
        findsNothing);

    // InteractiveViewer initial translation is identity
    final viewerFinder = find.byType(InteractiveViewer);
    final initialViewer = tester.widget<InteractiveViewer>(viewerFinder);
    final initialMatrix = initialViewer.transformationController!.value.clone();

    // Drag the Details node card
    await tester.drag(find.text('Details'), const Offset(100, 60));
    await tester.pumpAndSettle();

    // Reset layout button is now visible in the zoom controls
    expect(find.byKey(const ValueKey('graph_overview_reset_layout_btn')),
        findsOneWidget);

    // InteractiveViewer did NOT pan when dragging table card
    final matrixAfterTableDrag = initialViewer.transformationController!.value;
    expect(matrixAfterTableDrag.getTranslation(),
        equals(initialMatrix.getTranslation()));

    // Tapping the reset layout button restores positions and hides the button
    await tester
        .tap(find.byKey(const ValueKey('graph_overview_reset_layout_btn')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('graph_overview_reset_layout_btn')),
        findsNothing);
  });

  testWidgets(
      'pointer scroll event over canvas zooms in/out via transformation controller',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        multiSheetAnalysisServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    await pumpOverview(tester, container: container);

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

  testWidgets(
      'hovering a card leaves the canvas pannable, a pointer down on it does not',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        multiSheetAnalysisServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    await pumpOverview(tester, container: container);

    final viewerFinder = find.byType(InteractiveViewer);
    var viewer = tester.widget<InteractiveViewer>(viewerFinder);
    expect(viewer.panEnabled, isTrue);

    // Hover over table card
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);

    await gesture.moveTo(tester.getCenter(find.text('Details')));
    await tester.pumpAndSettle();

    // Hover must not gate panning: a card rebuilt or removed while hovered
    // never reports onExit, which used to lock the canvas for good.
    viewer = tester.widget<InteractiveViewer>(viewerFinder);
    expect(viewer.panEnabled, isTrue);

    // A pointer held down on a card hands the gesture to the node instead.
    final down = await tester.startGesture(
      tester.getCenter(find.text('Details')),
    );
    await tester.pump();

    viewer = tester.widget<InteractiveViewer>(viewerFinder);
    expect(viewer.panEnabled, isFalse);

    await down.up();
    await tester.pumpAndSettle();

    viewer = tester.widget<InteractiveViewer>(viewerFinder);
    expect(viewer.panEnabled, isTrue);
  });

  ProviderContainer containerWithService() {
    final container = ProviderContainer(
      overrides: [
        multiSheetAnalysisServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  JoinConnectorsPainter connectorsPainter(WidgetTester tester) {
    final paint =
        tester.widgetList<CustomPaint>(find.byType(CustomPaint)).firstWhere(
              (widget) => widget.painter is JoinConnectorsPainter,
            );
    return paint.painter! as JoinConnectorsPainter;
  }

  JoinTableNodeCard nodeCardFor(WidgetTester tester, int tableId) {
    return tester
        .widgetList<JoinTableNodeCard>(find.byType(JoinTableNodeCard))
        .firstWhere((card) => card.table.tableId == tableId);
  }

  testWidgets('draws the relationships already saved for the dataset',
      (tester) async {
    when(() => service.loadRelationships(1)).thenAnswer((_) async => const [
          DatasetRelationship(
            id: 7,
            datasetId: 1,
            endpointATableId: 1,
            endpointAColumnDbName: 'cust_id',
            endpointBTableId: 3,
            endpointBColumnDbName: 'id',
          ),
        ]);

    await pumpOverview(tester, container: containerWithService());

    final painter = connectorsPainter(tester);
    expect(painter.connections, hasLength(1));
    final connection = painter.connections.single;
    expect(connection.relationshipId, 7);
    expect(connection.isSuggestion, isFalse);
    expect(connection.fromColumnDbName, 'cust_id');
    expect(connection.toColumnDbName, 'id');

    // No generation is needed to see them.
    verifyNever(() => service.suggestRelationships(
          sheets: any(named: 'sheets'),
          selectedTableIds: any(named: 'selectedTableIds'),
        ));
  });

  testWidgets('renders nothing when the dataset has a single table',
      (tester) async {
    tables = [tables.first];
    activeTable = tables.first;

    await pumpOverview(tester, container: containerWithService());

    expect(find.byKey(const ValueKey('dataset_tables_graph_overview_card')),
        findsNothing);
    expect(find.byType(InteractiveViewer), findsNothing);
    verifyNever(() => service.loadRelationships(any()));
  });

  testWidgets('reports a failed generation instead of failing silently',
      (tester) async {
    when(() => service.suggestRelationships(
          sheets: any(named: 'sheets'),
          selectedTableIds: any(named: 'selectedTableIds'),
        )).thenThrow(Exception('boom'));

    await pumpOverview(tester, container: containerWithService());

    await tester
        .tap(find.byKey(const ValueKey('graph_generate_connections_btn')));
    await tester.pumpAndSettle();

    expect(find.text('Could not find connections.'), findsOneWidget);
    // The spinner is gone, so the button can be used again.
    expect(find.byKey(const ValueKey('graph_generate_connections_btn')),
        findsOneWidget);
  });

  testWidgets('reports a failed save instead of failing silently',
      (tester) async {
    when(() => service.suggestRelationships(
          sheets: any(named: 'sheets'),
          selectedTableIds: any(named: 'selectedTableIds'),
        )).thenAnswer((_) async => [
          SheetRelationshipSuggestion(
            relationship: const SheetJoinRelationship(
              leftTableId: 1,
              leftColumnDbName: 'cust_id',
              rightTableId: 3,
              rightColumnDbName: 'id',
            ),
            score: 0.9,
            confidence: SuggestionConfidence.high,
            reasons: const [RelationshipReason.nameMatch],
          ),
        ]);
    when(() => service.createRelationships(
          datasetId: any(named: 'datasetId'),
          relationships: any(named: 'relationships'),
        )).thenThrow(Exception('write failed'));

    await pumpOverview(tester, container: containerWithService());

    await tester
        .tap(find.byKey(const ValueKey('graph_generate_connections_btn')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('graph_save_connections_btn')));
    await tester.pumpAndSettle();

    expect(find.text('Could not save the connections.'), findsOneWidget);
    // The suggestions stay on screen so the user can retry.
    expect(find.byKey(const ValueKey('graph_save_connections_btn')),
        findsOneWidget);
  });

  testWidgets('tells the user how many connections a partial save stored',
      (tester) async {
    when(() => service.suggestRelationships(
          sheets: any(named: 'sheets'),
          selectedTableIds: any(named: 'selectedTableIds'),
        )).thenAnswer((_) async => [
          SheetRelationshipSuggestion(
            relationship: const SheetJoinRelationship(
              leftTableId: 1,
              leftColumnDbName: 'cust_id',
              rightTableId: 3,
              rightColumnDbName: 'id',
            ),
            score: 0.9,
            confidence: SuggestionConfidence.high,
            reasons: const [RelationshipReason.nameMatch],
          ),
          SheetRelationshipSuggestion(
            relationship: const SheetJoinRelationship(
              leftTableId: 1,
              leftColumnDbName: 'id',
              rightTableId: 2,
              rightColumnDbName: 'order_id',
            ),
            score: 0.8,
            confidence: SuggestionConfidence.medium,
            reasons: const [RelationshipReason.nameMatch],
          ),
        ]);
    when(() => service.createRelationships(
          datasetId: any(named: 'datasetId'),
          relationships: any(named: 'relationships'),
        )).thenAnswer((inv) async {
      final requested = inv.namedArguments[const Symbol('relationships')]
          as List<DatasetRelationship>;
      return CreateDatasetRelationshipsResult(
        created: [requested.first.copyWith(id: 1)],
        failed: [requested.last],
      );
    });

    await pumpOverview(tester, container: containerWithService());

    await tester
        .tap(find.byKey(const ValueKey('graph_generate_connections_btn')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('graph_save_connections_btn')));
    await tester.pumpAndSettle();

    expect(find.text('Saved 1 of 2 connections.'), findsOneWidget);
  });

  testWidgets('caps the columns a card renders and counts the rest',
      (tester) async {
    columnsByTableId = {
      1: [for (var i = 0; i < 12; i++) _col('c$i', 1)],
      2: [_col('id', 2), _col('order_id', 2)],
      3: [_col('id', 3), _col('name', 3)],
    };

    await pumpOverview(tester, container: containerWithService());

    final card = nodeCardFor(tester, 1);
    expect(card.table.columns,
        hasLength(DatasetTablesGraphOverview.maxVisibleColumnsPerCard));
    expect(card.table.hiddenColumnCount, 4);
    expect(find.text('+4 more columns'), findsOneWidget);
  });

  testWidgets('keeps a connected column visible even when the card is capped',
      (tester) async {
    columnsByTableId = {
      1: [for (var i = 0; i < 12; i++) _col('c$i', 1)],
      2: [_col('id', 2), _col('order_id', 2)],
      3: [_col('id', 3), _col('name', 3)],
    };
    // The relationship points at the last column, which the cap would drop.
    when(() => service.loadRelationships(1)).thenAnswer((_) async => const [
          DatasetRelationship(
            id: 9,
            datasetId: 1,
            endpointATableId: 1,
            endpointAColumnDbName: 'c11',
            endpointBTableId: 3,
            endpointBColumnDbName: 'id',
          ),
        ]);

    await pumpOverview(tester, container: containerWithService());

    final card = nodeCardFor(tester, 1);
    expect(
      card.table.columns.map((column) => column.columnDbName),
      contains('c11'),
    );
    expect(connectorsPainter(tester).connections, hasLength(1));
  });

  testWidgets('fits the whole graph inside the canvas on first layout',
      (tester) async {
    await pumpOverview(tester, container: containerWithService());

    final viewer =
        tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
    final scale = viewer.transformationController!.value.getMaxScaleOnAxis();

    // The graph is taller than the 320px canvas, so it opens scaled down
    // instead of showing a slice of one card.
    expect(scale, lessThan(1.0));
    expect(scale, greaterThanOrEqualTo(DatasetTablesGraphOverview.minScale));
  });

  testWidgets('restores a saved node layout and persists a dragged one',
      (tester) async {
    final bloc = _FakeDatasetBloc();

    await pumpOverview(
      tester,
      container: containerWithService(),
      bloc: bloc,
      savedNodePositions: const {2: Offset(420, 180)},
    );

    // The stored position is used instead of the automatic one.
    expect(nodeCardFor(tester, 2).table.position, const Offset(420, 180));
    expect(find.byKey(const ValueKey('graph_overview_reset_layout_btn')),
        findsOneWidget);

    await tester.drag(find.text('Details'), const Offset(60, 40));
    await tester.pumpAndSettle();

    final persisted = bloc.events.whereType<UpdateGraphNodePositionsEvent>();
    expect(persisted, isNotEmpty);
    expect(persisted.last.positions[2], isNotNull);
    expect(persisted.last.positions[2], isNot(const Offset(420, 180)));

    // Resetting the layout persists the empty map, so the automatic layout
    // survives the next reload too.
    await tester
        .tap(find.byKey(const ValueKey('graph_overview_reset_layout_btn')));
    await tester.pumpAndSettle();

    expect(
      bloc.events.whereType<UpdateGraphNodePositionsEvent>().last.positions,
      isEmpty,
    );
  });

  testWidgets('mouse wheel over the canvas zooms without scrolling the page',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = containerWithService();
    final pageScrollController = ScrollController();
    addTearDown(pageScrollController.dispose);

    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en')],
          path: 'assets/i18n',
          fallbackLocale: const Locale('en'),
          startLocale: const Locale('en'),
          child: UncontrolledProviderScope(
            container: container,
            child: Builder(
              builder: (context) => MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: Scaffold(
                  body: BlocProvider<DatasetBloc>.value(
                    value: _FakeDatasetBloc(),
                    child: SingleChildScrollView(
                      controller: pageScrollController,
                      child: Column(
                        children: [
                          DatasetTablesGraphOverview(
                            dataset: dataset,
                            tables: tables,
                            activeTable: activeTable,
                            columnsByTableId: columnsByTableId,
                          ),
                          // Makes the page genuinely scrollable, so a wheel event
                          // leaking out of the canvas would move it.
                          const SizedBox(height: 2000),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pumpAndSettle();

    expect(pageScrollController.position.maxScrollExtent, greaterThan(0));

    final viewerFinder = find.byType(InteractiveViewer);
    final controller = tester
        .widget<InteractiveViewer>(viewerFinder)
        .transformationController!;
    final initialScale = controller.value.getMaxScaleOnAxis();

    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    pointer.hover(tester.getCenter(viewerFinder));
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, -100)));
    await tester.pumpAndSettle();

    expect(controller.value.getMaxScaleOnAxis(), greaterThan(initialScale));
    expect(pageScrollController.offset, 0.0);
  });

  testWidgets('reuses the computed layout across unrelated rebuilds',
      (tester) async {
    when(() => service.loadRelationships(1)).thenAnswer((_) async => const [
          DatasetRelationship(
            id: 7,
            datasetId: 1,
            endpointATableId: 1,
            endpointAColumnDbName: 'cust_id',
            endpointBTableId: 3,
            endpointBColumnDbName: 'id',
          ),
        ]);

    await pumpOverview(tester, container: containerWithService());

    final connectionsBefore = connectorsPainter(tester).connections;

    // Hovering a card rebuilds the widget without changing any layout input.
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.text('Details')));
    await tester.pumpAndSettle();

    expect(
      identical(connectorsPainter(tester).connections, connectionsBefore),
      isTrue,
      reason: 'the layout should be memoized, not recomputed on every rebuild',
    );

    // Dragging a node is a real input change, so the layout is recomputed.
    await tester.drag(find.text('Details'), const Offset(50, 30));
    await tester.pumpAndSettle();

    expect(
      identical(connectorsPainter(tester).connections, connectionsBefore),
      isFalse,
    );
  });

  testWidgets(
      'dragging a table node upwards moves it freely without freezing at top limit',
      (tester) async {
    final bloc = _FakeDatasetBloc();
    await pumpOverview(tester, container: containerWithService(), bloc: bloc);

    // Initial position of Details (table 2) is at canvasPadding (same row as Orders)
    final initialDetailsPos = nodeCardFor(tester, 2).table.position;
    expect(initialDetailsPos.dy, equals(JoinGraphLayoutBuilder.canvasPadding));

    // Drag Details upwards (dx = 100, dy = -40)
    await tester.drag(find.text('Details'), const Offset(100, -40));
    await tester.pumpAndSettle();

    final persisted = bloc.events.whereType<UpdateGraphNodePositionsEvent>();
    expect(persisted, isNotEmpty);
    final finalDetailsPos = persisted.last.positions[2];
    expect(finalDetailsPos, isNotNull);

    // With auto-normalization, all node positions are shifted so minimum remains
    // >= canvasPadding (60.0). Details (dragged upwards) is now placed higher than Orders.
    final ordersPos = persisted.last.positions[1];
    expect(ordersPos, isNotNull);
    expect(finalDetailsPos!.dy, lessThan(ordersPos!.dy));
    expect(finalDetailsPos.dy, equals(JoinGraphLayoutBuilder.canvasPadding));
  });
}
