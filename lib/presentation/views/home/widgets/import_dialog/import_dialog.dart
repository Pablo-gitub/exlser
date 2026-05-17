import 'package:easy_localization/easy_localization.dart';
import 'package:exel_category/application/dto/import_file.dart';
import 'package:exel_category/core/constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/routes.dart';
import 'import_dialog_provider.dart';
import 'import_error_messages.dart';
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
/// - trigger dataset creation from the confirmation step
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
                _buildImportError(context, viewModel),
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
        return ImportConfirmationPage(viewModel: viewModel);
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
            onPressed: viewModel.isBusy ? null : viewModel.goToPreviousStep,
            child: Text(AppStrings.previous.tr()),
          ),
        const Spacer(),
        ElevatedButton(
          onPressed: viewModel.canContinue
              ? () async {
                  if (viewModel.isLastStep) {
                    final result = await viewModel.finishImport();
                    if (result == null || !context.mounted) return;

                    final navigator = Navigator.of(context);
                    final router = GoRouter.of(context);

                    onImportCompleted();
                    navigator.pop();
                    router.goNamed(
                      AppRoutes.datasetName,
                      pathParameters: {
                        AppRoutes.datasetIdParam: '${result.datasetId}',
                      },
                    );
                  } else {
                    await viewModel.goToNextStep();
                  }
                }
              : null,
          child: viewModel.isBusy
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

  Widget _buildImportError(
    BuildContext context,
    ImportDialogViewModel viewModel,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ImportErrorMessages.translationKeyForCode(
              viewModel.importErrorCode!,
            ).tr(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
          if (viewModel.canRetryPreparation) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppStrings.cancel.tr()),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: viewModel.retryPrepareImport,
                  child: Text(AppStrings.retry.tr()),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
