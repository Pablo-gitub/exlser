import 'package:exel_category/application/dto/import_file.dart';
import 'package:exel_category/application/dto/prepared_import_result.dart';
import 'package:exel_category/application/exceptions/import_exceptions.dart';
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

  ImportDialogStep get currentStep => _currentStep;

  String get datasetName => _datasetName;

  bool get saveLocally => _saveLocally;

  String get sourceFileName => file.fileName;

  bool get isPreparingImport => _isPreparingImport;

  PreparedImportResult? get preparedImportResult => _preparedImportResult;

  String? get importErrorCode => _importErrorCode;

  bool get canGoBack => _currentStep.index > 0;

  bool get isLastStep => _currentStep == ImportDialogStep.confirmation;

  bool get canContinue => isCurrentStepValid && !_isPreparingImport;

  bool get isCurrentStepValid {
    switch (_currentStep) {
      case ImportDialogStep.general:
        return _datasetName.trim().isNotEmpty;

      case ImportDialogStep.columnTypes:
        // TODO: validate inferred/selected column types.
        return true;

      case ImportDialogStep.confirmation:
        return true;
    }
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
      _preparedImportResult = await _prepareImport(file: file);
    } on ImportException catch (e) {
      _preparedImportResult = null;
      _importErrorCode = e.code;
    } catch (_) {
      _preparedImportResult = null;
      _importErrorCode = 'unexpected_error';
    } finally {
      _isPreparingImport = false;
      notifyListeners();
    }
  }
}
