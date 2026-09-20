import 'package:easy_localization/easy_localization.dart';
import 'package:exlser/core/constants/app_strings.dart';
import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/entities/dataset_table.dart';
import 'package:exlser/domain/value_objects/dataset_query_mode.dart';
import 'package:exlser/presentation/widgets/dataset_views/dataset_filter_panel.dart';
import 'package:exlser/presentation/state/dataset_bloc.dart';
import 'package:exlser/presentation/state/dataset_event.dart';
import 'package:exlser/presentation/state/dataset_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DatasetQueryModePanel extends StatelessWidget {
  final DatasetLoadedState state;

  const DatasetQueryModePanel({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: _QueryModeSelector(queryMode: state.queryMode),
        ),
        const SizedBox(height: 12),
        if (state.queryMode == DatasetQueryMode.filters)
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
          )
        else
          _ReadOnlyQueryPanel(state: state),
      ],
    );
  }
}

class _QueryModeSelector extends StatelessWidget {
  final DatasetQueryMode queryMode;

  const _QueryModeSelector({
    required this.queryMode,
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
              _QueryModeChip(
                queryMode: DatasetQueryMode.filters,
                selectedQueryMode: queryMode,
                icon: Icons.filter_alt_outlined,
                label: AppStrings.datasetWorkspaceQueryTabFilters.tr(),
              ),
              _QueryModeChip(
                queryMode: DatasetQueryMode.sql,
                selectedQueryMode: queryMode,
                icon: Icons.terminal,
                label: AppStrings.datasetWorkspaceQueryTabSql.tr(),
              ),
            ],
          );
        }

        return SegmentedButton<DatasetQueryMode>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: DatasetQueryMode.filters,
              icon: const Icon(Icons.filter_alt_outlined),
              label: Text(AppStrings.datasetWorkspaceQueryTabFilters.tr()),
            ),
            ButtonSegment(
              value: DatasetQueryMode.sql,
              icon: const Icon(Icons.terminal),
              label: Text(AppStrings.datasetWorkspaceQueryTabSql.tr()),
            ),
          ],
          selected: {queryMode},
          onSelectionChanged: (selection) {
            context.read<DatasetBloc>().add(
                  ChangeQueryModeEvent(selection.single),
                );
          },
        );
      },
    );
  }
}

class _QueryModeChip extends StatelessWidget {
  final DatasetQueryMode queryMode;
  final DatasetQueryMode selectedQueryMode;
  final IconData icon;
  final String label;

  const _QueryModeChip({
    required this.queryMode,
    required this.selectedQueryMode,
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
      selected: selectedQueryMode == queryMode,
      onSelected: (_) {
        context.read<DatasetBloc>().add(ChangeQueryModeEvent(queryMode));
      },
    );
  }
}

class _SqlHighlightingTextEditingController extends TextEditingController {
  static final RegExp _keywordPattern = RegExp(
    r'\b(SELECT|FROM|WHERE|JOIN|LEFT|RIGHT|INNER|OUTER|ON|AS|AND|OR|NOT|IN|IS|NULL|LIKE|BETWEEN|GROUP|BY|ORDER|HAVING|LIMIT|OFFSET|DISTINCT|COUNT|SUM|AVG|MIN|MAX)\b',
    caseSensitive: false,
  );

  _SqlHighlightingTextEditingController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final keywordStyle = style?.copyWith(
      color: const Color(0xFFC2185B),
      fontWeight: FontWeight.w600,
    );
    final spans = <TextSpan>[];
    var currentIndex = 0;

    for (final match in _keywordPattern.allMatches(text)) {
      if (match.start > currentIndex) {
        spans.add(TextSpan(text: text.substring(currentIndex, match.start)));
      }
      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: keywordStyle,
      ));
      currentIndex = match.end;
    }

    if (currentIndex < text.length) {
      spans.add(TextSpan(text: text.substring(currentIndex)));
    }

    return TextSpan(style: style, children: spans);
  }
}

class _ReadOnlyQueryPanel extends StatefulWidget {
  final DatasetLoadedState state;

  const _ReadOnlyQueryPanel({
    required this.state,
  });

  @override
  State<_ReadOnlyQueryPanel> createState() => _ReadOnlyQueryPanelState();
}

