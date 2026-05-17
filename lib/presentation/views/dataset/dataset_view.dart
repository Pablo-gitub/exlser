import 'package:easy_localization/easy_localization.dart';
import 'package:exel_category/core/constants/app_strings.dart';
import 'package:exel_category/domain/entities/dataset.dart';
import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/entities/dataset_table.dart';
import 'package:exel_category/presentation/providers/repository_providers.dart';
import 'package:exel_category/presentation/providers/usecase_providers.dart';
import 'package:exel_category/presentation/state/dataset_bloc.dart';
import 'package:exel_category/presentation/state/dataset_event.dart';
import 'package:exel_category/presentation/state/dataset_state.dart';
import 'package:exel_category/presentation/widgets/dataset_views/dataset_card_view.dart';
import 'package:exel_category/presentation/widgets/dataset_views/dataset_table_view.dart';
import 'package:exel_category/presentation/widgets/layout/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DatasetView extends ConsumerWidget {
  final int datasetId;

  const DatasetView({
    super.key,
    required this.datasetId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BlocProvider(
      create: (_) => DatasetBloc(
        openDataset: ref.read(openDatasetUseCaseProvider),
        schemaRepository: ref.read(schemaRepositoryProvider),
        fetchRows: ref.read(fetchRowsUseCaseProvider),
      )..add(LoadDatasetEvent(datasetId)),
      child: AppScaffold(
        title: AppStrings.datasetWorkspaceTitle.tr(),
        body: BlocBuilder<DatasetBloc, DatasetState>(
          builder: (context, state) {
            return switch (state) {
              DatasetInitialState() ||
              DatasetLoadingState() =>
                const Center(child: CircularProgressIndicator()),
              DatasetEmptyState(:final dataset) =>
                _EmptyWorkspace(dataset: dataset),
              DatasetLoadedState() => _LoadedWorkspace(state: state),
              DatasetErrorState(:final code) => _WorkspaceError(
                  code: code,
                  datasetId: datasetId,
                ),
            };
          },
        ),
      ),
    );
  }
}

class _LoadedWorkspace extends StatelessWidget {
  final DatasetLoadedState state;

  const _LoadedWorkspace({
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<DatasetBloc>().add(const RefreshResultsEvent());
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DatasetHeader(
            dataset: state.dataset,
            activeTable: state.activeTable,
            tables: state.tables,
            columns: state.columns,
            loadedRowCount: state.rows.length,
            rowLimit: state.rowLimit,
            viewMode: state.viewMode,
          ),
          const SizedBox(height: 16),
          _SheetSelector(
            tables: state.tables,
            activeTable: state.activeTable,
          ),
          const SizedBox(height: 16),
          if (state.rows.isEmpty)
            _NoRowsMessage(columns: state.columns)
          else if (state.viewMode == DatasetViewMode.table)
            DatasetTableView(
              columns: state.columns,
              rows: state.rows,
            )
          else
            DatasetCardView(
              columns: state.columns,
              rows: state.rows,
            ),
        ],
      ),
    );
  }
}

class _DatasetHeader extends StatelessWidget {
  final Dataset dataset;
  final DatasetTable activeTable;
  final List<DatasetTable> tables;
  final List<DatasetColumn> columns;
  final int loadedRowCount;
  final int rowLimit;
  final DatasetViewMode viewMode;

  const _DatasetHeader({
    required this.dataset,
    required this.activeTable,
    required this.tables,
    required this.columns,
    required this.loadedRowCount,
    required this.rowLimit,
    required this.viewMode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dataset.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${AppStrings.datasetWorkspaceSourceFile.tr()}: '
                    '${dataset.sourceFileName}',
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: AppStrings.refresh.tr(),
              onPressed: () {
                context.read<DatasetBloc>().add(const RefreshResultsEvent());
              },
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricTile(
              label: AppStrings.datasetWorkspaceSheets.tr(),
              value: '${tables.length}',
            ),
            _MetricTile(
              label: AppStrings.datasetWorkspaceColumns.tr(),
              value: '${columns.length}',
            ),
            _MetricTile(
              label: AppStrings.datasetWorkspaceRows.tr(),
              value: '${activeTable.rowCount}',
            ),
            _MetricTile(
              label: AppStrings.datasetWorkspaceLoadedRows.tr(),
              value: '$loadedRowCount / ${activeTable.rowCount}',
            ),
          ],
        ),
        if (activeTable.rowCount > rowLimit && loadedRowCount >= rowLimit) ...[
          const SizedBox(height: 8),
          Text(
            AppStrings.datasetWorkspaceInitialRowLimit.tr(
              namedArgs: {'count': '$rowLimit'},
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 16),
        SegmentedButton<DatasetViewMode>(
          segments: [
            ButtonSegment(
              value: DatasetViewMode.table,
              icon: const Icon(Icons.table_rows),
              label: Text(AppStrings.datasetWorkspaceTableView.tr()),
            ),
            ButtonSegment(
              value: DatasetViewMode.cards,
              icon: const Icon(Icons.view_agenda),
              label: Text(AppStrings.datasetWorkspaceCardView.tr()),
            ),
          ],
          selected: {viewMode},
          onSelectionChanged: (selection) {
            context.read<DatasetBloc>().add(
                  ChangeViewModeEvent(selection.single),
                );
          },
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;

  const _MetricTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 120,
        maxWidth: 180,
        minHeight: 70,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetSelector extends StatelessWidget {
  final List<DatasetTable> tables;
  final DatasetTable activeTable;

  const _SheetSelector({
    required this.tables,
    required this.activeTable,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: activeTable.id,
      decoration: InputDecoration(
        labelText: AppStrings.datasetWorkspaceSelectSheet.tr(),
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final table in tables)
          DropdownMenuItem(
            value: table.id,
            child: Text(table.sheetNameOriginal),
          ),
      ],
      onChanged: (tableId) {
        if (tableId == null) return;

        context.read<DatasetBloc>().add(ChangeSheetEvent(tableId));
      },
    );
  }
}

class _NoRowsMessage extends StatelessWidget {
  final List<DatasetColumn> columns;

  const _NoRowsMessage({
    required this.columns,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.table_chart_outlined, size: 40),
            const SizedBox(height: 12),
            Text(AppStrings.datasetWorkspaceNoRows.tr()),
            if (columns.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final column in columns)
                    Chip(label: Text(column.originalName)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyWorkspace extends StatelessWidget {
  final Dataset dataset;

  const _EmptyWorkspace({
    required this.dataset,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.folder_open, size: 48),
            const SizedBox(height: 16),
            Text(
              dataset.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.datasetWorkspaceNoTables.tr(),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceError extends StatelessWidget {
  final String code;
  final int datasetId;

  const _WorkspaceError({
    required this.code,
    required this.datasetId,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text(
              _workspaceErrorMessage(code).tr(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.tonalIcon(
              onPressed: () {
                context.read<DatasetBloc>().add(LoadDatasetEvent(datasetId));
              },
              icon: const Icon(Icons.refresh),
              label: Text(AppStrings.retry.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

String _workspaceErrorMessage(String code) {
  switch (code) {
    case 'sheet_failed':
      return AppStrings.datasetWorkspaceSheetFailed;
    case 'refresh_failed':
      return AppStrings.datasetWorkspaceRefreshFailed;
    case 'load_failed':
    default:
      return AppStrings.datasetWorkspaceLoadFailed;
  }
}
