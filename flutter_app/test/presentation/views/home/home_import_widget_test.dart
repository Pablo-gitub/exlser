import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:exlser/application/dto/import_file.dart';
import 'package:exlser/application/dto/prepared_import_result.dart';
import 'package:exlser/application/dto/prepared_sheet.dart';
import 'package:exlser/application/services/create_dataset_service.dart';
import 'package:exlser/application/services/import_data_service.dart';
import 'package:exlser/application/usecases/file/save_uploaded_file_usecase.dart';
import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/entities/parsed_sheet.dart';
import 'package:exlser/domain/value_objects/column_type.dart';
import 'package:exlser/presentation/providers/service_providers.dart';
import 'package:exlser/presentation/providers/usecase_providers.dart';
import 'package:exlser/presentation/views/home/home_provider.dart';
import 'package:exlser/presentation/views/home/home_view.dart';
import 'package:exlser/presentation/views/home/home_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockImportDataService extends Mock implements ImportDataService {}

class MockSaveUploadedFileUseCase extends Mock
    implements SaveUploadedFileUseCase {}

class MockCreateDatasetService extends Mock implements CreateDatasetService {}

class FakeImportFile extends Fake implements ImportFile {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    registerFallbackValue(FakeImportFile());
  });

  group('Home import widgets', () {
    testWidgets('runs Home selection and import dialog preparation',
        (tester) async {
      final homeViewModel = HomeViewModel();
      final importDataService = MockImportDataService();
      when(() => importDataService.prepareImport(file: any(named: 'file')))
          .thenAnswer((_) async => _preparedResult());

      await _pumpApp(
        tester,
        overrides: [
          homeViewModelProvider.overrideWith((ref) => homeViewModel),
          ..._serviceOverrides(importDataService: importDataService),
        ],
        child: const HomeView(),
      );

      var processButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Process File'),
      );
      expect(find.text('Select a CSV or XLSX file'), findsOneWidget);
      expect(processButton.onPressed, isNull);

      homeViewModel.setSelectedFile(
        name: 'sales.csv',
        bytes: Uint8List.fromList([1, 2, 3]),
      );
      await tester.pump();

      processButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Process File'),
      );
      expect(find.text('sales.csv'), findsOneWidget);
      expect(processButton.onPressed, isNotNull);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      processButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Process File'),
      );
      expect(find.text('Select a CSV or XLSX file'), findsOneWidget);
      expect(processButton.onPressed, isNull);

      homeViewModel.setSelectedFile(
        name: 'sales.csv',
        bytes: Uint8List.fromList([1, 2, 3]),
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Process File'));
      await tester.pumpAndSettle();

      expect(find.text('Create new dataset'), findsOneWidget);
      expect(find.text('Dataset name'), findsOneWidget);
      expect(find.text('Save file locally'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();

      expect(find.text('Review column types'), findsOneWidget);
      expect(find.text('Sheet 1 · 2 rows'), findsOneWidget);
      expect(find.textContaining('Excel name: product'), findsOneWidget);
      expect(find.textContaining('Data type: Text'), findsOneWidget);
      verify(() => importDataService.prepareImport(file: any(named: 'file')))
          .called(1);
    });

    testWidgets(
        'displays matrix detection card and unpivot switch in column type page',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final homeViewModel = HomeViewModel();
      final importDataService = MockImportDataService();
      when(() => importDataService.prepareImport(
            file: any(named: 'file'),
            detectMultipleTables: any(named: 'detectMultipleTables'),
          )).thenAnswer((_) async => PreparedImportResult(
            fileName: 'matrix_data.csv',
            fileExtension: 'csv',
            sheets: [
              PreparedSheet(
                sheet: const ParsedSheet(
                  name: 'Quarterly',
                  rows: [
                    {'Region': 'North', 'Q1': '10', 'Q2': '20', 'Q3': '30'},
                    {'Region': 'South', 'Q1': '40', 'Q2': '50', 'Q3': '60'},
                  ],
                ),
                inferredColumns: [
                  _column(
                    originalName: 'Region',
                    dbName: 'region',
                    type: ColumnType.text,
                  ),
                  _column(
                    originalName: 'Q1',
                    dbName: 'q1',
                    type: ColumnType.integer,
                  ),
                  _column(
                    originalName: 'Q2',
                    dbName: 'q2',
                    type: ColumnType.integer,
                  ),
                  _column(
                    originalName: 'Q3',
                    dbName: 'q3',
                    type: ColumnType.integer,
                  ),
                ],
              ),
            ],
          ));

      await _pumpApp(
        tester,
        overrides: [
          homeViewModelProvider.overrideWith((ref) => homeViewModel),
          ..._serviceOverrides(importDataService: importDataService),
        ],
        child: const HomeView(),
      );

      homeViewModel.setSelectedFile(
        name: 'matrix_data.csv',
        bytes: Uint8List.fromList([1, 2, 3]),
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Process File'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();

      expect(find.text('Cross-tab matrix detected'), findsOneWidget);
      expect(find.text('Normalize matrix (Unpivot)'), findsOneWidget);
      expect(find.text('Dimension column'), findsOneWidget);
      expect(find.text('Value column'), findsOneWidget);

      // Verify unpivoted rows count: 2 regions * 3 quarters = 6 rows
      expect(find.text('Quarterly · 6 rows'), findsOneWidget);

      // Toggle unpivot switch off
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Should return to wide format (2 rows)
      expect(find.text('Quarterly · 2 rows'), findsOneWidget);
      expect(find.text('Dimension column'), findsNothing);
    });
  });
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required Widget child,
  List<Override> overrides = const [],
}) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(_localizedApp(child: child, overrides: overrides));
    await Future.delayed(const Duration(milliseconds: 200));
  });
  await tester.pumpAndSettle();
}

