import 'package:easy_localization/easy_localization.dart';
import 'package:exel_category/application/dto/chart_data.dart';
import 'package:exel_category/core/constants/app_strings.dart';
import 'package:exel_category/domain/entities/chart_config_validator.dart';
import 'package:exel_category/domain/entities/chart_suggestion.dart';
import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/value_objects/aggregation_type.dart';
import 'package:exel_category/domain/value_objects/chart_type.dart';
import 'package:exel_category/presentation/state/dataset_bloc.dart';
import 'package:exel_category/presentation/state/dataset_event.dart';
import 'package:exel_category/presentation/state/dataset_state.dart';
import 'package:exel_category/presentation/widgets/charts/distribution_chart.dart';
import 'package:exel_category/presentation/widgets/charts/line_chart.dart';
import 'package:exel_category/presentation/widgets/charts/pie_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AnalyticsSection extends StatefulWidget {
  final DatasetLoadedState state;

  const AnalyticsSection({super.key, required this.state});

  @override
  State<AnalyticsSection> createState() => _AnalyticsSectionState();
}

class _AnalyticsSectionState extends State<AnalyticsSection> {
  @override
  void initState() {
    super.initState();
    final blocState = context.read<DatasetBloc>().state;
    if (blocState is DatasetLoadedState &&
        blocState.analyticsState is DatasetAnalyticsIdleState) {
      context.read<DatasetBloc>().add(const LoadAnalyticsEvent());
    }
  }

