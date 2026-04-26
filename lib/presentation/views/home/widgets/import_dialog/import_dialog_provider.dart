import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'import_dialog_viewmodel.dart';

/// Provider for ImportDialogViewModel.
///
/// The provider is parameterized in order to:
/// - initialize the dataset name from the selected file
/// - keep dialog state isolated
final importDialogViewModelProvider =
    ChangeNotifierProvider.family<
      ImportDialogViewModel,
      String
    >(
  (ref, initialDatasetName) {
    return ImportDialogViewModel(
      initialDatasetName: initialDatasetName,
    );
  },
);