import 'package:flutter/foundation.dart';

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
    required String initialDatasetName,
  })  : _datasetName = initialDatasetName,
        _saveLocally = !kIsWeb;

  ImportDialogStep _currentStep = ImportDialogStep.general;

  String _datasetName;

  bool _saveLocally;

  ImportDialogStep get currentStep => _currentStep;

  String get datasetName => _datasetName;

  bool get saveLocally => _saveLocally;

  bool get canGoBack => _currentStep.index > 0;

  bool get isLastStep =>
      _currentStep == ImportDialogStep.confirmation;

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

  void goToNextStep() {
    if (!isCurrentStepValid || isLastStep) return;

    _currentStep = ImportDialogStep.values[_currentStep.index + 1];
    notifyListeners();
  }

  void goToPreviousStep() {
    if (!canGoBack) return;

    _currentStep = ImportDialogStep.values[_currentStep.index - 1];
    notifyListeners();
  }
}