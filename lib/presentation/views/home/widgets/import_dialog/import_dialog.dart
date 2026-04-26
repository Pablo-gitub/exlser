import 'package:easy_localization/easy_localization.dart';
import 'package:exel_category/core/constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'import_dialog_provider.dart';
import 'import_dialog_viewmodel.dart';
import 'pages/import_column_type_page.dart';
import 'pages/import_confirmation_page.dart';
import 'pages/import_general_page.dart';

/// Dialog orchestrating the dataset import workflow.
///
/// Responsibilities:
/// - render the current import step
/// - manage step navigation controls
/// - delegate step-specific UI to dedicated pages
///
/// This dialog does not execute the final import yet.
/// Final import will be triggered from the confirmation step.
class ImportDialog extends ConsumerWidget {
  final String initialDatasetName;
  final VoidCallback onImportCompleted;

  const ImportDialog({
    super.key,
    required this.initialDatasetName,
    required this.onImportCompleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(
      importDialogViewModelProvider(initialDatasetName),
    );

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.importTitle.tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              _buildCurrentPage(viewModel),
              const SizedBox(height: 24),
              _buildNavigationButtons(context, viewModel),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPage(ImportDialogViewModel viewModel) {
    switch (viewModel.currentStep) {
      case ImportDialogStep.general:
        return ImportGeneralPage(viewModel: viewModel);

      case ImportDialogStep.columnTypes:
        return const ImportColumnTypePage();

      case ImportDialogStep.confirmation:
        return const ImportConfirmationPage();
    }
  }

  Widget _buildNavigationButtons(
    BuildContext context,
    ImportDialogViewModel viewModel,
  ) {
    return Row(
      children: [
        if (viewModel.canGoBack)
          TextButton(
            onPressed: viewModel.goToPreviousStep,
            child: Text(AppStrings.previous.tr()),
          ),
        const Spacer(),
        ElevatedButton(
          onPressed: viewModel.isCurrentStepValid
              ? () {
                  if (viewModel.isLastStep) {
                    // Trigger final import action
                    onImportCompleted();
                    // Close dialog and navigate to dataset view
                    Navigator.of(context).pop();
                    // TODO: navigate to the newly created dataset view, passing the new dataset ID
                    context.go('/datasets/1');
                  } else {
                    viewModel.goToNextStep();
                  }
                }
              : null,
          child: Text(
            viewModel.isLastStep
                ? AppStrings.importFinish.tr()
                : AppStrings.importNext.tr(),
          ),
        ),
      ],
    );
  }
}