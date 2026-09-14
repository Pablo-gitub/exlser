import 'package:easy_localization/easy_localization.dart';
import 'package:exlser/application/services/multi_sheet_analysis_service.dart';
import 'package:exlser/core/constants/app_strings.dart';
import 'package:exlser/domain/entities/dataset.dart';
import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/entities/dataset_relationship.dart';
import 'package:exlser/domain/entities/dataset_table.dart';
import 'package:exlser/domain/value_objects/column_type.dart';
import 'package:exlser/domain/value_objects/sheet_join_relationship.dart';
import 'package:exlser/domain/value_objects/sheet_relationship_suggestion.dart';
import 'package:exlser/presentation/providers/service_providers.dart';
import 'package:exlser/presentation/views/dataset/widgets/dataset_tables_graph_overview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockService extends Mock implements MultiSheetAnalysisService {}

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
  });

  late MockService service;
  late Dataset dataset;
  late List<DatasetTable> tables;
  late DatasetTable activeTable;
  late Map<int, List<DatasetColumn>> columnsByTableId;

  setUp(() {
    service = MockService();
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
                  body: SingleChildScrollView(
                    child: DatasetTablesGraphOverview(
                      dataset: dataset,
                      tables: tables,
                      activeTable: activeTable,
                      columnsByTableId: columnsByTableId,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 150));
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

    when(() => service.createRelationship(any())).thenAnswer((inv) async {
      final r = inv.positionalArguments.first as DatasetRelationship;
      return r.copyWith(id: 42);
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

    verify(() => service.createRelationship(any())).called(1);
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
      await Future.delayed(const Duration(milliseconds: 150));
    });
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('graph_scope_segmented_button')),
        findsNothing);
    expect(find.text('Products'), findsOneWidget);
    expect(find.text('Regions'), findsOneWidget);
    expect(find.text('Sales'), findsOneWidget);
  });
}
