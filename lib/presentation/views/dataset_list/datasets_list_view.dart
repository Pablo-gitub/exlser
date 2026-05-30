import 'package:easy_localization/easy_localization.dart';
import 'package:exlser/core/constants/app_strings.dart';
import 'package:exlser/domain/entities/dataset.dart';
import 'package:exlser/presentation/router/routes.dart';
import 'package:exlser/presentation/widgets/layout/scroll_bottom_spacer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'datasets_list_provider.dart';
import 'datasets_list_viewmodel.dart';

class DatasetsListView extends ConsumerStatefulWidget {
  const DatasetsListView({super.key});

  @override
  ConsumerState<DatasetsListView> createState() => _DatasetsListViewState();
}

class _DatasetsListViewState extends ConsumerState<DatasetsListView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _dateFrom;
  DateTime? _dateTo;

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty || _dateFrom != null || _dateTo != null;

  List<Dataset> _filtered(List<Dataset> datasets) {
    if (!_hasActiveFilters) return datasets;
    return [
      for (final dataset in datasets)
        if (_matchesSearch(dataset) && _matchesDate(dataset)) dataset,
    ];
  }

  bool _matchesSearch(Dataset dataset) {
    if (_searchQuery.isEmpty) return true;
    final q = _searchQuery.toLowerCase();
    return dataset.name.toLowerCase().contains(q) ||
        dataset.sourceFileName.toLowerCase().contains(q);
  }

  bool _matchesDate(Dataset dataset) {
    final created = DateTime.fromMillisecondsSinceEpoch(dataset.createdAt);
    final day = DateTime(created.year, created.month, created.day);
    if (_dateFrom != null && day.isBefore(_dateFrom!)) return false;
    if (_dateTo != null && day.isAfter(_dateTo!)) return false;
    return true;
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _dateFrom = null;
      _dateTo = null;
    });
  }

  Future<void> _pickDateFrom(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateFrom ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: _dateTo ?? DateTime.now(),
    );
    if (picked != null) setState(() => _dateFrom = picked);
  }

  Future<void> _pickDateTo(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateTo ?? DateTime.now(),
      firstDate: _dateFrom ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dateTo = picked);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(datasetsListViewModelProvider);

    return _buildBody(context, viewModel);
  }

  Widget _buildBody(BuildContext context, DatasetsListViewModel viewModel) {
    if (viewModel.isLoading && !viewModel.hasDatasets) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!viewModel.hasDatasets) {
      return _EmptyDatasetsState(
        errorCode: viewModel.errorCode,
        onRetry: viewModel.loadDatasets,
      );
    }

    final filtered = _filtered(viewModel.datasets);

    return RefreshIndicator(
      onRefresh: viewModel.loadDatasets,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _WorksFilterBar(
                    searchController: _searchController,
                    dateFrom: _dateFrom,
                    dateTo: _dateTo,
                    hasActiveFilters: _hasActiveFilters,
                    onSearchChanged: (v) => setState(() => _searchQuery = v),
                    onPickDateFrom: () => _pickDateFrom(context),
                    onPickDateTo: () => _pickDateTo(context),
                    onClearDateFrom: _dateFrom != null
                        ? () => setState(() => _dateFrom = null)
                        : null,
                    onClearDateTo: _dateTo != null
                        ? () => setState(() => _dateTo = null)
                        : null,
                    onClearAll: _clearFilters,
                  ),
                  const SizedBox(height: 16),
                  if (viewModel.errorCode != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ErrorBanner(
                        errorCode: viewModel.errorCode!,
                        onDismissed: viewModel.clearError,
                      ),
                    ),
                  if (filtered.isEmpty)
                    _NoResultsMessage(onClearFilters: _clearFilters)
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final crossCount = width < 600
                            ? 1
                            : width < 1000
                                ? 2
                                : 3;
                        const spacing = 12.0;
                        final cardWidth =
                            (width - spacing * (crossCount - 1)) / crossCount;
                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: [
                            for (final dataset in filtered)
                              SizedBox(
                                width: cardWidth,
                                child: _DatasetListCard(
                                  dataset: dataset,
                                  isOpening:
                                      viewModel.openingDatasetId == dataset.id,
                                  isDeleting:
                                      viewModel.deletingDatasetId == dataset.id,
                                  onOpen: () => _openDataset(
                                      context, viewModel, dataset.id),
                                  onDelete: () => _confirmDeleteDataset(
                                      context, viewModel, dataset),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          const ScrollBottomSpacer(),
        ],
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

class _WorksFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final bool hasActiveFilters;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onPickDateFrom;
  final VoidCallback onPickDateTo;
  final VoidCallback? onClearDateFrom;
  final VoidCallback? onClearDateTo;
  final VoidCallback onClearAll;

  const _WorksFilterBar({
    required this.searchController,
    required this.dateFrom,
    required this.dateTo,
    required this.hasActiveFilters,
    required this.onSearchChanged,
    required this.onPickDateFrom,
    required this.onPickDateTo,
    required this.onClearDateFrom,
    required this.onClearDateTo,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: AppStrings.worksSearchHint.tr(),
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
            isDense: true,
            suffixIcon: searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      searchController.clear();
                      onSearchChanged('');
                    },
                  )
                : null,
          ),
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _DateFilterChip(
              label: AppStrings.datasetWorkspaceFiltersFrom.tr(),
              date: dateFrom,
              onTap: onPickDateFrom,
              onClear: onClearDateFrom,
            ),
            _DateFilterChip(
              label: AppStrings.datasetWorkspaceFiltersTo.tr(),
              date: dateTo,
              onTap: onPickDateTo,
              onClear: onClearDateTo,
            ),
            if (hasActiveFilters)
              ActionChip(
                avatar: const Icon(Icons.clear_all, size: 16),
                label: Text(AppStrings.clear.tr()),
                onPressed: onClearAll,
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ],
    );
  }
}

class _DateFilterChip extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateFilterChip({
    required this.label,
    required this.date,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final dateText = date != null
        ? MaterialLocalizations.of(context).formatMediumDate(date!)
        : null;

    return InputChip(
      avatar: const Icon(Icons.calendar_month_outlined, size: 16),
      label: Text(dateText != null ? '$label: $dateText' : label),
      onPressed: onTap,
      deleteIcon: const Icon(Icons.close, size: 14),
      onDeleted: onClear,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _NoResultsMessage extends StatelessWidget {
  final VoidCallback onClearFilters;

  const _NoResultsMessage({required this.onClearFilters});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 40),
            const SizedBox(height: 12),
            Text(
              AppStrings.worksNoResults.tr(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.clear_all),
              label: Text(AppStrings.clear.tr()),
            ),
          ],
        ),
      ),
    );
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
