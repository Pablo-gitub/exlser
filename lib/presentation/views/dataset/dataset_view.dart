import 'package:flutter/material.dart';
import 'dataset_viewmodel.dart';

/// Main workspace view for a dataset.
///
/// This page allows the user to:
/// - Manage dataset metadata (rename, file path, delete)
/// - Select which Excel sheet to work on
/// - Apply filters to dataset columns
/// - Visualize filtered results
/// - View analytics charts
///
/// Layout structure:
///
/// DatasetInfoSection
/// SheetSelectorSection
/// FiltersSection
/// ResultsSection
/// AnalyticsSection
///
/// The view itself must remain "dumb":
/// - UI rendering only
/// - No business logic
///
/// All actions are delegated to DatasetViewModel.
class DatasetView extends StatefulWidget {

  final int datasetId;

  const DatasetView({
    super.key,
    required this.datasetId,
  });

  @override
  State<DatasetView> createState() => _DatasetViewState();
}

class _DatasetViewState extends State<DatasetView> {

  late DatasetViewModel viewModel;

  @override
  void initState() {
    super.initState();

    /// TODO
    /// Initialize ViewModel and load dataset state
    viewModel = DatasetViewModel();
  }

  @override
  Widget build(BuildContext context) {

    /// TODO
    /// Listen to ViewModel state changes (Riverpod / BLoC / notifier)

    return Scaffold(

      appBar: AppBar(
        title: const Text("Dataset Workspace"),

        /// TODO
        /// Export menu button
        /// Allows exporting:
        /// - filtered data
        /// - charts
        /// - combined report
      ),

      body: Column(
        children: [

          /// Dataset metadata section
          /// Rename dataset, file path, delete
          /// TODO: implement DatasetInfoSection
          const Placeholder(),

          /// Sheet selector dropdown
          /// Allows choosing Excel sheet
          /// TODO: implement SheetSelectorSection
          const Placeholder(),

          /// Filters section
          /// Column-based filters
          /// TODO: implement FiltersSection
          const Placeholder(),

          /// Filtered results section
          /// Table / card toggle
          /// TODO: implement ResultsSection
          const Placeholder(),

          /// Analytics section
          /// Charts based on filtered data
          /// TODO: implement AnalyticsSection
          const Placeholder(),

        ],
      ),
    );
  }
}