import 'package:easy_localization/easy_localization.dart';
import 'package:exlser/application/services/export_data_service.dart';
import 'package:exlser/core/constants/app_strings.dart';
import 'package:exlser/domain/entities/dataset.dart';
import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/entities/dataset_table.dart';
import 'package:exlser/domain/repositories/schema_repository.dart';
import 'package:exlser/presentation/providers/repository_providers.dart';
import 'package:exlser/presentation/providers/service_providers.dart';
import 'package:exlser/presentation/providers/usecase_providers.dart';
import 'package:exlser/presentation/state/dataset_bloc.dart';
import 'package:exlser/presentation/state/dataset_event.dart';
import 'package:exlser/presentation/state/dataset_state.dart';
import 'package:exlser/presentation/views/dataset/widgets/dataset_export_action.dart';
import 'package:exlser/presentation/views/dataset/widgets/dataset_query_mode_panel.dart';
import 'package:exlser/presentation/views/dataset/widgets/dataset_tables_graph_overview.dart';
import 'package:exlser/presentation/views/dataset/widgets/sheet_selector.dart';
import 'package:exlser/presentation/widgets/dataset_sections/analytics_section.dart';
import 'package:exlser/presentation/widgets/dataset_views/dataset_card_view.dart';
import 'package:exlser/presentation/widgets/dataset_views/dataset_table_view.dart';
import 'package:exlser/presentation/widgets/layout/app_shell_actions.dart';
import 'package:exlser/presentation/widgets/layout/scroll_bottom_spacer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DatasetView extends ConsumerStatefulWidget {
  final int datasetId;

  const DatasetView({
    super.key,
    required this.datasetId,
  });

  @override
  ConsumerState<DatasetView> createState() => _DatasetViewState();
}

class _DatasetViewState extends ConsumerState<DatasetView> {
  late final DatasetBloc _bloc;
  late final ExportDataService _exportDataService;
  late final SchemaRepository _schemaRepository;
  late final AppShellActionsNotifier _shellActions;

  static const String _exportActionId = 'dataset_export_action';

  @override
  void initState() {
    super.initState();

    _shellActions = ref.read(appShellActionsProvider.notifier);
    _exportDataService = ref.read(exportDataServiceProvider);
    _schemaRepository = ref.read(schemaRepositoryProvider);
    _bloc = DatasetBloc(
      openDataset: ref.read(openDatasetUseCaseProvider),
      schemaRepository: ref.read(schemaRepositoryProvider),
      fetchRows: ref.read(fetchRowsUseCaseProvider),
      applyFilters: ref.read(applyFiltersUseCaseProvider),
      executeReadOnlyQuery: ref.read(executeReadOnlyQueryUseCaseProvider),
      updateDatasetUiState: ref.read(updateDatasetUiStateUseCaseProvider),
      analysisService: ref.read(analysisServiceProvider),
    )..add(LoadDatasetEvent(widget.datasetId));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _shellActions.setAction(
        AppShellAction(
          id: _exportActionId,
          builder: (_) => DatasetExportAction(
            bloc: _bloc,
            exportDataService: _exportDataService,
            schemaRepository: _schemaRepository,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_shellActions.mounted) {
        _shellActions.removeAction(_exportActionId);
      }
    });
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocBuilder<DatasetBloc, DatasetState>(
        builder: (context, state) {
          return switch (state) {
            DatasetInitialState() ||
            DatasetLoadingState() =>
              const Center(child: CircularProgressIndicator()),
            DatasetEmptyState(:final dataset) => _EmptyWorkspace(
                dataset: dataset,
              ),
            DatasetLoadedState() => _LoadedWorkspace(state: state),
            DatasetErrorState(:final code) => _WorkspaceError(
                code: code,
                datasetId: widget.datasetId,
              ),
          };
        },
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
    final visibleColumns = state.visibleColumns;
    final isQueryMode = state.isReadOnlyQueryMode;
    final resultColumns =
        isQueryMode ? state.readOnlyQueryColumns : visibleColumns;
    final resultRows = isQueryMode ? state.readOnlyQueryRows : state.rows;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<DatasetBloc>().add(const RefreshResultsEvent());
      },
      child: ListView(
        key: PageStorageKey(
          'dataset_workspace_${state.dataset.id}_${state.queryMode.name}',
        ),
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DatasetHeader(
                    dataset: state.dataset,
                    activeTable: state.activeTable,
                    tables: state.tables,
                    columns: state.columns,
                    visibleColumnCount: visibleColumns.length,
                    loadedRowCount: state.rows.length,
                    rowLimit: state.rowLimit,
                    totalRowCount: state.totalRowCount,
                  ),
                  // A graph of one node says nothing: the overview only earns
                  // its canvas when there are at least two tables to relate.
                  if (state.tables.length >= 2) ...[
                    const SizedBox(height: 16),
                    DatasetTablesGraphOverview(
                      dataset: state.dataset,
                      tables: state.tables,
                      activeTable: state.activeTable,
                      columnsByTableId: state.columnsByTableId,
                      savedNodePositions: state.graphNodePositions,
                    ),
                  ],
                  const SizedBox(height: 16),
                  SheetSelector(
                    tables: state.tables,
                    activeTable: state.activeTable,
                  ),
                  const SizedBox(height: 16),
                  _ViewModeSelector(viewMode: state.viewMode),
                  const SizedBox(height: 16),
                  DatasetQueryModePanel(state: state),
                  const SizedBox(height: 16),
                  if (!isQueryMode) ...[
                    _ColumnVisibilitySection(
                      columns: state.columns,
                      hiddenColumnDbNames: state.hiddenColumnDbNames,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (state.isTableSwitching) ...[
                    const LinearProgressIndicator(minHeight: 3),
                    const SizedBox(height: 12),
                  ],
                  AnimatedOpacity(
                    opacity: state.isTableSwitching ? 0.45 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: IgnorePointer(
                      ignoring: state.isTableSwitching,
                      child: isQueryMode &&
                              resultRows.isEmpty &&
                              !state.hasReadOnlyQueryRun &&
                              state.readOnlyQueryErrorCode == null
                          ? _QueryEmptyMessage()
                          : (resultRows.isEmpty
                              ? _NoRowsMessage(columns: resultColumns)
                              : (state.viewMode == DatasetViewMode.table
                                  ? DatasetTableView(
                                      columns: resultColumns,
                                      rows: resultRows,
                                      sort: isQueryMode ? null : state.sort,
                                      onSortColumn: isQueryMode
                                          ? null
                                          : (column) {
                                              context.read<DatasetBloc>().add(
                                                    ToggleSortColumnEvent(
                                                        column),
                                                  );
                                            },
                                      columnCurrencySymbols:
                                          state.columnCurrencySymbols,
                                    )
                                  : DatasetCardView(
                                      columns: resultColumns,
                                      rows: resultRows,
                                      columnCurrencySymbols:
                                          state.columnCurrencySymbols,
                                    ))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!isQueryMode) ...[
                    _DatasetPaginationControls(state: state),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 8),
                    AnalyticsSection(state: state),
                  ] else if (resultRows.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 8),
                    AnalyticsSection(state: state),
                  ],
                ],
              ),
            ),
          ),
          const ScrollBottomSpacer(),
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
  final int visibleColumnCount;
  final int loadedRowCount;
  final int rowLimit;
  final int totalRowCount;

