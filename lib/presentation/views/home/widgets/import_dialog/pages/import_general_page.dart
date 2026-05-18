import 'package:easy_localization/easy_localization.dart';
import 'package:exel_category/core/constants/app_strings.dart';
import 'package:flutter/material.dart';

import '../import_dialog_viewmodel.dart';

/// General import configuration page.
///
/// Responsibilities:
/// - collect dataset name
/// - configure file storage behavior
class ImportGeneralPage extends StatelessWidget {
  final ImportDialogViewModel viewModel;

  const ImportGeneralPage({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          initialValue: viewModel.datasetName,
          onChanged: viewModel.updateDatasetName,
          decoration: InputDecoration(
            labelText: AppStrings.importDatasetName.tr(),
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          value: viewModel.saveLocally,
          onChanged: viewModel.updateSaveLocally,
          title: Text(AppStrings.importSaveLocally.tr()),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
