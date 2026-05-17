import 'package:easy_localization/easy_localization.dart';
import 'package:exel_category/core/constants/app_strings.dart';
import 'package:exel_category/domain/entities/dataset.dart';
import 'package:exel_category/presentation/router/routes.dart';
import 'package:exel_category/presentation/widgets/layout/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'datasets_list_provider.dart';
import 'datasets_list_viewmodel.dart';

class DatasetsListView extends ConsumerWidget {
  const DatasetsListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(datasetsListViewModelProvider);

    return AppScaffold(
      title: AppStrings.works.tr(),
      actions: [
        IconButton(
          tooltip: AppStrings.refresh.tr(),
          onPressed: viewModel.isLoading ? null : viewModel.loadDatasets,
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: _buildBody(context, viewModel),
    );
  }

  Widget _buildBody(
    BuildContext context,
    DatasetsListViewModel viewModel,
  ) {
    if (viewModel.isLoading && !viewModel.hasDatasets) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (!viewModel.hasDatasets) {
      return _EmptyDatasetsState(
        errorCode: viewModel.errorCode,
        onRetry: viewModel.loadDatasets,
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.loadDatasets,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount:
            viewModel.datasets.length + (viewModel.errorCode == null ? 0 : 1),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (viewModel.errorCode != null && index == 0) {
            return _ErrorBanner(
              errorCode: viewModel.errorCode!,
              onDismissed: viewModel.clearError,
            );
          }

          final datasetIndex = viewModel.errorCode == null ? index : index - 1;
          final dataset = viewModel.datasets[datasetIndex];

          return _DatasetListCard(
            dataset: dataset,
            isOpening: viewModel.openingDatasetId == dataset.id,
            isDeleting: viewModel.deletingDatasetId == dataset.id,
            onOpen: () => _openDataset(context, viewModel, dataset.id),
            onDelete: () => _confirmDeleteDataset(
              context,
              viewModel,
              dataset,
            ),
          );
        },
      ),
    );
  }

  Future<void> _openDataset(
    BuildContext context,
    DatasetsListViewModel viewModel,
    int datasetId,
  ) async {
    final openedDatasetId = await viewModel.openDataset(datasetId);
    if (openedDatasetId == null || !context.mounted) return;

    context.goNamed(
      AppRoutes.datasetName,
      pathParameters: {
        AppRoutes.datasetIdParam: '$openedDatasetId',
      },
    );
  }

  Future<void> _confirmDeleteDataset(
    BuildContext context,
    DatasetsListViewModel viewModel,
    Dataset dataset,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppStrings.worksDeleteTitle.tr()),
          content: Text(
            '${dataset.name}\n\n${AppStrings.worksDeleteMessage.tr()}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppStrings.cancel.tr()),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(AppStrings.delete.tr()),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;
    await viewModel.deleteDataset(dataset.id);
  }
}

class _EmptyDatasetsState extends StatelessWidget {
  final String? errorCode;
  final VoidCallback onRetry;

  const _EmptyDatasetsState({
    required this.errorCode,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final errorCode = this.errorCode;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              errorCode == null ? Icons.folder_open : Icons.error_outline,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              errorCode == null
                  ? AppStrings.noWorksYet.tr()
                  : _datasetListErrorMessage(errorCode).tr(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (errorCode == null)
              ElevatedButton.icon(
                onPressed: () => context.go(AppRoutes.homePath),
                icon: const Icon(Icons.add),
                label: Text(AppStrings.goHome.tr()),
              )
            else
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(AppStrings.retry.tr()),
              ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String errorCode;
  final VoidCallback onDismissed;

  const _ErrorBanner({
    required this.errorCode,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(8),
      child: ListTile(
        leading: Icon(
          Icons.error_outline,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
        title: Text(
          _datasetListErrorMessage(errorCode).tr(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
        trailing: IconButton(
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: onDismissed,
          icon: const Icon(Icons.close),
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
    );
  }
}

class _DatasetListCard extends StatelessWidget {
  final Dataset dataset;
  final bool isOpening;
  final bool isDeleting;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _DatasetListCard({
    required this.dataset,
    required this.isOpening,
    required this.isDeleting,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: const Icon(Icons.dataset),
        title: Text(dataset.name),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: _DatasetMetadata(dataset: dataset),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: AppStrings.open.tr(),
              onPressed: isOpening || isDeleting ? null : onOpen,
              icon: isOpening
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.open_in_new),
            ),
            IconButton(
              tooltip: AppStrings.delete.tr(),
              onPressed: isOpening || isDeleting ? null : onDelete,
              icon: isDeleting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
            ),
          ],
        ),
        onTap: isOpening || isDeleting ? null : onOpen,
      ),
    );
  }
}

class _DatasetMetadata extends StatelessWidget {
  final Dataset dataset;

  const _DatasetMetadata({
    required this.dataset,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${AppStrings.worksSourceFile.tr()}: ${dataset.sourceFileName}',
          style: textStyle,
        ),
        const SizedBox(height: 4),
        Text(
          '${AppStrings.worksCreatedAt.tr()}: '
          '${_formatTimestamp(context, dataset.createdAt)}',
          style: textStyle,
        ),
        const SizedBox(height: 4),
        Text(
          '${AppStrings.worksLastOpenedAt.tr()}: '
          '${_formatNullableTimestamp(context, dataset.lastOpenedAt)}',
          style: textStyle,
        ),
      ],
    );
  }
}

String _formatNullableTimestamp(BuildContext context, int? timestamp) {
  if (timestamp == null) {
    return AppStrings.worksNeverOpened.tr();
  }

  return _formatTimestamp(context, timestamp);
}

String _formatTimestamp(BuildContext context, int timestamp) {
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  return MaterialLocalizations.of(context).formatMediumDate(date);
}

String _datasetListErrorMessage(String code) {
  switch (code) {
    case 'load_failed':
      return AppStrings.worksLoadFailed;
    case 'open_failed':
      return AppStrings.worksOpenFailed;
    case 'delete_failed':
      return AppStrings.worksDeleteFailed;
    default:
      return AppStrings.worksLoadFailed;
  }
}
