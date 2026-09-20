import 'dart:io';

import 'package:exlser/application/dto/import_file.dart';
import 'package:exlser/application/dto/confirmed_import.dart';
import 'package:exlser/application/dto/created_dataset_result.dart';
import 'package:exlser/application/dto/prepared_import_result.dart';
import 'package:exlser/application/dto/prepared_sheet.dart';
import 'package:exlser/application/exceptions/import_exceptions.dart';
import 'package:exlser/core/constants/app_strings.dart';
import 'package:exlser/core/normalizers/sql_name_sanitizer.dart';
import 'package:exlser/core/normalizers/boolean_normalizer.dart';
import 'package:exlser/core/normalizers/date_normalizer.dart';
import 'package:exlser/core/normalizers/number_normalizer.dart';
import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/entities/source_file_reference.dart';
import 'package:exlser/domain/usecases/schema/detect_matrix_table_usecase.dart';
import 'package:exlser/domain/usecases/schema/infer_schema_usecase.dart';
import 'package:exlser/domain/usecases/schema/unpivot_matrix_table_usecase.dart';
import 'package:exlser/domain/value_objects/column_type.dart';
import 'package:flutter/foundation.dart';

typedef PrepareImportCallback = Future<PreparedImportResult> Function({
  required ImportFile file,
  bool detectMultipleTables,
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
    DetectMatrixTableUseCase? detectMatrixTableUseCase,
    UnpivotMatrixTableUseCase? unpivotMatrixTableUseCase,
    InferSchemaUseCase? inferSchemaUseCase,
  })  : _datasetName = initialDatasetName,
        _saveLocally = !kIsWeb,
        _prepareImport = prepareImport,
        _saveUploadedFile = saveUploadedFile,
        _createDataset = createDataset,
        _detectMatrixTableUseCase = detectMatrixTableUseCase ??
            DetectMatrixTableUseCase(
              numberNormalizer: NumberNormalizer(),
              dateNormalizer: DateNormalizer(),
              booleanNormalizer: BooleanNormalizer(),
            ),
        _unpivotMatrixTableUseCase =
            unpivotMatrixTableUseCase ?? const UnpivotMatrixTableUseCase(),
        _inferSchemaUseCase = inferSchemaUseCase ??
            InferSchemaUseCase(
              numberNormalizer: NumberNormalizer(),
              dateNormalizer: DateNormalizer(),
              booleanNormalizer: BooleanNormalizer(),
            );

  final ImportFile file;

  final PrepareImportCallback _prepareImport;

  final SaveUploadedFileCallback _saveUploadedFile;

  final CreateDatasetCallback _createDataset;

  final DetectMatrixTableUseCase _detectMatrixTableUseCase;

  final UnpivotMatrixTableUseCase _unpivotMatrixTableUseCase;

  final InferSchemaUseCase _inferSchemaUseCase;

  ImportDialogStep _currentStep = ImportDialogStep.general;

  String _datasetName;

  bool _saveLocally;

  bool _detectMultipleTables = true;

  bool _isPreparingImport = false;

  bool _isCreatingDataset = false;

  PreparedImportResult? _preparedImportResult;

  CreatedDatasetResult? _createdDatasetResult;

  String? _importErrorCode;

  /// Raw exception message captured from unexpected errors.
  /// Exposed so the UI can show actionable detail to the user.
  String? _importErrorDetail;

  final Map<int, Map<int, ColumnType>> _selectedColumnTypes = {};

  final Map<int, String> _customTableNames = {};

  final Map<int, MatrixCandidate> _matrixCandidates = {};

  final Map<int, bool> _matrixUnpivotEnabled = {};

  final Map<int, String> _unpivotDimensionNames = {};

  final Map<int, String> _unpivotValueNames = {};

  final Map<int, PreparedSheet> _unpivotedSheets = {};

  ImportDialogStep get currentStep => _currentStep;

  String get datasetName => _datasetName;

  bool get saveLocally => _saveLocally;

  bool get detectMultipleTables => _detectMultipleTables;

  String get sourceFileName => file.fileName;

  bool get isPreparingImport => _isPreparingImport;

  bool get isCreatingDataset => _isCreatingDataset;

  bool get isBusy => _isPreparingImport || _isCreatingDataset;

  PreparedImportResult? get preparedImportResult => _preparedImportResult;

  CreatedDatasetResult? get createdDatasetResult => _createdDatasetResult;

  String tableNameFor(int sheetIndex) {
    return _customTableNames[sheetIndex] ??
        _preparedImportResult?.sheets[sheetIndex].sheet.name ??
        '';
  }

  void updateTableName({
    required int sheetIndex,
    required String name,
  }) {
    _customTableNames[sheetIndex] = name;
    notifyListeners();
  }

  void updateDetectMultipleTables(bool value) {
    if (_detectMultipleTables == value) return;
    _detectMultipleTables = value;
    _preparedImportResult = null;
    _customTableNames.clear();
    _matrixCandidates.clear();
    _matrixUnpivotEnabled.clear();
    _unpivotDimensionNames.clear();
    _unpivotValueNames.clear();
    _unpivotedSheets.clear();
    notifyListeners();
  }

  MatrixCandidate? matrixCandidateFor(int sheetIndex) {
    return _matrixCandidates[sheetIndex];
  }

  bool isMatrixUnpivotEnabled(int sheetIndex) {
    return _matrixUnpivotEnabled[sheetIndex] ?? false;
  }

  void toggleMatrixUnpivot(int sheetIndex, bool enabled) {
    if (_matrixUnpivotEnabled[sheetIndex] == enabled) return;
    _matrixUnpivotEnabled[sheetIndex] = enabled;
    if (enabled && !_unpivotedSheets.containsKey(sheetIndex)) {
      _updateUnpivotedSheet(sheetIndex);
    }
    _reinitializeColumnTypesForSheet(sheetIndex);
    notifyListeners();
  }

  String unpivotDimensionNameFor(int sheetIndex) {
    return _unpivotDimensionNames[sheetIndex] ??
        _matrixCandidates[sheetIndex]?.suggestedDimensionName ??
        'Dimension';
  }

  void updateUnpivotDimensionName({
    required int sheetIndex,
    required String name,
  }) {
    _unpivotDimensionNames[sheetIndex] = name;
    if (isMatrixUnpivotEnabled(sheetIndex)) {
      _updateUnpivotedSheet(sheetIndex);
      _reinitializeColumnTypesForSheet(sheetIndex);
      notifyListeners();
    }
  }

  String unpivotValueNameFor(int sheetIndex) {
    return _unpivotValueNames[sheetIndex] ??
        _matrixCandidates[sheetIndex]?.suggestedValueName ??
        'Value';
  }

  void updateUnpivotValueName({
    required int sheetIndex,
    required String name,
  }) {
    _unpivotValueNames[sheetIndex] = name;
    if (isMatrixUnpivotEnabled(sheetIndex)) {
      _updateUnpivotedSheet(sheetIndex);
      _reinitializeColumnTypesForSheet(sheetIndex);
      notifyListeners();
    }
  }

  PreparedSheet effectiveSheetFor(int sheetIndex) {
    final prepared = _preparedImportResult;
    if (prepared == null ||
        sheetIndex < 0 ||
        sheetIndex >= prepared.sheets.length) {
      throw StateError('Sheet index $sheetIndex out of bounds');
    }
    if (isMatrixUnpivotEnabled(sheetIndex)) {
      final unpivoted = _unpivotedSheets[sheetIndex];
      if (unpivoted != null) {
        return unpivoted;
      }
    }
    return prepared.sheets[sheetIndex];
  }

  bool get hasValidTableNames {
    final prepared = _preparedImportResult;
    if (prepared == null || !prepared.hasSheets) return true;

    final names = <String>{};
    final sqlNames = <String>{};
    for (var i = 0; i < prepared.sheets.length; i++) {
      final name = tableNameFor(i).trim();
      if (name.isEmpty) return false;
      if (!names.add(name.toLowerCase())) return false;
      if (!sqlNames.add(_sqlNameFor(i))) return false;
    }
    return true;
  }

  /// The identifier a table name will end up as. Two different labels can map to
  /// the same one ("Sales 2024" and "Sales-2024"), which used to pass the wizard
  /// and only fail at CREATE TABLE time.
  String _sqlNameFor(int sheetIndex) {
    return SqlNameSanitizer.sanitizeTableName(tableNameFor(sheetIndex).trim());
  }

  String? tableNameErrorFor(int sheetIndex) {
    final name = tableNameFor(sheetIndex).trim();
    if (name.isEmpty) {
      return AppStrings.importTableNameEmpty;
    }
    final prepared = _preparedImportResult;
    if (prepared != null) {
      final sqlName = _sqlNameFor(sheetIndex);
      for (var i = 0; i < prepared.sheets.length; i++) {
        if (i == sheetIndex) continue;
        if (tableNameFor(i).trim().toLowerCase() == name.toLowerCase() ||
            _sqlNameFor(i) == sqlName) {
          return AppStrings.importTableNameDuplicate;
        }
      }
    }
    return null;
  }

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
          sheet: effectiveSheetFor(sheetIndex).sheet.copyWith(
                name: tableNameFor(sheetIndex).trim().isNotEmpty
                    ? tableNameFor(sheetIndex).trim()
                    : effectiveSheetFor(sheetIndex).sheet.name,
              ),
          columns: [
            for (var columnIndex = 0;
                columnIndex <
                    effectiveSheetFor(sheetIndex).inferredColumns.length;
                columnIndex++)
              effectiveSheetFor(sheetIndex)
                  .inferredColumns[columnIndex]
                  .copyWith(
                    declaredType: selectedColumnTypeFor(
                      sheetIndex: sheetIndex,
                      columnIndex: columnIndex,
                    ),
                  ),
          ],
          columnCurrencySymbols:
              effectiveSheetFor(sheetIndex).columnCurrencySymbols,
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
      final columns = effectiveSheetFor(sheetIndex).inferredColumns;

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

  bool get hasValidMatrixColumnNames {
    for (final entry in _matrixCandidates.entries) {
      final sheetIndex = entry.key;
      if (isMatrixUnpivotEnabled(sheetIndex)) {
        final dimName = unpivotDimensionNameFor(sheetIndex).trim();
        final valName = unpivotValueNameFor(sheetIndex).trim();
        if (dimName.isEmpty || valName.isEmpty) return false;
      }
    }
    return true;
  }

  bool get isCurrentStepValid {
    switch (_currentStep) {
      case ImportDialogStep.general:
        return _datasetName.trim().isNotEmpty;

      case ImportDialogStep.columnTypes:
        return hasConfirmedColumnTypes &&
            hasValidTableNames &&
            hasValidMatrixColumnNames;

      case ImportDialogStep.confirmation:
        return confirmedImport != null;
    }
  }

  ColumnType? selectedColumnTypeFor({
    required int sheetIndex,
    required int columnIndex,
  }) {
    final selected = _selectedColumnTypes[sheetIndex]?[columnIndex];
    if (selected != null) return selected;
    if (_hasColumn(sheetIndex: sheetIndex, columnIndex: columnIndex)) {
      return effectiveSheetFor(sheetIndex)
          .inferredColumns[columnIndex]
          .declaredType;
    }
    return null;
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
      final preparedImportResult = await _prepareImport(
        file: file,
        detectMultipleTables: _detectMultipleTables,
      );
      _preparedImportResult = preparedImportResult;
      _customTableNames.clear();
      _matrixCandidates.clear();
      _matrixUnpivotEnabled.clear();
      _unpivotDimensionNames.clear();
      _unpivotValueNames.clear();
      _unpivotedSheets.clear();
      _detectMatrixTables(preparedImportResult);
      _initializeSelectedColumnTypes();
    } on ImportException catch (e) {
      _preparedImportResult = null;
      _selectedColumnTypes.clear();
      _matrixCandidates.clear();
      _matrixUnpivotEnabled.clear();
      _unpivotDimensionNames.clear();
      _unpivotValueNames.clear();
      _unpivotedSheets.clear();
      _importErrorCode = e.code;
    } catch (_) {
      _preparedImportResult = null;
      _selectedColumnTypes.clear();
      _matrixCandidates.clear();
      _matrixUnpivotEnabled.clear();
      _unpivotDimensionNames.clear();
      _unpivotValueNames.clear();
      _unpivotedSheets.clear();
      _importErrorCode = 'unexpected_error';
    } finally {
      _isPreparingImport = false;
      notifyListeners();
    }
  }

  void _detectMatrixTables(PreparedImportResult preparedImportResult) {
    for (var i = 0; i < preparedImportResult.sheets.length; i++) {
      final sheet = preparedImportResult.sheets[i].sheet;
      final candidate = _detectMatrixTableUseCase(sheet.rows);
      if (candidate != null) {
        _matrixCandidates[i] = candidate;
        _matrixUnpivotEnabled[i] = true;
        _unpivotDimensionNames[i] = candidate.suggestedDimensionName;
        _unpivotValueNames[i] = candidate.suggestedValueName;
        _updateUnpivotedSheet(i);
      }
    }
  }

  void _initializeSelectedColumnTypes() {
    _selectedColumnTypes.clear();
    final prepared = _preparedImportResult;
    if (prepared == null) return;

    for (var sheetIndex = 0;
        sheetIndex < prepared.sheets.length;
        sheetIndex++) {
      _reinitializeColumnTypesForSheet(sheetIndex);
    }
  }

  void _reinitializeColumnTypesForSheet(int sheetIndex) {
    final sheet = effectiveSheetFor(sheetIndex);
    _selectedColumnTypes[sheetIndex] = {
      for (var colIdx = 0; colIdx < sheet.inferredColumns.length; colIdx++)
        colIdx: sheet.inferredColumns[colIdx].declaredType,
    };
  }

  void _updateUnpivotedSheet(int sheetIndex) {
    final original = _preparedImportResult?.sheets[sheetIndex];
    final candidate = _matrixCandidates[sheetIndex];
    if (original == null || candidate == null) return;

    try {
      final unpivotedParsedSheet = _unpivotMatrixTableUseCase.unpivotSheet(
        original.sheet,
        candidate: candidate,
        customDimensionName: unpivotDimensionNameFor(sheetIndex),
        customValueName: unpivotValueNameFor(sheetIndex),
      );

      final columns = _inferColumnsForRows(
        unpivotedParsedSheet.rows,
        [
          ...candidate.idColumnNames,
          unpivotDimensionNameFor(sheetIndex),
          unpivotValueNameFor(sheetIndex),
        ],
      );

      _unpivotedSheets[sheetIndex] = PreparedSheet(
        sheet: unpivotedParsedSheet,
        inferredColumns: columns,
        columnCurrencySymbols: const {},
      );
    } catch (_) {
      _unpivotedSheets.remove(sheetIndex);
      _matrixUnpivotEnabled[sheetIndex] = false;
    }
  }

  List<DatasetColumn> _inferColumnsForRows(
    List<Map<String, dynamic>> rows,
    List<String> headers,
  ) {
    if (rows.isEmpty) {
      final seenDbNames = <String>[];
      return [
        for (final header in headers)
          DatasetColumn(
            id: 0,
            datasetTableId: 0,
            originalName: header,
            dbName: SqlNameSanitizer.sanitizeColumnName(
              header,
              existingNames: seenDbNames,
            ),
            inferredType: ColumnType.text,
            declaredType: ColumnType.text,
            nullable: true,
          ),
      ];
    }
    final matrix = _convertToMatrix(rows);
    return _inferSchemaUseCase(matrix, 0);
  }

  List<List<String>> _convertToMatrix(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return [];
    final headers = rows.first.keys.toList();
    final matrix = <List<String>>[headers];
    for (final row in rows) {
      matrix.add(
        headers.map((h) => row[h]?.toString() ?? '').toList(),
      );
    }
    return matrix;
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

    final columns = effectiveSheetFor(sheetIndex).inferredColumns;

    return columnIndex >= 0 && columnIndex < columns.length;
  }
}