  const _DatasetHeader({
    required this.dataset,
    required this.activeTable,
    required this.tables,
    required this.columns,
    required this.visibleColumnCount,
    required this.loadedRowCount,
    required this.rowLimit,
    required this.totalRowCount,
  });

  @override
  Widget build(BuildContext context) {
    final uniqueSheets = tables.map((t) => t.effectiveSourceSheetName).toSet();
    final hasMultipleTablesPerSheet = uniqueSheets.length < tables.length;

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
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (hasMultipleTablesPerSheet) ...[
              _MetricTile(
                label: AppStrings.datasetWorkspaceSheets.tr(),
                value: '${uniqueSheets.length}',
              ),
              _MetricTile(
                label: AppStrings.datasetWorkspaceTable.tr(),
                value: '${tables.length}',
              ),
            ] else ...[
              _MetricTile(
                label: AppStrings.datasetWorkspaceSheets.tr(),
                value: '${tables.length}',
              ),
            ],
            _MetricTile(
              label: AppStrings.datasetWorkspaceColumns.tr(),
              value: visibleColumnCount == columns.length
                  ? '${columns.length}'
                  : '$visibleColumnCount / ${columns.length}',
            ),
            _MetricTile(
              label: AppStrings.datasetWorkspaceRows.tr(),
              value: '${activeTable.rowCount}',
            ),
            _MetricTile(
              label: AppStrings.datasetWorkspaceLoadedRows.tr(),
              value: '$loadedRowCount / $totalRowCount',
            ),
          ],
        ),
      ],
    );
  }
}

class _ViewModeSelector extends StatelessWidget {
  final DatasetViewMode viewMode;

  const _ViewModeSelector({
    required this.viewMode,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 420) {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ViewModeChip(
                viewMode: DatasetViewMode.table,
                selectedViewMode: viewMode,
                icon: Icons.table_rows,
                label: AppStrings.datasetWorkspaceTableView.tr(),
              ),
              _ViewModeChip(
                viewMode: DatasetViewMode.cards,
                selectedViewMode: viewMode,
                icon: Icons.view_agenda,
                label: AppStrings.datasetWorkspaceCardView.tr(),
              ),
            ],
          );
        }

        return SegmentedButton<DatasetViewMode>(
          showSelectedIcon: false,
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
        );
      },
    );
  }
}

