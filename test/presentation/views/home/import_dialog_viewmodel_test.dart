import 'dart:async';

import 'package:exel_category/application/dto/confirmed_import.dart';
import 'package:exel_category/application/dto/created_dataset_result.dart';
import 'package:exel_category/application/dto/import_file.dart';
import 'package:exel_category/application/dto/prepared_import_result.dart';
import 'package:exel_category/application/dto/prepared_sheet.dart';
import 'package:exel_category/application/exceptions/import_exceptions.dart';
import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/entities/parsed_sheet.dart';
import 'package:exel_category/domain/entities/source_file_reference.dart';
import 'package:exel_category/domain/value_objects/column_type.dart';
import 'package:exel_category/domain/value_objects/dataset_file_storage_mode.dart';
import 'package:exel_category/presentation/views/home/widgets/import_dialog/import_dialog_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ImportDialogViewModel', () {
    test('should prepare import and move to column type step', () async {
      final importFile = _importFile();
      final preparedResult = _preparedResult();
      var callCount = 0;

      final viewModel = _viewModel(
        file: importFile,
        prepareImport: ({required file}) async {
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
        prepareImport: ({required file}) => completer.future,
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
        prepareImport: ({required file}) {
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
        prepareImport: ({required file}) async {
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
        prepareImport: ({required file}) async {
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
        prepareImport: ({required file}) async {
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
        prepareImport: ({required file}) async => _preparedResult(),
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
        prepareImport: ({required file}) async => _preparedResult(),
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
        prepareImport: ({required file}) async => _preparedResult(),
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
        prepareImport: ({required file}) async => _preparedResult(),
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
        prepareImport: ({required file}) async => _preparedResult(),
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
    prepareImport:
        prepareImport ?? ({required file}) async => _preparedResult(),
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
