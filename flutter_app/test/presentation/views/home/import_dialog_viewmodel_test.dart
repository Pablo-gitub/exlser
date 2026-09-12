import 'dart:async';

import 'package:exlser/application/dto/confirmed_import.dart';
import 'package:exlser/application/dto/created_dataset_result.dart';
import 'package:exlser/application/dto/import_file.dart';
import 'package:exlser/application/dto/prepared_import_result.dart';
import 'package:exlser/application/dto/prepared_sheet.dart';
import 'package:exlser/application/exceptions/import_exceptions.dart';
import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/entities/parsed_sheet.dart';
import 'package:exlser/domain/entities/source_file_reference.dart';
import 'package:exlser/domain/value_objects/column_type.dart';
import 'package:exlser/domain/value_objects/dataset_file_storage_mode.dart';
import 'package:exlser/presentation/views/home/widgets/import_dialog/import_dialog_viewmodel.dart';
import 'package:exlser/core/constants/app_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ImportDialogViewModel', () {
    test('should prepare import and move to column type step', () async {
      final importFile = _importFile();
      final preparedResult = _preparedResult();
      var callCount = 0;

      final viewModel = _viewModel(
        file: importFile,
        prepareImport: ({required file, detectMultipleTables = true}) async {
          callCount++;
          expect(file, same(importFile));
          return preparedResult;
        },
      );

      await viewModel.goToNextStep();

      expect(callCount, 1);
      expect(viewModel.currentStep, ImportDialogStep.columnTypes);
      expect(viewModel.preparedImportResult, same(preparedResult));
      expect(viewModel.importErrorCode, isNull);
      expect(viewModel.isPreparingImport, isFalse);
    });

    test('should expose loading state while preparing import', () async {
      final completer = Completer<PreparedImportResult>();
      final viewModel = _viewModel(
        prepareImport: ({required file, detectMultipleTables = true}) =>
            completer.future,
      );

      final nextStep = viewModel.goToNextStep();

      expect(viewModel.isPreparingImport, isTrue);
      expect(viewModel.canContinue, isFalse);

      completer.complete(_preparedResult());
      await nextStep;

      expect(viewModel.isPreparingImport, isFalse);
      expect(viewModel.currentStep, ImportDialogStep.columnTypes);
    });

    test('should stay on general step and expose import error code', () async {
      final viewModel = _viewModel(
        prepareImport: ({required file, detectMultipleTables = true}) {
          throw const ParsingException(
            code: 'parsing_failed',
            message: 'Cannot parse file',
          );
        },
      );

      await viewModel.goToNextStep();

      expect(viewModel.currentStep, ImportDialogStep.general);
      expect(viewModel.preparedImportResult, isNull);
      expect(viewModel.importErrorCode, 'parsing_failed');
      expect(viewModel.isPreparingImport, isFalse);
      expect(viewModel.canRetryPreparation, isTrue);
    });

    test('should retry import preparation after failure', () async {
      var callCount = 0;
      final viewModel = _viewModel(
        prepareImport: ({required file, detectMultipleTables = true}) async {
          callCount++;

          if (callCount == 1) {
            throw const ParsingException(
              code: 'parsing_failed',
              message: 'Cannot parse file',
            );
          }

          return _preparedResult();
        },
      );

      await viewModel.goToNextStep();
      expect(viewModel.currentStep, ImportDialogStep.general);
      expect(viewModel.importErrorCode, 'parsing_failed');
      expect(viewModel.canRetryPreparation, isTrue);

      await viewModel.retryPrepareImport();

      expect(callCount, 2);
      expect(viewModel.currentStep, ImportDialogStep.columnTypes);
      expect(viewModel.importErrorCode, isNull);
      expect(viewModel.preparedImportResult, isNotNull);
      expect(viewModel.canRetryPreparation, isFalse);
    });

    test('should not prepare import when current step is invalid', () async {
      var callCount = 0;
      final viewModel = _viewModel(
        prepareImport: ({required file, detectMultipleTables = true}) async {
          callCount++;
          return _preparedResult();
        },
      );

      viewModel.updateDatasetName('   ');
      await viewModel.goToNextStep();

      expect(callCount, 0);
      expect(viewModel.currentStep, ImportDialogStep.general);
      expect(viewModel.preparedImportResult, isNull);
    });

    test('should reuse prepared result when returning to general step',
        () async {
      var callCount = 0;
      final viewModel = _viewModel(
        prepareImport: ({required file, detectMultipleTables = true}) async {
          callCount++;
          return _preparedResult();
        },
      );

      await viewModel.goToNextStep();
      viewModel.goToPreviousStep();
      await viewModel.goToNextStep();

      expect(callCount, 1);
      expect(viewModel.currentStep, ImportDialogStep.columnTypes);
    });

    test('should initialize selected column types from prepared import',
        () async {
      final viewModel = _viewModel(
        prepareImport: ({required file, detectMultipleTables = true}) async =>
            _preparedResult(),
      );

      await viewModel.goToNextStep();

      expect(
        viewModel.selectedColumnTypeFor(sheetIndex: 0, columnIndex: 0),
        ColumnType.text,
      );
      expect(
        viewModel.selectedColumnTypeFor(sheetIndex: 0, columnIndex: 1),
        ColumnType.real,
      );
      expect(viewModel.hasConfirmedColumnTypes, isTrue);
    });

    test('should build confirmed import with selected type overrides',
        () async {
      final viewModel = _viewModel(
        prepareImport: ({required file, detectMultipleTables = true}) async =>
            _preparedResult(),
      );

      viewModel.updateDatasetName('  Sales 2026  ');
      await viewModel.goToNextStep();
      viewModel.updateColumnType(
        sheetIndex: 0,
        columnIndex: 0,
        type: ColumnType.boolean,
      );

      final confirmedImport = viewModel.confirmedImport;

      expect(confirmedImport?.datasetName, 'Sales 2026');
      expect(confirmedImport?.sourceFileName, 'sales.csv');
      expect(confirmedImport?.sourceFileReference, isNull);
      expect(confirmedImport?.tableCount, 1);
      expect(confirmedImport?.columnCount, 2);
      expect(
        confirmedImport?.sheets.single.columns.first.declaredType,
        ColumnType.boolean,
      );
      expect(
        confirmedImport?.sheets.single.columns.first.inferredType,
        ColumnType.text,
      );
      expect(
        confirmedImport?.sheets.single.columns.last.declaredType,
        ColumnType.real,
      );
    });

    test('should advance to confirmation after column types are confirmed',
        () async {
      final viewModel = _viewModel(
        prepareImport: ({required file, detectMultipleTables = true}) async =>
            _preparedResult(),
      );

      await viewModel.goToNextStep();
      await viewModel.goToNextStep();

      expect(viewModel.currentStep, ImportDialogStep.confirmation);
      expect(viewModel.confirmedImport, isNotNull);
    });

    test('should save source file and create dataset on finish', () async {
      final sourceFileReference = _sourceFileReference();
      ConfirmedImport? capturedImport;
      bool? capturedSaveLocally;

      final viewModel = _viewModel(
        prepareImport: ({required file, detectMultipleTables = true}) async =>
            _preparedResult(),
        saveUploadedFile: (
          file, {
          importedAt,
          saveLocally = false,
        }) async {
          capturedSaveLocally = saveLocally;
          expect(file.fileName, 'sales.csv');
          return sourceFileReference;
        },
        createDataset: ({required confirmedImport}) async {
          capturedImport = confirmedImport;
          return _createdDatasetResult();
        },
      );

      viewModel.updateSaveLocally(false);
      await viewModel.goToNextStep();
      await viewModel.goToNextStep();
      final result = await viewModel.finishImport();

      expect(capturedSaveLocally, isFalse);
      expect(result?.datasetId, 42);
      expect(viewModel.createdDatasetResult?.datasetId, 42);
      expect(viewModel.isCreatingDataset, isFalse);
      expect(viewModel.importErrorCode, isNull);
      expect(capturedImport?.sourceFileReference, sourceFileReference);
      expect(capturedImport?.datasetName, 'Sales');
    });

    test('should expose creation error when dataset creation fails', () async {
      final viewModel = _viewModel(
        prepareImport: ({required file, detectMultipleTables = true}) async =>
            _preparedResult(),
        createDataset: ({required confirmedImport}) {
          throw Exception('create failed');
        },
      );

      await viewModel.goToNextStep();
      await viewModel.goToNextStep();
      final result = await viewModel.finishImport();

      expect(result, isNull);
      expect(viewModel.currentStep, ImportDialogStep.confirmation);
      expect(viewModel.importErrorCode, 'creation_failed');
      expect(viewModel.isCreatingDataset, isFalse);
    });

    test('should not finish before confirmation step', () async {
      var saveCallCount = 0;
      var createCallCount = 0;
      final viewModel = _viewModel(
        saveUploadedFile: (
          file, {
          importedAt,
          saveLocally = false,
        }) async {
          saveCallCount++;
          return _sourceFileReference();
        },
        createDataset: ({required confirmedImport}) async {
          createCallCount++;
          return _createdDatasetResult();
        },
      );

      final result = await viewModel.finishImport();

      expect(result, isNull);
      expect(saveCallCount, 0);
      expect(createCallCount, 0);
      expect(viewModel.currentStep, ImportDialogStep.general);
    });

    test('should toggle detectMultipleTables and pass flag to prepareImport',
        () async {
      bool? capturedFlag;
      final viewModel = _viewModel(
        prepareImport: ({required file, detectMultipleTables = true}) async {
          capturedFlag = detectMultipleTables;
          return _preparedResult();
        },
      );

      expect(viewModel.detectMultipleTables, isTrue);

      viewModel.updateDetectMultipleTables(false);
      expect(viewModel.detectMultipleTables, isFalse);

      await viewModel.goToNextStep();
      expect(capturedFlag, isFalse);
    });

    test('should allow custom table names and propagate to confirmed sheets',
        () async {
      final viewModel = _viewModel(
        prepareImport: ({required file, detectMultipleTables = true}) async =>
            _preparedResult(),
      );

      await viewModel.goToNextStep();
      expect(viewModel.currentStep, ImportDialogStep.columnTypes);
      expect(viewModel.tableNameFor(0), 'Sheet1');

      viewModel.updateTableName(sheetIndex: 0, name: 'CustomProducts');
      expect(viewModel.tableNameFor(0), 'CustomProducts');

      final confirmed = viewModel.confirmedSheets;
      expect(confirmed.first.sheet.name, 'CustomProducts');
    });

    test('should validate empty and duplicate table names', () async {
      final multiSheetResult = PreparedImportResult(
        fileName: 'sales.csv',
        fileExtension: 'csv',
        sheets: [
          PreparedSheet(
            sheet: const ParsedSheet(name: 'TableA', rows: [
              {'id': '1'}
            ]),
            inferredColumns: [
              const DatasetColumn(
                id: 0,
                datasetTableId: 0,
                originalName: 'id',
                dbName: 'id',
                declaredType: ColumnType.integer,
                inferredType: ColumnType.integer,
                nullable: false,
              ),
            ],
          ),
          PreparedSheet(
            sheet: const ParsedSheet(name: 'TableB', rows: [
              {'id': '2'}
            ]),
            inferredColumns: [
              const DatasetColumn(
                id: 0,
                datasetTableId: 0,
                originalName: 'id',
                dbName: 'id',
                declaredType: ColumnType.integer,
                inferredType: ColumnType.integer,
                nullable: false,
              ),
            ],
          ),
        ],
      );

      final viewModel = _viewModel(
        prepareImport: ({required file, detectMultipleTables = true}) async =>
            multiSheetResult,
      );

      await viewModel.goToNextStep();
      expect(viewModel.hasValidTableNames, isTrue);
      expect(viewModel.canContinue, isTrue);

      // Empty name
      viewModel.updateTableName(sheetIndex: 0, name: '   ');
      expect(viewModel.hasValidTableNames, isFalse);
      expect(viewModel.tableNameErrorFor(0), AppStrings.importTableNameEmpty);
      expect(viewModel.canContinue, isFalse);

      // Duplicate name
      viewModel.updateTableName(sheetIndex: 0, name: 'TableB');
      expect(viewModel.hasValidTableNames, isFalse);
      expect(
          viewModel.tableNameErrorFor(0), AppStrings.importTableNameDuplicate);
      expect(
          viewModel.tableNameErrorFor(1), AppStrings.importTableNameDuplicate);
      expect(viewModel.canContinue, isFalse);

      // Fixed unique name
      viewModel.updateTableName(sheetIndex: 0, name: 'TableA_Renamed');
      expect(viewModel.hasValidTableNames, isTrue);
      expect(viewModel.tableNameErrorFor(0), isNull);
      expect(viewModel.canContinue, isTrue);
    });

    test('should detect cross-tab matrix table and unpivot by default',
        () async {
      final matrixResult = PreparedImportResult(
        fileName: 'yearly_sales.xlsx',
        fileExtension: 'xlsx',
        sheets: [
          PreparedSheet(
            sheet: const ParsedSheet(
              name: 'Sales',
              rows: [
                {
                  'Product': 'Apples',
                  '2020': '100',
                  '2021': '150',
                  '2022': '200'
                },
                {
                  'Product': 'Bananas',
                  '2020': '80',
                  '2021': '90',
                  '2022': '110'
                },
              ],
            ),
            inferredColumns: [
              const DatasetColumn(
                id: 0,
                datasetTableId: 0,
                originalName: 'Product',
                dbName: 'product',
                declaredType: ColumnType.text,
                inferredType: ColumnType.text,
                nullable: false,
              ),
              const DatasetColumn(
                id: 0,
                datasetTableId: 0,
                originalName: '2020',
                dbName: 'col_2020',
                declaredType: ColumnType.integer,
                inferredType: ColumnType.integer,
                nullable: false,
              ),
              const DatasetColumn(
                id: 0,
                datasetTableId: 0,
                originalName: '2021',
                dbName: 'col_2021',
                declaredType: ColumnType.integer,
                inferredType: ColumnType.integer,
                nullable: false,
              ),
              const DatasetColumn(
                id: 0,
                datasetTableId: 0,
                originalName: '2022',
                dbName: 'col_2022',
                declaredType: ColumnType.integer,
                inferredType: ColumnType.integer,
                nullable: false,
              ),
            ],
          ),
        ],
      );

      final viewModel = _viewModel(
        prepareImport: ({required file, detectMultipleTables = true}) async =>
            matrixResult,
      );

      await viewModel.goToNextStep();

      expect(viewModel.currentStep, ImportDialogStep.columnTypes);
      final candidate = viewModel.matrixCandidateFor(0);
      expect(candidate, isNotNull);
      expect(candidate!.suggestedDimensionName, 'Year');
      expect(candidate.suggestedValueName, 'Value');
      expect(viewModel.isMatrixUnpivotEnabled(0), isTrue);

      // Unpivoted effective sheet should have 3 columns: Product, Year, Value
      final effectiveSheet = viewModel.effectiveSheetFor(0);
      expect(effectiveSheet.inferredColumns.length, 3);
      expect(
        effectiveSheet.inferredColumns.map((c) => c.originalName).toList(),
        ['Product', 'Year', 'Value'],
      );
      expect(
          effectiveSheet.sheet.rows.length, 6); // 2 products * 3 years = 6 rows

      // Toggle unpivot off
      viewModel.toggleMatrixUnpivot(0, false);
      expect(viewModel.isMatrixUnpivotEnabled(0), isFalse);
      final wideSheet = viewModel.effectiveSheetFor(0);
      expect(wideSheet.inferredColumns.length, 4);
      expect(wideSheet.sheet.rows.length, 2);

      // Toggle unpivot back on
      viewModel.toggleMatrixUnpivot(0, true);
      expect(viewModel.isMatrixUnpivotEnabled(0), isTrue);
      expect(viewModel.effectiveSheetFor(0).sheet.rows.length, 6);

      // Update dimension and value names
      viewModel.updateUnpivotDimensionName(sheetIndex: 0, name: 'FiscalYear');
      viewModel.updateUnpivotValueName(sheetIndex: 0, name: 'Revenue');
      expect(viewModel.unpivotDimensionNameFor(0), 'FiscalYear');
      expect(viewModel.unpivotValueNameFor(0), 'Revenue');
      expect(
        viewModel
            .effectiveSheetFor(0)
            .inferredColumns
            .map((c) => c.originalName)
            .toList(),
        ['Product', 'FiscalYear', 'Revenue'],
      );

      // Confirmed sheets reflect unpivoted structure
      final confirmed = viewModel.confirmedSheets;
      expect(confirmed.length, 1);
      expect(confirmed.first.columns.length, 3);
      expect(
        confirmed.first.columns.map((c) => c.originalName).toList(),
        ['Product', 'FiscalYear', 'Revenue'],
      );
      expect(confirmed.first.sheet.rows.length, 6);

      // Validation: blank dimension or value column name blocks next step
      viewModel.updateUnpivotDimensionName(sheetIndex: 0, name: '   ');
      expect(viewModel.hasValidMatrixColumnNames, isFalse);
      expect(viewModel.canContinue, isFalse);

      viewModel.updateUnpivotDimensionName(sheetIndex: 0, name: 'FiscalYear');
      expect(viewModel.hasValidMatrixColumnNames, isTrue);
      expect(viewModel.canContinue, isTrue);
    });
  });
}

