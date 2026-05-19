import 'package:easy_localization/easy_localization.dart';
import 'package:exel_category/application/services/export_data_service.dart';
import 'package:exel_category/core/constants/app_strings.dart';
import 'package:exel_category/domain/entities/dataset.dart';
import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/entities/dataset_table.dart';
import 'package:exel_category/domain/entities/exported_file.dart';
import 'package:exel_category/domain/value_objects/export_format.dart';
import 'package:exel_category/presentation/providers/repository_providers.dart';
import 'package:exel_category/presentation/providers/service_providers.dart';
import 'package:exel_category/presentation/providers/usecase_providers.dart';
import 'package:exel_category/presentation/state/dataset_bloc.dart';
import 'package:exel_category/presentation/state/dataset_event.dart';
import 'package:exel_category/presentation/state/dataset_state.dart';
import 'package:exel_category/presentation/widgets/dataset_sections/analytics_section.dart';
import 'package:exel_category/presentation/widgets/dataset_views/dataset_card_view.dart';
import 'package:exel_category/presentation/widgets/dataset_views/dataset_filter_panel.dart';
import 'package:exel_category/presentation/widgets/dataset_views/dataset_table_view.dart';
import 'package:exel_category/presentation/widgets/layout/app_scaffold.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        applyFilters: ref.read(applyFiltersUseCaseProvider),
        updateDatasetUiState: ref.read(updateDatasetUiStateUseCaseProvider),
        analysisService: ref.read(analysisServiceProvider),
      )..add(LoadDatasetEvent(datasetId)),
      child: AppScaffold(
        title: AppStrings.datasetWorkspaceTitle.tr(),
        actions: [
          _DatasetExportAction(
            exportDataService: ref.read(exportDataServiceProvider),
          ),
        ],
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

class _DatasetExportAction extends StatefulWidget {
  final ExportDataService exportDataService;

  const _DatasetExportAction({
    required this.exportDataService,
  });

  @override
  State<_DatasetExportAction> createState() => _DatasetExportActionState();
}

class _DatasetExportActionState extends State<_DatasetExportAction> {
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DatasetBloc, DatasetState>(
      builder: (context, state) {
        final loadedState = state is DatasetLoadedState ? state : null;

        if (_isExporting) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        return PopupMenuButton<ExportFormat>(
          icon: const Icon(Icons.ios_share),
          tooltip: AppStrings.datasetWorkspaceExportTooltip.tr(),
          enabled: loadedState != null,
          onSelected: loadedState == null
              ? null
              : (format) => _export(context, loadedState, format),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: ExportFormat.excel,
              child: Text(AppStrings.datasetWorkspaceExportExcel.tr()),
            ),
            PopupMenuItem(
              value: ExportFormat.csv,
              child: Text(AppStrings.datasetWorkspaceExportCsv.tr()),
            ),
            PopupMenuItem(
              value: ExportFormat.pdf,
              child: Text(AppStrings.datasetWorkspaceExportPdf.tr()),
            ),
            PopupMenuItem(
              value: ExportFormat.sql,
              child: Text(AppStrings.datasetWorkspaceExportSql.tr()),
            ),
          ],
        );
      },
    );
  }

  Future<void> _export(
    BuildContext context,
    DatasetLoadedState state,
    ExportFormat format,
  ) async {
    setState(() {
      _isExporting = true;
    });

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(AppStrings.datasetWorkspaceExportStarted.tr()),
      ),
    );

    try {
      final files = await widget.exportDataService.exportDataset(
        dataset: state.dataset,
        format: format,
      );

      for (final file in files) {
        await FileSaver.instance.saveFile(
          name: file.name,
          bytes: file.bytes,
          ext: file.extension,
          mimeType: _mimeTypeFor(file),
          customMimeType: file.mimeType,
        );
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.datasetWorkspaceExportSuccess.tr(
              namedArgs: {'count': '${files.length}'},
            ),
          ),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(AppStrings.datasetWorkspaceExportFailed.tr()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  MimeType _mimeTypeFor(ExportedFile file) {
    switch (file.format) {
      case ExportFormat.excel:
        return MimeType.microsoftExcel;
      case ExportFormat.csv:
        return MimeType.csv;
      case ExportFormat.pdf:
        return MimeType.pdf;
      case ExportFormat.sql:
        return MimeType.custom;
    }
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
            totalRowCount: state.totalRowCount,
            viewMode: state.viewMode,
          ),
          const SizedBox(height: 16),
          _SheetSelector(
            tables: state.tables,
            activeTable: state.activeTable,
          ),
          const SizedBox(height: 16),
          DatasetFilterPanel(
            columns: state.columns,
            rows: state.rows,
            filters: state.filters,
            onAddFilter: (filter) {
              context.read<DatasetBloc>().add(AddFilterEvent(filter));
            },
            onRemoveFilter: (filterId) {
              context.read<DatasetBloc>().add(RemoveFilterEvent(filterId));
            },
            onClearFilters: () {
              context.read<DatasetBloc>().add(const ClearFiltersEvent());
            },
          ),
          const SizedBox(height: 16),
          if (state.rows.isEmpty)
            _NoRowsMessage(columns: state.columns)
          else if (state.viewMode == DatasetViewMode.table)
            DatasetTableView(
              columns: state.columns,
              rows: state.rows,
              sort: state.sort,
              onSortColumn: (column) {
                context.read<DatasetBloc>().add(
                      ToggleSortColumnEvent(column),
                    );
              },
            )
          else
            DatasetCardView(
              columns: state.columns,
              rows: state.rows,
            ),
          const SizedBox(height: 12),
          _DatasetPaginationControls(state: state),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          AnalyticsSection(state: state),
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
  final int totalRowCount;
  final DatasetViewMode viewMode;

  const _DatasetHeader({
    required this.dataset,
    required this.activeTable,
    required this.tables,
    required this.columns,
    required this.loadedRowCount,
    required this.rowLimit,
    required this.totalRowCount,
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
              value: '$loadedRowCount / $totalRowCount',
            ),
          ],
        ),
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
