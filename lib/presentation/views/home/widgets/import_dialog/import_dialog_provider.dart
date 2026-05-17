import 'package:exel_category/application/dto/import_file.dart';
import 'package:exel_category/presentation/providers/service_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'import_dialog_viewmodel.dart';

class ImportDialogProviderArgs {
  final ImportFile file;
  final String initialDatasetName;

  const ImportDialogProviderArgs({
    required this.file,
    required this.initialDatasetName,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ImportDialogProviderArgs &&
            other.initialDatasetName == initialDatasetName &&
            other.file == file;
  }

  @override
  int get hashCode => Object.hash(initialDatasetName, file);
}

/// Provider for ImportDialogViewModel.
///
/// The provider is parameterized in order to:
/// - initialize the dataset name from the selected file
/// - keep dialog state isolated
final importDialogViewModelProvider = ChangeNotifierProvider.family<
    ImportDialogViewModel, ImportDialogProviderArgs>(
  (ref, args) {
    final importDataService = ref.watch(importDataServiceProvider);

    return ImportDialogViewModel(
      file: args.file,
      initialDatasetName: args.initialDatasetName,
      prepareImport: importDataService.prepareImport,
    );
  },
);