Widget _localizedApp({
  required Widget child,
  List<Override> overrides = const [],
}) {
  return EasyLocalization(
    supportedLocales: const [Locale('en')],
    path: 'assets/i18n',
    fallbackLocale: const Locale('en'),
    startLocale: const Locale('en'),
    child: Builder(
      builder: (context) {
        return ProviderScope(
          overrides: overrides,
          child: MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: child,
          ),
        );
      },
    ),
  );
}

List<Override> _serviceOverrides({
  MockImportDataService? importDataService,
  MockSaveUploadedFileUseCase? saveUploadedFileUseCase,
  MockCreateDatasetService? createDatasetService,
}) {
  return [
    importDataServiceProvider.overrideWithValue(
      importDataService ?? MockImportDataService(),
    ),
    saveUploadedFileUseCaseProvider.overrideWithValue(
      saveUploadedFileUseCase ?? MockSaveUploadedFileUseCase(),
    ),
    createDatasetServiceProvider.overrideWithValue(
      createDatasetService ?? MockCreateDatasetService(),
    ),
  ];
}

PreparedImportResult _preparedResult() {
  return PreparedImportResult(
    fileName: 'sales.csv',
    fileExtension: 'csv',
    sheets: [
      PreparedSheet(
        sheet: const ParsedSheet(
          name: 'Sheet 1',
          rows: [
            {'product': 'book', 'price': '10'},
            {'product': 'pen', 'price': '2'},
          ],
        ),
        inferredColumns: [
          _column(
            originalName: 'product',
            dbName: 'product',
            type: ColumnType.text,
          ),
          _column(
            originalName: 'price',
            dbName: 'price',
            type: ColumnType.integer,
          ),
        ],
      ),
    ],
  );
}

DatasetColumn _column({
  required String originalName,
  required String dbName,
  required ColumnType type,
}) {
  return DatasetColumn(
    id: 0,
    datasetTableId: 0,
    originalName: originalName,
    dbName: dbName,
    declaredType: type,
    inferredType: type,
    nullable: false,
  );
}
