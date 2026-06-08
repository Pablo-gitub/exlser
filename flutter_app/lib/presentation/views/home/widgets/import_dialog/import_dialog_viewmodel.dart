import 'dart:io';

import 'package:exlser/application/dto/import_file.dart';
import 'package:exlser/application/dto/confirmed_import.dart';
import 'package:exlser/application/dto/created_dataset_result.dart';
import 'package:exlser/application/dto/prepared_import_result.dart';
import 'package:exlser/application/exceptions/import_exceptions.dart';
import 'package:exlser/domain/entities/source_file_reference.dart';
import 'package:exlser/domain/value_objects/column_type.dart';
import 'package:flutter/foundation.dart';

typedef PrepareImportCallback = Future<PreparedImportResult> Function({
  required ImportFile file,
});

typedef SaveUploadedFileCallback = Future<SourceFileReference> Function(
  ImportFile file, {
  DateTime? importedAt,
  bool saveLocally,
});

typedef CreateDatasetCallback = Future<CreatedDatasetResult> Function({
  required ConfirmedImport confirmedImport,
});

/// Steps of the import dialog workflow.
enum ImportDialogStep {
  general,
  columnTypes,
  confirmation,
}

/// ViewModel responsible for the import dialog workflow state.
///
/// Responsibilities:
/// - store temporary import configuration
/// - manage wizard step navigation
/// - validate each dialog step
/// - prepare import configuration
/// - execute final dataset creation after confirmation
class ImportDialogViewModel extends ChangeNotifier {
  ImportDialogViewModel({
    required this.file,
    required PrepareImportCallback prepareImport,
    required SaveUploadedFileCallback saveUploadedFile,
    required CreateDatasetCallback createDataset,
    required String initialDatasetName,
  })  : _datasetName = initialDatasetName,
        _saveLocally = !kIsWeb,
        _prepareImport = prepareImport,
        _saveUploadedFile = saveUploadedFile,
        _createDataset = createDataset;

  final ImportFile file;

  final PrepareImportCallback _prepareImport;

  final SaveUploadedFileCallback _saveUploadedFile;

  final CreateDatasetCallback _createDataset;

  ImportDialogStep _currentStep = ImportDialogStep.general;

  String _datasetName;

  bool _saveLocally;

  bool _isPreparingImport = false;

  bool _isCreatingDataset = false;

  PreparedImportResult? _preparedImportResult;

  CreatedDatasetResult? _createdDatasetResult;

  String? _importErrorCode;

  /// Raw exception message captured from unexpected errors.
  /// Exposed so the UI can show actionable detail to the user.
  String? _importErrorDetail;

  final Map<int, Map<int, ColumnType>> _selectedColumnTypes = {};

  ImportDialogStep get currentStep => _currentStep;

  String get datasetName => _datasetName;

  bool get saveLocally => _saveLocally;

  String get sourceFileName => file.fileName;

  bool get isPreparingImport => _isPreparingImport;

  bool get isCreatingDataset => _isCreatingDataset;

  bool get isBusy => _isPreparingImport || _isCreatingDataset;

  PreparedImportResult? get preparedImportResult => _preparedImportResult;

  CreatedDatasetResult? get createdDatasetResult => _createdDatasetResult;

  List<ConfirmedImportSheet> get confirmedSheets {
    final preparedImportResult = _preparedImportResult;

    if (preparedImportResult == null || !hasConfirmedColumnTypes) {
      return const [];
    }

    return [
      for (var sheetIndex = 0;
          sheetIndex < preparedImportResult.sheets.length;
          sheetIndex++)
        ConfirmedImportSheet(
          sheet: preparedImportResult.sheets[sheetIndex].sheet,
          columns: [
            for (var columnIndex = 0;
                columnIndex <
                    preparedImportResult
                        .sheets[sheetIndex].inferredColumns.length;
                columnIndex++)
              preparedImportResult
                  .sheets[sheetIndex].inferredColumns[columnIndex]
                  .copyWith(
                declaredType: selectedColumnTypeFor(
                  sheetIndex: sheetIndex,
                  columnIndex: columnIndex,
                ),
              ),
          ],
          columnCurrencySymbols: preparedImportResult
              .sheets[sheetIndex].columnCurrencySymbols,
        ),
    ];
  }

  ConfirmedImport? get confirmedImport {
    final preparedImportResult = _preparedImportResult;

    if (preparedImportResult == null || !hasConfirmedColumnTypes) {
      return null;
    }

    return ConfirmedImport(
      datasetName: _datasetName.trim(),
      sourceFileName: preparedImportResult.fileName,
      sheets: confirmedSheets,
    );
  }

  String? get importErrorCode => _importErrorCode;

  /// Additional detail about the last error, for display alongside the code.
  String? get importErrorDetail => _importErrorDetail;

  bool get canRetryPreparation =>
      _currentStep == ImportDialogStep.general &&
      _preparedImportResult == null &&
      _importErrorCode != null &&
      !isBusy;

  bool get canGoBack => _currentStep.index > 0;

  bool get isLastStep => _currentStep == ImportDialogStep.confirmation;

  bool get canContinue => isCurrentStepValid && !isBusy;