class _ReadOnlyQueryPanelState extends State<_ReadOnlyQueryPanel> {
  late final _SqlHighlightingTextEditingController _queryController;
  late final TextEditingController _limitController;
  final FocusNode _queryFocusNode = FocusNode();
  String? _limitError;

  @override
  void initState() {
    super.initState();
    _queryController = _SqlHighlightingTextEditingController(
      text: widget.state.readOnlyQuery.sql,
    );
    _limitController = TextEditingController(
      text: widget.state.readOnlyQuery.limit.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant _ReadOnlyQueryPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_queryController.text != widget.state.readOnlyQuery.sql) {
      _queryController.text = widget.state.readOnlyQuery.sql;
    }
    if (_limitController.text != widget.state.readOnlyQuery.limit.toString()) {
      _limitController.text = widget.state.readOnlyQuery.limit.toString();
      _limitError = null;
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    _limitController.dispose();
    _queryFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final errorCode = widget.state.readOnlyQueryErrorCode;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.datasetWorkspaceQueryTitle.tr(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (widget.state.isReadOnlyQueryRunning)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.datasetWorkspaceQueryIntro.tr(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _queryController,
              focusNode: _queryFocusNode,
              minLines: 4,
              maxLines: 8,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                labelText: AppStrings.datasetWorkspaceQueryEditor.tr(),
                border: const OutlineInputBorder(),
                errorText: errorCode == null
                    ? null
                    : _readOnlyQueryErrorMessage(errorCode).tr(),
              ),
              onChanged: (value) {
                context.read<DatasetBloc>().add(
                      UpdateReadOnlyQueryEvent(value),
                    );
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 140,
                  child: TextField(
                    controller: _limitController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: AppStrings.datasetWorkspaceQueryLimit.tr(),
                      border: const OutlineInputBorder(),
                      isDense: true,
                      errorText: _limitError,
                    ),
                    onSubmitted: (_) => _applyLimit(context),
                  ),
                ),
                FilledButton.icon(
                  onPressed: widget.state.isReadOnlyQueryRunning
                      ? null
                      : () {
                          if (_applyLimit(context)) {
                            context
                                .read<DatasetBloc>()
                                .add(const RunReadOnlyQueryEvent());
                          }
                        },
                  icon: const Icon(Icons.play_arrow),
                  label: Text(AppStrings.run.tr()),
                ),
                TextButton.icon(
                  onPressed: () {
                    context
                        .read<DatasetBloc>()
                        .add(const ResetReadOnlyQueryEvent());
                  },
                  icon: const Icon(Icons.restart_alt),
                  label: Text(AppStrings.datasetWorkspaceQueryReset.tr()),
                ),
                TextButton.icon(
                  onPressed: () {
                    context
                        .read<DatasetBloc>()
                        .add(const ClearReadOnlyQueryEvent());
                  },
                  icon: const Icon(Icons.clear),
                  label: Text(AppStrings.clear.tr()),
                ),
                if (widget.state.hasReadOnlyQueryRun &&
                    widget.state.readOnlyQueryErrorCode == null)
                  _QueryResultSummaryNotice(
                    shownRows: widget.state.readOnlyQueryRows.length,
                    totalRows: widget.state.readOnlyQueryTotalRowCount,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _QuerySchemaHelper(
              state: widget.state,
              onInsert: _insertIdentifier,
            ),
          ],
        ),
      ),
    );
  }

  bool _applyLimit(BuildContext context) {
    final limit = int.tryParse(_limitController.text.trim());
    if (limit == null || limit <= 0) {
      setState(() {
        _limitError = AppStrings.datasetWorkspaceQueryErrorInvalidLimit.tr();
      });
      return false;
    }

    setState(() {
      _limitError = null;
    });
    context.read<DatasetBloc>().add(ChangeReadOnlyQueryLimitEvent(limit));
    return true;
  }

  void _insertIdentifier(String text) {
    final selection = _queryController.selection;
    final start =
        selection.start < 0 ? _queryController.text.length : selection.start;
    final end =
        selection.end < 0 ? _queryController.text.length : selection.end;
    final updated = _queryController.text.replaceRange(start, end, text);

    _queryController.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: start + text.length),
    );
    _queryFocusNode.requestFocus();
    context.read<DatasetBloc>().add(UpdateReadOnlyQueryEvent(updated));
  }
}

