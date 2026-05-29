import 'package:flutter/material.dart';
import 'multi_dataset_analytics_viewmodel.dart';

/// View dedicated to cross-sheet analytics.
///
/// This page allows performing operations between
/// multiple sheets belonging to the same dataset.
///
/// Planned operations:
///
/// - Merge sheets with identical schema
/// - Join sheets with relational keys
/// - Compare datasets
/// - Diff between dataset versions
/// - Data consistency checks
///
/// This page is accessed from DatasetView via
/// "Analyze across sheets".
class MultiDatasetAnalyticsView extends StatefulWidget {
  final int datasetId;

  const MultiDatasetAnalyticsView({
    super.key,
    required this.datasetId,
  });

  @override
  State<MultiDatasetAnalyticsView> createState() =>
      _MultiDatasetAnalyticsViewState();
}

class _MultiDatasetAnalyticsViewState extends State<MultiDatasetAnalyticsView> {
  late MultiDatasetAnalyticsViewModel viewModel;

  @override
  void initState() {
    super.initState();

    /// TODO:
    /// Initialize analytics view model
    /// and load dataset tables.
    viewModel = MultiDatasetAnalyticsViewModel();
  }

  @override
  Widget build(BuildContext context) {
    /// TODO:
    /// Build UI allowing selection of:
    /// - sheets involved
    /// - analysis operation
    ///
    /// Then execute analytics service.

    return const Placeholder();
  }
}
