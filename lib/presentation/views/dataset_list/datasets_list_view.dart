import 'package:flutter/material.dart';

import 'datasets_list_viewmodel.dart';

/// View displaying all saved datasets (workspaces).
///
/// This page is accessible from the main navigation menu
/// and allows the user to:
/// - browse saved datasets
/// - open a selected dataset
/// - delete a dataset
///
/// The HomeView remains dedicated to importing a new file,
/// while this page is used only for reopening existing workspaces.
class DatasetsListView extends StatefulWidget {
  const DatasetsListView({super.key});

  @override
  State<DatasetsListView> createState() => _DatasetsListViewState();
}

class _DatasetsListViewState extends State<DatasetsListView> {
  late DatasetsListViewModel viewModel;

  @override
  void initState() {
    super.initState();

    /// TODO:
    /// Initialize the view model and load saved datasets.
    viewModel = DatasetsListViewModel();
  }

  @override
  Widget build(BuildContext context) {
    /// TODO:
    /// Build datasets list page layout.
    ///
    /// UI elements:
    /// - shared app bar with navigation menu
    /// - list of saved datasets
    /// - optional delete button for each dataset
    ///
    /// Interactions:
    /// - tap on dataset item -> open selected dataset
    /// - tap on delete icon -> delete dataset
    return const Scaffold(
      body: Placeholder(),
    );
  }
}