import '../../domain/entities/dataset.dart';

/// Base class for dataset workspace states.
abstract class DatasetState {}

/// Initial state before loading data.
class DatasetInitialState extends DatasetState {}

/// Loading state while dataset is being initialized.
class DatasetLoadingState extends DatasetState {}

/// State when dataset is fully loaded.
class DatasetLoadedState extends DatasetState {

  final Dataset dataset;

  /// Active sheet name
  final String activeSheet;

  /// Current filters
  final Map<String, dynamic> filters;

  /// Current rows
  final List<Map<String, dynamic>> rows;

  /// Current view mode (table/cards)
  final String viewMode;

  DatasetLoadedState({
    required this.dataset,
    required this.activeSheet,
    required this.filters,
    required this.rows,
    required this.viewMode,
  });
}

/// Error state.
class DatasetErrorState extends DatasetState {

  final String message;

  DatasetErrorState(this.message);
}