class _ViewModeChip extends StatelessWidget {
  final DatasetViewMode viewMode;
  final DatasetViewMode selectedViewMode;
  final IconData icon;
  final String label;

  const _ViewModeChip({
    required this.viewMode,
    required this.selectedViewMode,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: selectedViewMode == viewMode,
      onSelected: (_) {
        context.read<DatasetBloc>().add(ChangeViewModeEvent(viewMode));
      },
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

class _ColumnVisibilitySection extends StatelessWidget {
  final List<DatasetColumn> columns;
  final List<String> hiddenColumnDbNames;

  const _ColumnVisibilitySection({
    required this.columns,
    required this.hiddenColumnDbNames,
  });

  @override
  Widget build(BuildContext context) {
    if (columns.isEmpty) {
      return const SizedBox.shrink();
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.datasetWorkspaceVisibleColumns.tr(),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.datasetWorkspaceVisibleColumnsHint.tr(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final column in columns)
                  FilterChip(
                    label: Text(column.originalName),
                    selected: !hiddenColumnDbNames.contains(column.dbName),
                    onSelected: (selected) {
                      context.read<DatasetBloc>().add(
                            SetColumnHiddenEvent(
                              columnDbName: column.dbName,
                              hidden: !selected,
                            ),
                          );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DatasetPaginationControls extends StatefulWidget {
  final DatasetLoadedState state;

  const _DatasetPaginationControls({
    required this.state,
  });

  @override
  State<_DatasetPaginationControls> createState() =>
      _DatasetPaginationControlsState();
}

class _DatasetPaginationControlsState
    extends State<_DatasetPaginationControls> {
  late final TextEditingController _limitController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _limitController = TextEditingController(
      text: widget.state.rowLimit.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant _DatasetPaginationControls oldWidget) {
    super.didUpdateWidget(oldWidget);

    final currentText = _limitController.text.trim();
    final currentValue = int.tryParse(currentText);
    if (currentValue == oldWidget.state.rowLimit &&
        widget.state.rowLimit != oldWidget.state.rowLimit) {
      _limitController.text = widget.state.rowLimit.toString();
      _errorText = null;
    }
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final firstRow =
        state.totalRowCount == 0 ? 0 : (state.pageIndex * state.rowLimit) + 1;
    final lastRow = state.totalRowCount == 0
        ? 0
        : (state.pageIndex * state.rowLimit + state.rows.length);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 150,
              child: TextField(
                controller: _limitController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: AppStrings.datasetWorkspaceRowsPerPage.tr(),
                  border: const OutlineInputBorder(),
                  isDense: true,
                  errorText: _errorText,
                ),
                onSubmitted: (_) => _applyLimit(context),
              ),
            ),
            FilledButton.tonal(
              onPressed: () => _applyLimit(context),
              child: Text(AppStrings.apply.tr()),
            ),
            Text(
              AppStrings.datasetWorkspacePaginationRange.tr(
                namedArgs: {
                  'from': '$firstRow',
                  'to': '$lastRow',
                  'total': '${state.totalRowCount}',
                },
              ),
            ),
            Text(
              AppStrings.datasetWorkspacePaginationPage.tr(
                namedArgs: {
                  'page': '${state.pageNumber}',
                  'pages': '${state.pageCount}',
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: AppStrings.previous.tr(),
              onPressed: state.canGoToPreviousPage
                  ? () {
                      context
                          .read<DatasetBloc>()
                          .add(ChangePageEvent(state.pageIndex - 1));
                    }
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: AppStrings.next.tr(),
              onPressed: state.canGoToNextPage
                  ? () {
                      context
                          .read<DatasetBloc>()
                          .add(ChangePageEvent(state.pageIndex + 1));
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _applyLimit(BuildContext context) {
    final value = int.tryParse(_limitController.text.trim());
    if (value == null || value <= 0) {
      setState(() {
        _errorText = AppStrings.datasetWorkspacePaginationInvalidLimit.tr();
      });
      return;
    }

    setState(() {
      _errorText = null;
    });
    context.read<DatasetBloc>().add(ChangeRowLimitEvent(value));
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

class _QueryEmptyMessage extends StatelessWidget {
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
            const Icon(Icons.terminal, size: 40),
            const SizedBox(height: 12),
            Text(
              AppStrings.datasetWorkspaceQueryEmptyResult.tr(),
              textAlign: TextAlign.center,
            ),
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
    case 'filter_failed':
      return AppStrings.datasetWorkspaceFilterFailed;
    case 'sort_failed':
      return AppStrings.datasetWorkspaceSortFailed;
    case 'pagination_failed':
      return AppStrings.datasetWorkspacePaginationFailed;
    case 'sheet_failed':
      return AppStrings.datasetWorkspaceSheetFailed;
    case 'refresh_failed':
      return AppStrings.datasetWorkspaceRefreshFailed;
    case 'load_failed':
    default:
      return AppStrings.datasetWorkspaceLoadFailed;
  }
}
