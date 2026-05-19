import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:exel_category/application/dto/import_file.dart';
import 'package:exel_category/application/dto/prepared_import_result.dart';
import 'package:exel_category/application/dto/prepared_sheet.dart';
import 'package:exel_category/application/services/create_dataset_service.dart';
import 'package:exel_category/application/services/import_data_service.dart';
import 'package:exel_category/application/usecases/file/save_uploaded_file_usecase.dart';
import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/entities/parsed_sheet.dart';
import 'package:exel_category/domain/value_objects/column_type.dart';
import 'package:exel_category/presentation/providers/service_providers.dart';
import 'package:exel_category/presentation/providers/usecase_providers.dart';
import 'package:exel_category/presentation/views/home/home_provider.dart';
import 'package:exel_category/presentation/views/home/home_view.dart';
import 'package:exel_category/presentation/views/home/home_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

      await tester.pumpWidget(
        _localizedApp(
          overrides: [
            homeViewModelProvider.overrideWith((ref) => homeViewModel),
            ..._serviceOverrides(importDataService: importDataService),
          ],
          child: const HomeView(),
        ),
      );
      await tester.pumpAndSettle();

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
  });
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
