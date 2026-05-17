import 'package:easy_localization/easy_localization.dart';
import 'package:exel_category/application/dto/import_file.dart';
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
  final ImportFile file;
  final String initialDatasetName;
  final VoidCallback onImportCompleted;

  const ImportDialog({
    super.key,
    required this.file,
    required this.initialDatasetName,
    required this.onImportCompleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final viewModel = ref.watch(
      importDialogViewModelProvider(
        ImportDialogProviderArgs(
          file: file,
          initialDatasetName: initialDatasetName,
        ),
      ),
    );

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 720,
          maxHeight: size.height * 0.85,
        ),
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
              Flexible(
                child: SingleChildScrollView(
                  child: _buildCurrentPage(viewModel),
                ),
              ),
              if (viewModel.importErrorCode != null) ...[
                const SizedBox(height: 16),
                _buildImportError(context, viewModel.importErrorCode!),
              ],
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
        return ImportColumnTypePage(viewModel: viewModel);

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
            onPressed:
                viewModel.isPreparingImport ? null : viewModel.goToPreviousStep,
            child: Text(AppStrings.previous.tr()),
          ),
        const Spacer(),
        ElevatedButton(
          onPressed: viewModel.canContinue
              ? () async {
                  if (viewModel.isLastStep) {
                    // Trigger final import action
                    onImportCompleted();
                    // Close dialog and navigate to dataset view
                    Navigator.of(context).pop();
                    // TODO: navigate to the newly created dataset view, passing the new dataset ID
                    context.go('/datasets/1');
                  } else {
                    await viewModel.goToNextStep();
                  }
                }
              : null,
          child: viewModel.isPreparingImport
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  viewModel.isLastStep
                      ? AppStrings.importFinish.tr()
                      : AppStrings.importNext.tr(),
                ),
        ),
      ],
    );
  }

  Widget _buildImportError(BuildContext context, String code) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _localizedImportError(code).tr(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
    );
  }

  String _localizedImportError(String code) {
    switch (code) {
      case 'no_extension':
        return AppStrings.importNoExtension;
      case 'unsupported_format':
      case 'parser_not_found':
        return AppStrings.importParserNotFound;
      case 'parsing_failed':
        return AppStrings.importParsingFailed;
      case 'no_sheets':
      case 'no_valid_sheets':
        return AppStrings.importEmptySheets;
      case 'schema_failed':
        return AppStrings.importSchemaFailed;
      default:
        return AppStrings.importUnexpectedError;
    }
  }
}
