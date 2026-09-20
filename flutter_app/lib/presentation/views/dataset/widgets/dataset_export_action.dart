import 'package:easy_localization/easy_localization.dart';
import 'package:exlser/application/services/export_data_service.dart';
import 'package:exlser/core/constants/app_strings.dart';
import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/repositories/schema_repository.dart';
import 'package:exlser/domain/value_objects/dataset_filter.dart';
import 'package:exlser/domain/value_objects/dataset_sort.dart';
import 'package:exlser/domain/value_objects/export_format.dart';
import 'package:exlser/domain/value_objects/pdf_export_layout.dart';
import 'package:exlser/core/diagnostics/recovered_error.dart';
import 'package:exlser/presentation/state/dataset_bloc.dart';
import 'package:exlser/presentation/state/dataset_state.dart';
import 'package:exlser/presentation/state/dataset_workspace_ui_state.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

class DatasetExportAction extends StatefulWidget {
  final DatasetBloc bloc;
  final ExportDataService exportDataService;
  final SchemaRepository schemaRepository;

  const DatasetExportAction({
    super.key,
    required this.bloc,
    required this.exportDataService,
    required this.schemaRepository,
  });

  @override
  State<DatasetExportAction> createState() => _DatasetExportActionState();
}

class _DatasetExportActionState extends State<DatasetExportAction> {
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DatasetBloc, DatasetState>(
      bloc: widget.bloc,
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

        return IconButton(
          icon: const Icon(Icons.ios_share),
          tooltip: AppStrings.datasetWorkspaceExportTooltip.tr(),
          onPressed: loadedState == null
              ? null
              : () => _showExportDialog(context, loadedState),
        );
      },
    );
  }

  Future<void> _showExportDialog(
    BuildContext context,
    DatasetLoadedState state,
  ) async {
    final result = await showDialog<_ExportDialogResult>(
      context: context,
      builder: (context) => _ExportDialog(state: state),
    );

    if (result == null || !context.mounted) {
      return;
    }

    await _export(context, state, result);
  }

  Future<void> _export(
    BuildContext context,
    DatasetLoadedState state,
    _ExportDialogResult result,
  ) async {
    setState(() {
      _isExporting = true;
    });

    final messenger = ScaffoldMessenger.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    messenger.showSnackBar(
      SnackBar(
        content: Text(AppStrings.datasetWorkspaceExportStarted.tr()),
      ),
    );

    try {
      final selectedTables = [
        for (final table in state.tables)
          if (result.tableIds.contains(table.id)) table,
      ];
      final workspaceState = DatasetWorkspaceUiState.fromJsonString(
        state.dataset.uiStateJson,
      );
      final visibleColumnsByTableId = <int, List<DatasetColumn>>{};
      final filtersByTableId = <int, List<DatasetFilter>>{};
      final sortByTableId = <int, DatasetSort?>{};

      for (final table in selectedTables) {
        final isActiveTable = table.id == state.activeTable.id;
        final columns = isActiveTable
            ? state.columns
            : await widget.schemaRepository.getColumnsForTable(table.id);
        final hiddenColumnDbNames = isActiveTable
            ? state.hiddenColumnDbNames
            : workspaceState.restoreHiddenColumnDbNames(
                columns,
                tableId: table.id,
              );

        visibleColumnsByTableId[table.id] = [
          for (final column in columns)
            if (!hiddenColumnDbNames.contains(column.dbName)) column,
        ];
        filtersByTableId[table.id] = isActiveTable
            ? state.filters
            : workspaceState.restoreFilters(columns, tableId: table.id);
        sortByTableId[table.id] = isActiveTable
            ? state.sort
            : workspaceState.restoreSort(columns, tableId: table.id);
      }

      final files = await widget.exportDataService.exportSelectedTables(
        dataset: state.dataset,
        selectedTables: selectedTables,
        visibleColumnsByTableId: visibleColumnsByTableId,
        filtersByTableId: filtersByTableId,
        sortByTableId: sortByTableId,
        format: result.format,
        pdfLayout: result.pdfLayout,
      );

      if (kIsWeb || defaultTargetPlatform == TargetPlatform.iOS) {
        await SharePlus.instance.share(
          ShareParams(
            files: [
              for (final file in files)
                XFile.fromData(
                  file.bytes,
                  mimeType: file.mimeType,
                  name: file.fileName,
                ),
            ],
            fileNameOverrides: [for (final file in files) file.fileName],
            sharePositionOrigin: renderBox == null
                ? null
                : renderBox.localToGlobal(Offset.zero) & renderBox.size,
            downloadFallbackEnabled: true,
          ),
        );
      } else {
        for (final file in files) {
          await FilePicker.saveFile(
            dialogTitle: file.fileName,
            fileName: file.fileName,
            bytes: file.bytes,
            mimeType: file.mimeType,
          );
        }
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
    } catch (error, stackTrace) {
      recordRecoveredError(error, stackTrace, context: 'DatasetView');
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
}

class _ExportDialogResult {
  final Set<int> tableIds;
  final ExportFormat format;
  final PdfExportLayout pdfLayout;

  const _ExportDialogResult({
    required this.tableIds,
    required this.format,
    required this.pdfLayout,
  });
}

class _ExportDialog extends StatefulWidget {
  final DatasetLoadedState state;

  const _ExportDialog({
    required this.state,
  });

  @override
  State<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<_ExportDialog> {
  late Set<int> _selectedTableIds;
  ExportFormat _format = ExportFormat.excel;
  PdfExportLayout _pdfLayout = PdfExportLayout.table;

  @override
  void initState() {
    super.initState();
    _selectedTableIds = {widget.state.activeTable.id};
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppStrings.datasetWorkspaceExportDialogTitle.tr()),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.datasetWorkspaceExportSheets.tr(),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.article_outlined, size: 18),
                    label: Text(
                      AppStrings.datasetWorkspaceExportCurrentSheet.tr(),
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedTableIds = {widget.state.activeTable.id};
                      });
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.dataset_outlined, size: 18),
                    label:
                        Text(AppStrings.datasetWorkspaceExportAllSheets.tr()),
                    onPressed: () {
                      setState(() {
                        _selectedTableIds = {
                          for (final table in widget.state.tables) table.id,
                        };
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final table in widget.state.tables)
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: _selectedTableIds.contains(table.id),
                  title: Text(table.sheetNameOriginal),
                  subtitle: table.id == widget.state.activeTable.id
                      ? Text(
                          AppStrings.datasetWorkspaceExportCurrentSheet.tr(),
                        )
                      : null,
                  onChanged: (selected) {
                    setState(() {
                      if (selected ?? false) {
                        _selectedTableIds.add(table.id);
                      } else {
                        _selectedTableIds.remove(table.id);
                      }
                    });
                  },
                ),
              if (_selectedTableIds.isEmpty)
                Text(
                  AppStrings.datasetWorkspaceExportNoSheetSelected.tr(),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 16),
              Text(
                AppStrings.datasetWorkspaceExportFormat.tr(),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final format in ExportFormat.values)
                    ChoiceChip(
                      label: Text(_formatLabel(format).tr()),
                      selected: _format == format,
                      onSelected: (_) {
                        setState(() {
                          _format = format;
                        });
                      },
                    ),
                ],
              ),
              if (_format == ExportFormat.pdf) ...[
                const SizedBox(height: 16),
                Text(
                  AppStrings.datasetWorkspaceExportPdfLayout.tr(),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                SegmentedButton<PdfExportLayout>(
                  segments: [
                    ButtonSegment(
                      value: PdfExportLayout.table,
                      icon: const Icon(Icons.table_rows),
                      label: Text(
                        AppStrings.datasetWorkspaceExportPdfTable.tr(),
                      ),
                    ),
                    ButtonSegment(
                      value: PdfExportLayout.cards,
                      icon: const Icon(Icons.view_agenda),
                      label: Text(
                        AppStrings.datasetWorkspaceExportPdfCards.tr(),
                      ),
                    ),
                  ],
                  selected: {_pdfLayout},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _pdfLayout = selection.single;
                    });
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.cancel.tr()),
        ),
        FilledButton.icon(
          onPressed: _selectedTableIds.isEmpty
              ? null
              : () {
                  Navigator.of(context).pop(
                    _ExportDialogResult(
                      tableIds: Set.unmodifiable(_selectedTableIds),
                      format: _format,
                      pdfLayout: _pdfLayout,
                    ),
                  );
                },
          icon: const Icon(Icons.ios_share),
          label: Text(AppStrings.datasetWorkspaceExportDialogTitle.tr()),
        ),
      ],
    );
  }

  String _formatLabel(ExportFormat format) {
    switch (format) {
      case ExportFormat.excel:
        return AppStrings.datasetWorkspaceExportExcel;
      case ExportFormat.csv:
        return AppStrings.datasetWorkspaceExportCsv;
      case ExportFormat.pdf:
        return AppStrings.datasetWorkspaceExportPdf;
      case ExportFormat.sql:
        return AppStrings.datasetWorkspaceExportSql;
      case ExportFormat.json:
        return AppStrings.datasetWorkspaceExportJson;
    }
  }
}
