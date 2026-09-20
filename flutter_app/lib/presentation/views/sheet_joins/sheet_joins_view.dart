//lib/presentation/views/sheet_joins/sheet_joins_view.dart

import 'package:easy_localization/easy_localization.dart';
import 'package:exlser/core/constants/app_strings.dart';
import 'package:exlser/domain/usecases/multisheet/multi_sheet_join_risk_analyzer.dart';
import 'package:exlser/presentation/views/sheet_joins/join_labels.dart';
import 'package:exlser/presentation/views/sheet_joins/join_section_card.dart';
import 'package:exlser/presentation/views/sheet_joins/join_suggestions_section.dart';
import 'package:exlser/presentation/views/sheet_joins/join_risk_confirmation_dialog.dart';
import 'package:exlser/presentation/views/sheet_joins/multi_sheet_join_controller.dart';
import 'package:exlser/presentation/views/sheet_joins/saved_join_configurations_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:exlser/presentation/router/routes.dart';

enum JoinViewMode { list, graph }

/// Guided workspace to combine two or more sheets of the same dataset.
///
/// Takes only a [datasetId]: it reads everything through
/// [MultiSheetJoinController] and never touches `DatasetBloc`.
class SheetJoinsView extends ConsumerStatefulWidget {
  final int datasetId;

  const SheetJoinsView({super.key, required this.datasetId});

  @override
  ConsumerState<SheetJoinsView> createState() => _SheetJoinsViewState();
}

class _SheetJoinsViewState extends ConsumerState<SheetJoinsView> {
  JoinViewMode _viewMode = JoinViewMode.list;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(multiSheetJoinControllerProvider(widget.datasetId).notifier)
          .load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = multiSheetJoinControllerProvider(widget.datasetId);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);

    if (state.status == MultiSheetJoinStatus.initial ||
        state.status == MultiSheetJoinStatus.loadingMetadata) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              AppStrings.datasetJoinsLoading.tr(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    if (!state.canConfigure) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: IconButton(
              key: const ValueKey('sheet_joins_back_button'),
              icon: const Icon(Icons.arrow_back),
              tooltip: AppStrings.datasetJoinsBack.tr(),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.goNamed(
                    AppRoutes.datasetName,
                    pathParameters: {
                      AppRoutes.datasetIdParam: '${widget.datasetId}',
                    },
                  );
                }
              },
            ),
          ),
          Expanded(
            child: JoinMessage(
              icon: Icons.grid_view_outlined,
              text: AppStrings.datasetJoinsErrorNotEnoughTables.tr(),
            ),
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth >= 720 ? 24.0 : 12.0;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 16,
              ),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      key: const ValueKey('sheet_joins_back_button'),
                      icon: const Icon(Icons.arrow_back),
                      tooltip: AppStrings.datasetJoinsBack.tr(),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.goNamed(
                            AppRoutes.datasetName,
                            pathParameters: {
                              AppRoutes.datasetIdParam: '${widget.datasetId}',
                            },
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppStrings.datasetJoinsSubtitle.tr(),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SavedJoinConfigurationsPanel(
                    state: state, controller: controller),
                const SizedBox(height: 16),
                _SheetPicker(state: state, controller: controller),
                const SizedBox(height: 16),
                if (state.hasEnoughSheets) ...[
                  _BaseSheetPicker(state: state, controller: controller),
                  const SizedBox(height: 16),
                  JoinSuggestionsSection(state: state, controller: controller),
                  const SizedBox(height: 16),
                  JoinRelationshipsSection(
                    state: state,
                    controller: controller,
                    viewMode: _viewMode,
                    onViewModeChanged: (mode) =>
                        setState(() => _viewMode = mode),
                  ),
                  const SizedBox(height: 16),
                  _OutputColumnsSection(state: state, controller: controller),
                  const SizedBox(height: 16),
                ],
                _ErrorBanner(state: state),
                _WarningsBanner(state: state),
                const SizedBox(height: 8),
                _RunBar(state: state, controller: controller),
                const SizedBox(height: 16),
                _PreviewSection(state: state),
                const SizedBox(height: 16),
                _GeneratedSqlSection(state: state),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SheetPicker extends StatelessWidget {
  final MultiSheetJoinState state;
  final MultiSheetJoinController controller;

  const _SheetPicker({required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    return JoinSectionCard(
      title: AppStrings.datasetJoinsSelectSheets.tr(),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final sheet in state.sheets)
            FilterChip(
              key: ValueKey('join_sheet_${sheet.tableId}'),
              label: Text(sheet.label),
              showCheckmark: false,
              selected: state.spec.selectedTableIds.contains(sheet.tableId),
              onSelected: (_) => controller.toggleSheet(sheet.tableId),
            ),
        ],
      ),
    );
  }
}

class _BaseSheetPicker extends StatelessWidget {
  final MultiSheetJoinState state;
  final MultiSheetJoinController controller;