  @override
  void didUpdateWidget(covariant AnalyticsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.activeTable.id != oldWidget.state.activeTable.id &&
        widget.state.analyticsState is DatasetAnalyticsIdleState) {
      context.read<DatasetBloc>().add(const LoadAnalyticsEvent());
    }
  }

  void _showAddChartDialog() {
    final columns = widget.state.columns;
    final availableTypes = ChartType.values
        .where((t) => t.isImplemented)
        .where(
          (t) =>
              columns.any((c) => t.validXColumnTypes.contains(c.declaredType)),
        )
        .where(
          (t) => !t.requiresYColumn || columns.any((c) => c.isNumeric),
        )
        .toList();

    if (availableTypes.isEmpty) return;

    showDialog<ChartType>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppStrings.datasetWorkspaceAnalyticsAddChart.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final type in availableTypes)
              ListTile(
                title: Text(type.label),
                onTap: () => Navigator.of(dialogContext).pop(type),
              ),
          ],
        ),
      ),
    ).then((type) {
      if (type != null && mounted) {
        context.read<DatasetBloc>().add(AddChartEvent(type));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final analyticsState = widget.state.analyticsState;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppStrings.datasetWorkspaceAnalyticsTitle.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            if (analyticsState is DatasetAnalyticsLoadedState)
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: AppStrings.datasetWorkspaceAnalyticsAddChart.tr(),
                onPressed: _showAddChartDialog,
              ),
            if (analyticsState is DatasetAnalyticsLoadedState ||
                analyticsState is DatasetAnalyticsErrorState)
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: AppStrings.refresh.tr(),
                onPressed: () {
                  context.read<DatasetBloc>().add(const LoadAnalyticsEvent());
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        switch (analyticsState) {
          DatasetAnalyticsIdleState() ||
          DatasetAnalyticsLoadingState() =>
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(),
              ),
            ),
          DatasetAnalyticsErrorState() => _ErrorTile(
              onRetry: () {
                context.read<DatasetBloc>().add(const LoadAnalyticsEvent());
              },
            ),
          DatasetAnalyticsLoadedState(:final charts) => charts.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      AppStrings.datasetWorkspaceAnalyticsNoChart.tr(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final twoColumns = constraints.maxWidth >= 800;
                    if (twoColumns) {
                      final cardWidth = (constraints.maxWidth - 16) / 2;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 0,
                        children: [
                          for (final chart in charts)
                            SizedBox(
                              width: cardWidth,
                              child: _ChartCard(
                                key: ValueKey(chart.id),
                                chart: chart,
                                allColumns: widget.state.columns,
                                onRemove: () {
                                  context
                                      .read<DatasetBloc>()
                                      .add(RemoveChartEvent(chart.id));
                                },
                                onConfigChanged: (suggestion) {
                                  context.read<DatasetBloc>().add(
                                        UpdateChartConfigEvent(
                                          chartId: chart.id,
                                          suggestion: suggestion,
                                        ),
                                      );
                                },
                              ),
                            ),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        for (final chart in charts)
                          _ChartCard(
                            key: ValueKey(chart.id),
                            chart: chart,
                            allColumns: widget.state.columns,
                            onRemove: () {
                              context
                                  .read<DatasetBloc>()
                                  .add(RemoveChartEvent(chart.id));
                            },
                            onConfigChanged: (suggestion) {
                              context.read<DatasetBloc>().add(
                                    UpdateChartConfigEvent(
                                      chartId: chart.id,
                                      suggestion: suggestion,
                                    ),
                                  );
                            },
                          ),
                      ],
                    );
                  },
                ),
        },
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  final AnalyticsChart chart;
  final List<DatasetColumn> allColumns;
  final VoidCallback onRemove;
  final ValueChanged<ChartSuggestion> onConfigChanged;

  const _ChartCard({
    super.key,
    required this.chart,
    required this.allColumns,
    required this.onRemove,
    required this.onConfigChanged,
  });

  void _showExpanded(BuildContext context, ChartSuggestion suggestion) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width - 48,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Chip(
                      label: Text(suggestion.chartType.label),
                      visualDensity: VisualDensity.compact,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _ChartBody(
                  suggestion: suggestion,
                  chartData: chart.chartData,
                  error: chart.error,
                  chartHeight: 420,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final suggestion = chart.suggestion;
    final chartType = suggestion.chartType;

    final validXColumns = allColumns
        .where((c) => chartType.validXColumnTypes.contains(c.declaredType))
        .toList();
    final validYColumns = allColumns
        .where((c) => chartType.validYColumnTypes.contains(c.declaredType))
        .toList();
    final selectedYColumn = suggestion.yColumn != null &&
            validYColumns.any((c) => c.dbName == suggestion.yColumn!.dbName)
        ? suggestion.yColumn
        : null;
    final aggregationOptions = ChartConfigValidator.getValidAggregations(
      chartType,
      selectedYColumn != null,
    );
    final selectedAggregation =
        aggregationOptions.contains(suggestion.aggregationType)
            ? suggestion.aggregationType
            : AggregationType.count;
    final displaySuggestion = suggestion.copyWith(
      yColumn: selectedYColumn,
      aggregationType: selectedAggregation,
    );
    final chartTitle =
        aggregationOptions.isEmpty ? '' : _chartSentence(displaySuggestion);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  label: Text(chartType.label),
                  visualDensity: VisualDensity.compact,
                ),
                const Spacer(),
                if (chart.isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                IconButton(
                  icon: const Icon(Icons.open_in_full),
                  tooltip: AppStrings.expand.tr(),
                  onPressed: () => _showExpanded(context, suggestion),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: AppStrings.delete.tr(),
                  onPressed: onRemove,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (validXColumns.isNotEmpty)
                  _ColumnDropdown(
                    label: _xColumnLabel(chartType).tr(),
                    columns: validXColumns,
                    selected: suggestion.xColumn,
                    onChanged: (col) {
                      if (col != null) {
                        onConfigChanged(suggestion.copyWith(xColumn: col));
                      }
                    },
                  ),
                if (validYColumns.isNotEmpty)
                  _ColumnDropdown(
                    label: _yColumnLabel(chartType).tr(),
                    columns: validYColumns,
                    selected: selectedYColumn,
                    nullable: !chartType.requiresYColumn,
                    onChanged: (col) {
                      final nextAggregation = col == null
                          ? AggregationType.count
                          : selectedAggregation;
                      onConfigChanged(
                        suggestion.copyWith(
                          yColumn: col,
                          aggregationType: nextAggregation,
                        ),
                      );
                    },
                  ),
                _AggregationDropdown(
                  selected: selectedAggregation,
                  options: aggregationOptions,
                  onChanged: (agg) {
                    if (agg != null) {
                      final nextYColumn = agg == AggregationType.count &&
                              !chartType.requiresYColumn
                          ? null
                          : selectedYColumn;
                      onConfigChanged(
                        suggestion.copyWith(
                          aggregationType: agg,
                          yColumn: nextYColumn,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            if (chartTitle.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                chartTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
            const SizedBox(height: 16),
            if (chart.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              _ChartBody(
                suggestion: suggestion,
                chartData: chart.chartData,
                error: chart.error,
              ),
          ],
        ),
      ),
    );
  }
}

class _ColumnDropdown extends StatelessWidget {
  final String label;
  final List<DatasetColumn> columns;
  final DatasetColumn? selected;
  final bool nullable;
  final ValueChanged<DatasetColumn?> onChanged;

  const _ColumnDropdown({
    required this.label,
    required this.columns,
    required this.selected,
    required this.onChanged,
    this.nullable = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSelected =
        selected != null && columns.any((c) => c.dbName == selected!.dbName)
            ? selected
            : null;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: DropdownButtonFormField<DatasetColumn?>(
        key: ValueKey(effectiveSelected?.dbName),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        initialValue: effectiveSelected,
        items: [
          if (nullable)
            DropdownMenuItem<DatasetColumn?>(
              value: null,
              child: Text(
                '-',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          for (final col in columns)
            DropdownMenuItem<DatasetColumn?>(
              value: col,
              child: Text(col.originalName),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _AggregationDropdown extends StatelessWidget {
  final AggregationType selected;
  final List<AggregationType> options;
  final ValueChanged<AggregationType?> onChanged;

  const _AggregationDropdown({
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSelected = options.contains(selected)
        ? selected
        : (options.isEmpty ? null : options.first);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 230),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: DropdownButtonFormField<AggregationType>(
              key: ValueKey(effectiveSelected),
              decoration: InputDecoration(
                labelText: AppStrings.datasetWorkspaceAnalyticsAggregation.tr(),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              initialValue: effectiveSelected,
              items: [
                for (final option in options)
                  DropdownMenuItem(
                    value: option,
                    child: Text(_aggregationLabel(option).tr()),
                  ),
              ],
              onChanged: options.isEmpty ? null : onChanged,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip:
                AppStrings.datasetWorkspaceAnalyticsAggregationInfoTooltip.tr(),
            onPressed: () => _showAggregationInfo(context),
          ),
        ],
      ),
    );
  }

  void _showAggregationInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          AppStrings.datasetWorkspaceAnalyticsAggregationInfoTitle.tr(),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.datasetWorkspaceAnalyticsAggregationInfoIntro.tr(),
              ),
              const SizedBox(height: 12),
              _AggregationInfoText(
                label: AppStrings.datasetWorkspaceAnalyticsAggCount.tr(),
                description: AppStrings
                    .datasetWorkspaceAnalyticsAggregationInfoCount
                    .tr(),
              ),
              _AggregationInfoText(
                label: AppStrings.datasetWorkspaceAnalyticsAggSum.tr(),
                description:
                    AppStrings.datasetWorkspaceAnalyticsAggregationInfoSum.tr(),
              ),
              _AggregationInfoText(
                label: AppStrings.datasetWorkspaceAnalyticsAggAvg.tr(),
                description:
                    AppStrings.datasetWorkspaceAnalyticsAggregationInfoAvg.tr(),
              ),
              _AggregationInfoText(
                label: AppStrings.datasetWorkspaceAnalyticsAggMin.tr(),
                description:
                    AppStrings.datasetWorkspaceAnalyticsAggregationInfoMin.tr(),
              ),
              _AggregationInfoText(
                label: AppStrings.datasetWorkspaceAnalyticsAggMax.tr(),
                description:
                    AppStrings.datasetWorkspaceAnalyticsAggregationInfoMax.tr(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(AppStrings.close.tr()),
          ),
        ],
      ),
    );
  }
}

String _xColumnLabel(ChartType chartType) {
  return switch (chartType) {
    ChartType.line => AppStrings.datasetWorkspaceAnalyticsDate,
    ChartType.bar ||
    ChartType.pie =>
      AppStrings.datasetWorkspaceAnalyticsGroupBy,
    ChartType.scatter => AppStrings.datasetWorkspaceAnalyticsXColumn,
    ChartType.none => AppStrings.datasetWorkspaceAnalyticsXColumn,
  };
}

String _yColumnLabel(ChartType chartType) {
  return switch (chartType) {
    ChartType.line => AppStrings.datasetWorkspaceAnalyticsValueOverTime,
    ChartType.bar || ChartType.pie => AppStrings.datasetWorkspaceAnalyticsValue,
    ChartType.scatter => AppStrings.datasetWorkspaceAnalyticsYColumn,
    ChartType.none => AppStrings.datasetWorkspaceAnalyticsYColumn,
  };
}

String _chartSentence(ChartSuggestion suggestion) {
  final xColumn = suggestion.xColumn;
  if (xColumn == null || !suggestion.hasChart) return '';

  final aggregation = _aggregationLabel(suggestion.aggregationType).tr();

  if (suggestion.chartType == ChartType.line) {
    if (suggestion.aggregationType == AggregationType.count) {
      return AppStrings.datasetWorkspaceAnalyticsTitleCountOver.tr(
        namedArgs: {'date': xColumn.originalName},
      );
    }

    final yColumn = suggestion.yColumn;
    if (yColumn == null) return '';

    return AppStrings.datasetWorkspaceAnalyticsTitleAggregationOver.tr(
      namedArgs: {
        'aggregation': aggregation,
        'value': yColumn.originalName,
        'date': xColumn.originalName,
      },
    );
  }

  if (suggestion.aggregationType == AggregationType.count ||
      suggestion.yColumn == null) {
    return AppStrings.datasetWorkspaceAnalyticsTitleCountBy.tr(
      namedArgs: {'group': xColumn.originalName},
    );
  }

  return AppStrings.datasetWorkspaceAnalyticsTitleAggregationBy.tr(
    namedArgs: {
      'aggregation': aggregation,
      'value': suggestion.yColumn!.originalName,
      'group': xColumn.originalName,
    },
  );
}

String _aggregationLabel(AggregationType aggregationType) {
  return switch (aggregationType) {
    AggregationType.count => AppStrings.datasetWorkspaceAnalyticsAggCount,
    AggregationType.sum => AppStrings.datasetWorkspaceAnalyticsAggSum,
    AggregationType.avg => AppStrings.datasetWorkspaceAnalyticsAggAvg,
    AggregationType.min => AppStrings.datasetWorkspaceAnalyticsAggMin,
    AggregationType.max => AppStrings.datasetWorkspaceAnalyticsAggMax,
  };
}

class _AggregationInfoText extends StatelessWidget {
  final String label;
  final String description;

  const _AggregationInfoText({
    required this.label,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: description),
          ],
        ),
      ),
    );
  }
}

class _ChartBody extends StatelessWidget {
  final ChartSuggestion suggestion;
  final ChartData chartData;
  final ChartLoadError? error;
  final double chartHeight;

  const _ChartBody({
    required this.suggestion,
    required this.chartData,
    this.error,
    this.chartHeight = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return _ChartErrorMessage(error: error!);
    }

    if (!suggestion.hasChart || chartData is EmptyChartData) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            AppStrings.datasetWorkspaceAnalyticsNoChart.tr(),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    if (chartData is CategoryChartData) {
      final data = chartData as CategoryChartData;
      if (data.isEmpty) return const _EmptyChartMessage();
      return data.chartType == ChartType.pie
          ? PieChartWidget(
              data: data,
              height: chartHeight > 0 ? chartHeight : 220,
            )
          : DistributionChartWidget(
              data: data,
              height: chartHeight > 0 ? chartHeight : 240,
            );
    }

    if (chartData is TimeSeriesChartData) {
      final data = chartData as TimeSeriesChartData;
      if (data.isEmpty) return const _EmptyChartMessage();
      return LineChartWidget(
        data: data,
        height: chartHeight > 0 ? chartHeight : 240,
      );
    }

    return const SizedBox.shrink();
  }
}

class _ChartErrorMessage extends StatelessWidget {
  final ChartLoadError error;

  const _ChartErrorMessage({required this.error});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline,
              size: 18,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _errorMessage(error).tr(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _errorMessage(ChartLoadError error) {
    return switch (error) {
      ChartLoadError.invalidAggregation =>
        AppStrings.datasetWorkspaceAnalyticsErrorInvalidAggregation,
      ChartLoadError.noRowsAfterFilter =>
        AppStrings.datasetWorkspaceAnalyticsErrorNoRows,
      ChartLoadError.chartTypeNotSupported =>
        AppStrings.datasetWorkspaceAnalyticsErrorUnsupported,
      ChartLoadError.noNumericColumn =>
        AppStrings.datasetWorkspaceAnalyticsErrorNoNumeric,
      ChartLoadError.internalFailure =>
        AppStrings.datasetWorkspaceAnalyticsErrorInternal,
    };
  }
}

class _EmptyChartMessage extends StatelessWidget {
  const _EmptyChartMessage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          AppStrings.datasetWorkspaceAnalyticsNoChart.tr(),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _ErrorTile extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorTile({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.error_outline),
        const SizedBox(width: 8),
        Text(AppStrings.datasetWorkspaceAnalyticsError.tr()),
        const Spacer(),
        TextButton(
          onPressed: onRetry,
          child: Text(AppStrings.retry.tr()),
        ),
      ],
    );
  }
}
