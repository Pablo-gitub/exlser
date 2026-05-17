import 'package:exel_category/application/dto/import_file.dart';
import 'package:exel_category/application/dto/confirmed_import.dart';
import 'package:exel_category/application/dto/prepared_import_result.dart';
import 'package:exel_category/application/exceptions/import_exceptions.dart';
import 'package:exel_category/domain/value_objects/column_type.dart';
import 'package:flutter/foundation.dart';

typedef PrepareImportCallback = Future<PreparedImportResult> Function({
  required ImportFile file,
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
///
/// This ViewModel does NOT execute the import.
/// Import execution will happen only after the entire
/// configuration flow is completed.
class ImportDialogViewModel extends ChangeNotifier {
  ImportDialogViewModel({
    required this.file,
    required PrepareImportCallback prepareImport,
    required String initialDatasetName,
  })  : _datasetName = initialDatasetName,
        _saveLocally = !kIsWeb,
        _prepareImport = prepareImport;

  final ImportFile file;

  final PrepareImportCallback _prepareImport;

  ImportDialogStep _currentStep = ImportDialogStep.general;

  String _datasetName;

  bool _saveLocally;

  bool _isPreparingImport = false;

  PreparedImportResult? _preparedImportResult;

  String? _importErrorCode;

  final Map<int, Map<int, ColumnType>> _selectedColumnTypes = {};

  ImportDialogStep get currentStep => _currentStep;

  String get datasetName => _datasetName;

  bool get saveLocally => _saveLocally;

  String get sourceFileName => file.fileName;

  bool get isPreparingImport => _isPreparingImport;

  PreparedImportResult? get preparedImportResult => _preparedImportResult;

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

  bool get canGoBack => _currentStep.index > 0;

  bool get isLastStep => _currentStep == ImportDialogStep.confirmation;

  bool get canContinue => isCurrentStepValid && !_isPreparingImport;

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