  bool get hasConfirmedColumnTypes {
    final preparedImportResult = _preparedImportResult;

    if (preparedImportResult == null || !preparedImportResult.hasSheets) {
      return false;
    }

    for (var sheetIndex = 0;
        sheetIndex < preparedImportResult.sheets.length;
        sheetIndex++) {
      final columns = preparedImportResult.sheets[sheetIndex].inferredColumns;

      if (columns.isEmpty) {
        return false;
      }

      for (var columnIndex = 0; columnIndex < columns.length; columnIndex++) {
        if (selectedColumnTypeFor(
              sheetIndex: sheetIndex,
              columnIndex: columnIndex,
            ) ==
            null) {
          return false;
        }
      }
    }

    return true;
  }

  bool get isCurrentStepValid {
    switch (_currentStep) {
      case ImportDialogStep.general:
        return _datasetName.trim().isNotEmpty;

      case ImportDialogStep.columnTypes:
        return hasConfirmedColumnTypes;

      case ImportDialogStep.confirmation:
        return confirmedImport != null;
    }
  }

  ColumnType? selectedColumnTypeFor({
    required int sheetIndex,
    required int columnIndex,
  }) {
    return _selectedColumnTypes[sheetIndex]?[columnIndex];
  }

  void updateColumnType({
    required int sheetIndex,
    required int columnIndex,
    required ColumnType type,
  }) {
    if (!_hasColumn(sheetIndex: sheetIndex, columnIndex: columnIndex)) {
      return;
    }

    _selectedColumnTypes.putIfAbsent(sheetIndex, () => {})[columnIndex] = type;
    notifyListeners();
  }

  void updateDatasetName(String value) {
    _datasetName = value;
    notifyListeners();
  }

  void updateSaveLocally(bool value) {
    _saveLocally = value;
    notifyListeners();
  }

  Future<void> retryPrepareImport() async {
    if (!canRetryPreparation) return;

    await goToNextStep();
  }

  Future<CreatedDatasetResult?> finishImport() async {
    if (!canContinue || !isLastStep) return null;

    final baseConfirmedImport = confirmedImport;
    if (baseConfirmedImport == null) return null;

    _isCreatingDataset = true;
    _importErrorCode = null;
    _importErrorDetail = null;
    notifyListeners();

    try {
      final sourceFileReference = await _saveUploadedFile(
        file,
        saveLocally: _saveLocally,
      );
      final confirmedImportWithFile = ConfirmedImport(
        datasetName: baseConfirmedImport.datasetName,
        sourceFileName: baseConfirmedImport.sourceFileName,
        sourceFileReference: sourceFileReference,
        sheets: baseConfirmedImport.sheets,
      );
      final result = await _createDataset(
        confirmedImport: confirmedImportWithFile,
      );

      _createdDatasetResult = result;
      return result;
    } on ImportException catch (e) {
      _importErrorCode = e.code;
      _importErrorDetail = e.message;
      return null;
    } on FileSystemException catch (e) {
      _importErrorCode = 'file_access_error';
      _importErrorDetail = e.message;
      return null;
    } catch (e) {
      _importErrorCode = 'creation_failed';
      _importErrorDetail = e.toString();
      return null;
    } finally {
      _isCreatingDataset = false;
      notifyListeners();
    }
  }

  Future<void> goToNextStep() async {
    if (!canContinue || isLastStep) return;

    if (_currentStep == ImportDialogStep.general &&
        _preparedImportResult == null) {
      await _prepareSelectedImport();

      if (_preparedImportResult == null) {
        return;
      }
    }

    _currentStep = ImportDialogStep.values[_currentStep.index + 1];
    notifyListeners();
  }

  void goToPreviousStep() {
    if (!canGoBack) return;

    _currentStep = ImportDialogStep.values[_currentStep.index - 1];
    notifyListeners();
  }

  Future<void> _prepareSelectedImport() async {
    _isPreparingImport = true;
    _importErrorCode = null;
    _createdDatasetResult = null;
    notifyListeners();

    try {
      final preparedImportResult = await _prepareImport(file: file);
      _preparedImportResult = preparedImportResult;
      _initializeSelectedColumnTypes(preparedImportResult);
    } on ImportException catch (e) {
      _preparedImportResult = null;
      _selectedColumnTypes.clear();
      _importErrorCode = e.code;
    } catch (_) {
      _preparedImportResult = null;
      _selectedColumnTypes.clear();
      _importErrorCode = 'unexpected_error';
    } finally {
      _isPreparingImport = false;
      notifyListeners();
    }
  }

  void _initializeSelectedColumnTypes(
    PreparedImportResult preparedImportResult,
  ) {
    _selectedColumnTypes.clear();

    for (var sheetIndex = 0;
        sheetIndex < preparedImportResult.sheets.length;
        sheetIndex++) {
      final columns = preparedImportResult.sheets[sheetIndex].inferredColumns;

      _selectedColumnTypes[sheetIndex] = {
        for (var columnIndex = 0; columnIndex < columns.length; columnIndex++)
          columnIndex: columns[columnIndex].declaredType,
      };
    }
  }

  bool _hasColumn({
    required int sheetIndex,
    required int columnIndex,
  }) {
    final preparedImportResult = _preparedImportResult;

    if (preparedImportResult == null ||
        sheetIndex < 0 ||
        sheetIndex >= preparedImportResult.sheets.length) {
      return false;
    }

    final columns = preparedImportResult.sheets[sheetIndex].inferredColumns;

    return columnIndex >= 0 && columnIndex < columns.length;
  }
}