ImportDialogViewModel _viewModel({
  ImportFile? file,
  String initialDatasetName = 'Sales',
  PrepareImportCallback? prepareImport,
  SaveUploadedFileCallback? saveUploadedFile,
  CreateDatasetCallback? createDataset,
}) {
  return ImportDialogViewModel(
    file: file ?? _importFile(),
    initialDatasetName: initialDatasetName,
    prepareImport: prepareImport ??
        ({required file, detectMultipleTables = true}) async =>
            _preparedResult(),
    saveUploadedFile: saveUploadedFile ??
        (file, {importedAt, saveLocally = false}) async {
          return _sourceFileReference();
        },
    createDataset: createDataset ??
        ({required confirmedImport}) async {
          return _createdDatasetResult();
        },
  );
}

ImportFile _importFile() {
  return ImportFile.fromBytes(
    fileName: 'sales.csv',
    bytes: [1, 2, 3],
  );
}

PreparedImportResult _preparedResult() {
  return PreparedImportResult(
    fileName: 'sales.csv',
    fileExtension: 'csv',
    sheets: [
      PreparedSheet(
        sheet: const ParsedSheet(
          name: 'Sheet1',
          rows: [
            {'product': 'book', 'price': '10'},
          ],
        ),
        inferredColumns: [
          const DatasetColumn(
            id: 0,
            datasetTableId: 0,
            originalName: 'product',
            dbName: 'product',
            declaredType: ColumnType.text,
            inferredType: ColumnType.text,
            nullable: false,
          ),
          const DatasetColumn(
            id: 0,
            datasetTableId: 0,
            originalName: 'price',
            dbName: 'price',
            declaredType: ColumnType.real,
            inferredType: ColumnType.real,
            nullable: false,
          ),
        ],
      ),
    ],
  );
}

SourceFileReference _sourceFileReference() {
  return SourceFileReference(
    fileName: 'sales.csv',
    storageMode: DatasetFileStorageMode.webTemporary,
    importedAt: DateTime(2026, 1, 2),
    fileSize: 3,
  );
}

CreatedDatasetResult _createdDatasetResult() {
  return const CreatedDatasetResult(
    datasetId: 42,
    datasetName: 'Sales',
    sourceFileName: 'sales.csv',
    tableCount: 1,
    columnCount: 2,
    rowCount: 1,
  );
}