  const _BaseSheetPicker({required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    final selected = state.sheets
        .where((s) => state.spec.selectedTableIds.contains(s.tableId))
        .toList();

    return JoinSectionCard(
      title: AppStrings.datasetJoinsBaseSheet.tr(),
      hint: AppStrings.datasetJoinsBaseSheetHint.tr(),
      child: DropdownButtonFormField<int>(
        key: const ValueKey('join_base_sheet'),
        isExpanded: true,
        initialValue: state.spec.baseTableId,
        items: [
          for (final sheet in selected)
            DropdownMenuItem(
              value: sheet.tableId,
              child: Text(sheet.label, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (value) {
          if (value != null) controller.setBaseTable(value);
        },
      ),
    );
  }
}

class _OutputColumnsSection extends StatelessWidget {
  final MultiSheetJoinState state;
  final MultiSheetJoinController controller;

  const _OutputColumnsSection({required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    final selected = state.sheets
        .where((s) => state.spec.selectedTableIds.contains(s.tableId))
        .toList();

    return JoinSectionCard(
      title: AppStrings.datasetJoinsOutputColumns.tr(),
      hint: AppStrings.datasetJoinsOutputColumnsHint.tr(),
      child: Column(
        children: [
          for (final sheet in selected)
            ExpansionTile(
              key: ValueKey('join_columns_${sheet.tableId}'),
              tilePadding: EdgeInsets.zero,
              title: Text(sheet.label),
              subtitle: Text(
                '${state.spec.columnsForTable(sheet.tableId).length}/${sheet.columns.length}',
              ),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final column in sheet.columns)
                      FilterChip(
                        label: Text(column.originalName),
                        showCheckmark: false,
                        selected: state.spec
                            .columnsForTable(sheet.tableId)
                            .contains(column.dbName),
                        onSelected: (isSelected) {
                          final current = [
                            ...state.spec.columnsForTable(sheet.tableId)
                          ];
                          if (isSelected) {
                            current.add(column.dbName);
                          } else {
                            current.remove(column.dbName);
                          }
                          controller.setColumns(sheet.tableId, current);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final MultiSheetJoinState state;

  const _ErrorBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final code = state.errorCode;
    if (code == null) return const SizedBox.shrink();

    final isStale = state.status == MultiSheetJoinStatus.staleSpec;
    final scheme = Theme.of(context).colorScheme;
    final solution = isStale ? null : joinErrorSolution(code);

    return Card(
      key: const ValueKey('join_error_banner'),
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: scheme.onErrorContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isStale
                        ? AppStrings.datasetJoinsStaleSpec.tr()
                        : joinErrorMessage(code),
                    style: TextStyle(
                      color: scheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (solution != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 18,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        solution,
                        key: const ValueKey('join_error_solution_text'),
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WarningsBanner extends StatelessWidget {
  final MultiSheetJoinState state;

  const _WarningsBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final warnings = state.generated?.warnings ?? const <JoinRiskWarning>[];
    if (warnings.isEmpty) return const SizedBox.shrink();

    return Card(
      key: const ValueKey('join_warning_banner'),
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < warnings.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_outlined),
                  const SizedBox(width: 12),
                  Expanded(child: Text(localizedJoinRiskWarning(warnings[i]))),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RunBar extends StatelessWidget {
  final MultiSheetJoinState state;
  final MultiSheetJoinController controller;

  const _RunBar({required this.state, required this.controller});

  Future<void> _requestPreview(BuildContext context) async {
    final generated = controller.prepare();
    if (generated == null) return;

    if (generated.hasWarnings) {
      final confirmed = await showJoinRiskConfirmationDialog(
        context: context,
        warnings: generated.warnings,
      );
      if (!confirmed || !context.mounted) return;
    }

    await controller.executePreparedPreview();
  }

  @override
  Widget build(BuildContext context) {
    final running = state.status == MultiSheetJoinStatus.executing;

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        key: const ValueKey('join_run_button'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: (!state.hasEnoughSheets || running)
            ? null
            : () => _requestPreview(context),
        icon: running
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.play_arrow),
        label: Text(AppStrings.datasetJoinsRun.tr()),
      ),
    );
  }
}

class _PreviewSection extends StatelessWidget {
  final MultiSheetJoinState state;

  const _PreviewSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final preview = state.preview;
    if (preview == null) return const SizedBox.shrink();

    return JoinSectionCard(
      title: AppStrings.datasetJoinsPreview.tr(),
      hint: AppStrings.datasetJoinsPreviewLimited.tr(
        namedArgs: {'limit': '${preview.limit}'},
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Headers exist even with zero rows, so the table is always meaningful.
          // DataTable asserts on an empty column list, so guard it.
          if (preview.outputColumns.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                key: const ValueKey('join_preview_table'),
                columns: [
                  for (final column in preview.outputColumns)
                    DataColumn(label: Text(column.label)),
                ],
                rows: [
                  for (final row in preview.rows)
                    DataRow(
                      cells: [
                        for (final column in preview.outputColumns)
                          DataCell(Text('${row[column.alias] ?? ''}')),
                      ],
                    ),
                ],
              ),
            ),
          if (preview.isEmpty) ...[
            const SizedBox(height: 12),
            Text(AppStrings.datasetJoinsEmptyResult.tr()),
          ],
          if (preview.isTruncated) ...[
            const SizedBox(height: 12),
            Text(
              AppStrings.datasetJoinsPreviewTruncated.tr(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _GeneratedSqlSection extends StatelessWidget {
  final MultiSheetJoinState state;

  const _GeneratedSqlSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final generated = state.generated;
    if (generated == null) return const SizedBox.shrink();

    return Card(
      child: ExpansionTile(
        key: const ValueKey('join_generated_sql'),
        title: Text(AppStrings.datasetJoinsGeneratedSql.tr()),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(
                generated.sql,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
