import 'package:exel_category/domain/entities/dataset.dart';
import 'package:exel_category/domain/usecases/dataset/delete_dataset_usecase.dart';
import 'package:exel_category/domain/usecases/dataset/get_datasets_usecase.dart';
import 'package:exel_category/domain/usecases/dataset/open_dataset_usecase.dart';
import 'package:flutter/foundation.dart';

/// ViewModel responsible for the saved datasets list.
///
/// Responsibilities:
/// - load all saved datasets
/// - expose them to the UI
/// - handle open dataset action
/// - handle delete dataset action
///
/// This ViewModel delegates business logic to domain use cases.
class DatasetsListViewModel extends ChangeNotifier {
  final GetDatasetsUseCase _getDatasets;
  final OpenDatasetUseCase _openDataset;
  final DeleteDatasetUseCase _deleteDataset;

  DatasetsListViewModel({
    required GetDatasetsUseCase getDatasets,
    required OpenDatasetUseCase openDataset,
    required DeleteDatasetUseCase deleteDataset,
  })  : _getDatasets = getDatasets,
        _openDataset = openDataset,
        _deleteDataset = deleteDataset;

  List<Dataset> _datasets = const [];
  bool _isLoading = false;
  bool _isOpening = false;
  int? _openingDatasetId;
  int? _deletingDatasetId;
  String? _errorCode;

  List<Dataset> get datasets => List.unmodifiable(_datasets);

  bool get hasDatasets => _datasets.isNotEmpty;

  bool get isLoading => _isLoading;

  bool get isOpening => _isOpening;

  int? get openingDatasetId => _openingDatasetId;

  int? get deletingDatasetId => _deletingDatasetId;

  String? get errorCode => _errorCode;

  Future<void> loadDatasets() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorCode = null;
    notifyListeners();

    try {
      _datasets = await _getDatasets.call();
    } catch (_) {
      _errorCode = 'load_failed';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int?> openDataset(int datasetId) async {
    if (_isOpening) return null;

    _isOpening = true;
    _openingDatasetId = datasetId;
    _errorCode = null;
    notifyListeners();

    try {
      final dataset = await _openDataset.call(datasetId);
      _replaceDataset(dataset);
      return dataset.id;
    } catch (_) {
      _errorCode = 'open_failed';
      return null;
    } finally {
      _isOpening = false;
      _openingDatasetId = null;
      notifyListeners();
    }
  }

  Future<void> deleteDataset(int datasetId) async {
    if (_deletingDatasetId != null) return;

    _deletingDatasetId = datasetId;
    _errorCode = null;
    notifyListeners();

    try {
      await _deleteDataset.call(datasetId);
      _datasets = [
        for (final dataset in _datasets)
          if (dataset.id != datasetId) dataset,
      ];
    } catch (_) {
      _errorCode = 'delete_failed';
    } finally {
      _deletingDatasetId = null;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorCode == null) return;

    _errorCode = null;
    notifyListeners();
  }

  void _replaceDataset(Dataset updatedDataset) {
    _datasets = [
      for (final dataset in _datasets)
        dataset.id == updatedDataset.id ? updatedDataset : dataset,
    ];
  }
}