class _QueryResultSummaryNotice extends StatelessWidget {
  final int shownRows;
  final int totalRows;

  const _QueryResultSummaryNotice({
    required this.shownRows,
    required this.totalRows,
  });

  @override
  Widget build(BuildContext context) {
    final hasResults = totalRows > 0;
    final colorScheme = Theme.of(context).colorScheme;
    final color = hasResults ? Colors.green.shade700 : colorScheme.error;
    final background = hasResults
        ? Colors.green.withValues(alpha: 0.08)
        : colorScheme.errorContainer.withValues(alpha: 0.35);
    final icon = hasResults ? Icons.check_circle_outline : Icons.info_outline;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                AppStrings.datasetWorkspaceQueryResultSummary.tr(
                  namedArgs: {
                    'shown': '$shownRows',
                    'total': '$totalRows',
                  },
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuerySchemaHelper extends StatelessWidget {
  final DatasetLoadedState state;
  final ValueChanged<String> onInsert;

  const _QuerySchemaHelper({
    required this.state,
    required this.onInsert,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.datasetWorkspaceQuerySchema.tr(),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.datasetWorkspaceQueryActiveContext.tr(
                namedArgs: {'table': state.activeTable.sqlTableName},
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.short_text, size: 18),
                  label: const Text('sheet'),
                  tooltip: AppStrings.datasetWorkspaceQueryInsertTable.tr(),
                  onPressed: () => onInsert('sheet'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final table in state.tables) ...[
              _QuerySchemaTableRow(
                table: table,
                columns: state.columnsByTableId[table.id] ??
                    (table.id == state.activeTable.id
                        ? state.columns
                        : const <DatasetColumn>[]),
                isActive: table.id == state.activeTable.id,
                onInsert: onInsert,
              ),
              if (table.id != state.tables.last.id) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuerySchemaTableRow extends StatelessWidget {
  final DatasetTable table;
  final List<DatasetColumn> columns;
  final bool isActive;
  final ValueChanged<String> onInsert;

  const _QuerySchemaTableRow({
    required this.table,
    required this.columns,
    required this.isActive,
    required this.onInsert,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ActionChip(
          avatar: Icon(
            isActive ? Icons.article : Icons.article_outlined,
            size: 18,
          ),
          label: Text(table.sheetNameOriginal),
          tooltip: '${AppStrings.datasetWorkspaceQueryInsertTable.tr()}: '
              '${table.sqlTableName}',
          onPressed: () => onInsert(_quoteIdentifier(table.sqlTableName)),
        ),
        Text(
          ':',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        for (final column in columns)
          ActionChip(
            avatar: const Icon(Icons.view_column_outlined, size: 18),
            label: Text(column.originalName),
            tooltip: '${AppStrings.datasetWorkspaceQueryInsertColumn.tr()}: '
                '${table.sqlTableName}.${column.dbName}',
            onPressed: () => onInsert(_quoteIdentifier(column.dbName)),
          ),
      ],
    );
  }
}

String _readOnlyQueryErrorMessage(String code) {
  switch (code) {
    case 'empty':
      return AppStrings.datasetWorkspaceQueryErrorEmpty;
    case 'not_select':
      return AppStrings.datasetWorkspaceQueryErrorNotSelect;
    case 'unsafe_statement':
      return AppStrings.datasetWorkspaceQueryErrorUnsafe;
    case 'multiple_statements':
      return AppStrings.datasetWorkspaceQueryErrorMultiple;
    case 'invalid_syntax':
      return AppStrings.datasetWorkspaceQueryErrorInvalidSyntax;
    case 'unknown_table':
      return AppStrings.datasetWorkspaceQueryErrorUnknownTable;
    case 'invalid_limit':
      return AppStrings.datasetWorkspaceQueryErrorInvalidLimit;
    case 'execution_failed':
    default:
      return AppStrings.datasetWorkspaceQueryErrorExecution;
  }
}

String _quoteIdentifier(String value) {
  return '"${value.replaceAll('"', '""')}"';
}
