import 'package:easy_localization/easy_localization.dart';
import 'package:exel_category/application/dto/chart_data.dart';
import 'package:exel_category/core/constants/app_strings.dart';
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
    context.read<DatasetBloc>().add(const LoadAnalyticsEvent());
  }

  void _showAddChartDialog() {
    final columns = widget.state.columns;
    final availableTypes = ChartType.values
        .where((t) => t != ChartType.none)
        .where(
          (t) =>
              columns.any((c) => t.validXColumnTypes.contains(c.declaredType)),
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
              : Column(
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

  @override
  Widget build(BuildContext context) {
    final suggestion = chart.suggestion;
    final chartType = suggestion.chartType;

    final validXColumns = allColumns
        .where((c) => chartType.validXColumnTypes.contains(c.declaredType))
        .toList();
    final validYColumns = allColumns.where((c) => c.isNumeric).toList();

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
                    label: AppStrings.datasetWorkspaceAnalyticsXColumn.tr(),
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
                    label: AppStrings.datasetWorkspaceAnalyticsYColumn.tr(),
                    columns: validYColumns,
                    selected: suggestion.yColumn,
                    nullable: true,
                    onChanged: (col) =>
                        onConfigChanged(suggestion.copyWith(yColumn: col)),
                  ),
                _AggregationDropdown(
                  selected: suggestion.aggregationType,
                  onChanged: (agg) {
                    if (agg != null) {
                      onConfigChanged(
                          suggestion.copyWith(aggregationType: agg));
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (chart.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              _ChartBody(suggestion: suggestion, chartData: chart.chartData),
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
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: DropdownButtonFormField<DatasetColumn?>(
        key: ValueKey(selected?.dbName),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        initialValue: selected,
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
  final ValueChanged<AggregationType?> onChanged;

  const _AggregationDropdown({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 180),
      child: DropdownButtonFormField<AggregationType>(
        key: ValueKey(selected),
        decoration: InputDecoration(
          labelText: AppStrings.datasetWorkspaceAnalyticsAggregation.tr(),
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        initialValue: selected,
        items: [
          DropdownMenuItem(
            value: AggregationType.count,
            child: Text(AppStrings.datasetWorkspaceAnalyticsAggCount.tr()),
          ),
          DropdownMenuItem(
            value: AggregationType.sum,
            child: Text(AppStrings.datasetWorkspaceAnalyticsAggSum.tr()),
          ),
          DropdownMenuItem(
            value: AggregationType.avg,
            child: Text(AppStrings.datasetWorkspaceAnalyticsAggAvg.tr()),
          ),
          DropdownMenuItem(
            value: AggregationType.min,
            child: Text(AppStrings.datasetWorkspaceAnalyticsAggMin.tr()),
          ),
          DropdownMenuItem(
            value: AggregationType.max,
            child: Text(AppStrings.datasetWorkspaceAnalyticsAggMax.tr()),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _ChartBody extends StatelessWidget {
  final ChartSuggestion suggestion;
  final ChartData chartData;

  const _ChartBody({required this.suggestion, required this.chartData});

  @override
  Widget build(BuildContext context) {
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
          ? PieChartWidget(data: data)
          : DistributionChartWidget(data: data);
    }

    if (chartData is TimeSeriesChartData) {
      final data = chartData as TimeSeriesChartData;
      if (data.isEmpty) return const _EmptyChartMessage();
      return LineChartWidget(data: data);
    }

    return const SizedBox.shrink();
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
