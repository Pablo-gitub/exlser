import 'package:easy_localization/easy_localization.dart';
import 'package:exlser/core/constants/app_strings.dart';
import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/value_objects/column_type.dart';
import 'package:exlser/domain/value_objects/dataset_filter.dart';
import 'package:exlser/domain/value_objects/filter_operator.dart';
import 'package:flutter/material.dart';

class DatasetFilterPanel extends StatefulWidget {
  final List<DatasetColumn> columns;
  final List<Map<String, dynamic>> rows;
  final List<DatasetFilter> filters;
  final ValueChanged<DatasetFilter> onAddFilter;
  final ValueChanged<String> onRemoveFilter;
  final VoidCallback onClearFilters;

  const DatasetFilterPanel({
    super.key,
    required this.columns,
    required this.rows,
    required this.filters,
    required this.onAddFilter,
    required this.onRemoveFilter,
    required this.onClearFilters,
  });

  @override
  State<DatasetFilterPanel> createState() => _DatasetFilterPanelState();
}

class _DatasetFilterPanelState extends State<DatasetFilterPanel> {
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _secondValueController = TextEditingController();

  DatasetColumn? _selectedColumn;
  FilterOperator? _selectedOperator;
  RangeValues? _selectedRange;
  bool _advancedMode = false;
  bool _selectedBooleanValue = true;
  DateTime? _selectedFromDate;
  DateTime? _selectedToDate;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _syncSelectionWithColumns();
  }

  @override
  void didUpdateWidget(covariant DatasetFilterPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!widget.columns.contains(_selectedColumn)) {
      _syncSelectionWithColumns();
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    _secondValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.columns.isEmpty) {
      return const SizedBox.shrink();
    }

    final selectedColumn = _selectedColumn;

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
            LayoutBuilder(
              builder: (context, constraints) {
                final title = Text(
                  AppStrings.datasetWorkspaceFiltersTitle.tr(),
                  style: Theme.of(context).textTheme.titleMedium,
                );
                final advancedToggle = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(AppStrings.datasetWorkspaceFiltersAdvanced.tr()),
                    Switch(
                      value: _advancedMode,
                      onChanged: _toggleAdvancedMode,
                    ),
                  ],
                );

                if (constraints.maxWidth < 420) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title,
                      const SizedBox(height: 8),
                      advancedToggle,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: title),
                    advancedToggle,
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final metrics = _FilterLayoutMetrics.fromWidth(
                  constraints.maxWidth,
                );

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _ColumnSelector(
                      columns: widget.columns,
                      selectedColumn: selectedColumn,
                      width: metrics.columnWidth,
                      onChanged: _selectColumn,
                    ),
                    if (_advancedMode)
                      ..._advancedControls(selectedColumn, metrics)
                    else
                      ..._simpleControls(selectedColumn, metrics),
                    SizedBox(
                      width: metrics.buttonWidth,
                      child: FilledButton.icon(
                        onPressed: selectedColumn == null ? null : _applyFilter,
                        icon: const Icon(Icons.check),
                        label: Text(AppStrings.apply.tr()),
                      ),
                    ),
                  ],
                );
              },
            ),
            if (widget.filters.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.datasetWorkspaceFiltersActive.tr(),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: widget.onClearFilters,
                    icon: const Icon(Icons.clear_all),
                    label: Text(AppStrings.datasetWorkspaceFiltersClear.tr()),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final filter in widget.filters)
                    InputChip(
                      label: Text(_filterLabel(filter)),
                      onDeleted: () {
                        widget.onRemoveFilter(filter.effectiveId);
                      },
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _simpleControls(
    DatasetColumn? selectedColumn,
    _FilterLayoutMetrics metrics,
  ) {
    if (selectedColumn == null) {
      return const [];
    }

    return switch (selectedColumn.declaredType) {
      ColumnType.text => [
          _FilterValueField(
            controller: _valueController,
            width: metrics.textWidth,
            label: AppStrings.datasetWorkspaceFiltersTextValue.tr(),
            errorText: _errorText,
          ),
        ],
      ColumnType.integer || ColumnType.real => [
          _NumericRangeControl(
            width: metrics.rangeWidth,
            bounds: _numericBounds(selectedColumn),
            selectedRange: _selectedRange,
            isInteger: selectedColumn.declaredType == ColumnType.integer,
            errorText: _errorText,
            onChanged: (range) {
              setState(() {
                _selectedRange = range;
                _errorText = null;
              });
            },
          ),
        ],
      ColumnType.date => [
          _DatePickerField(
            value: _selectedFromDate,
            label: AppStrings.datasetWorkspaceFiltersFrom.tr(),
            width: metrics.shortValueWidth,
            errorText: _errorText,
            onTap: () => _pickDateTime(isFirst: true),
          ),
          _DatePickerField(
            value: _selectedToDate,
            label: AppStrings.datasetWorkspaceFiltersTo.tr(),
            width: metrics.shortValueWidth,
            onTap: () => _pickDateTime(isFirst: false),
          ),
        ],
      ColumnType.boolean => [
          SizedBox(
            width: metrics.shortValueWidth,
            child: DropdownButtonFormField<bool>(
              key: ValueKey('filter-boolean-$_selectedBooleanValue'),
              initialValue: _selectedBooleanValue,
              decoration: InputDecoration(
                labelText: AppStrings.datasetWorkspaceFiltersValue.tr(),
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: true,
                  child: Text(AppStrings.datasetWorkspaceFiltersTrueValue.tr()),
                ),
                DropdownMenuItem(
                  value: false,
                  child:
                      Text(AppStrings.datasetWorkspaceFiltersFalseValue.tr()),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedBooleanValue = value;
                  _errorText = null;
                });
              },
            ),
          ),
        ],
    };
  }

  List<Widget> _advancedControls(
    DatasetColumn? selectedColumn,
    _FilterLayoutMetrics metrics,
  ) {
    if (selectedColumn == null) {
      return const [];
    }

    final selectedOperator = _selectedOperator;
    final operators = _operatorsForType(selectedColumn.declaredType);

    return [
      SizedBox(
        width: metrics.operatorWidth,
        child: DropdownButtonFormField<FilterOperator>(
          key: ValueKey(
            'filter-operator-${selectedColumn.dbName}'
            '-${selectedOperator?.name ?? 'none'}',
          ),
          initialValue: selectedOperator,
          decoration: InputDecoration(
            labelText: AppStrings.datasetWorkspaceFiltersOperator.tr(),
            border: const OutlineInputBorder(),
          ),
          items: [
            for (final operator in operators)
              DropdownMenuItem(
                value: operator,
                child: Text(_operatorLabel(operator).tr()),
              ),
          ],
          onChanged: _selectOperator,
        ),
      ),
      if (selectedOperator?.requiresValue ?? false)
        selectedColumn.declaredType == ColumnType.date
            ? _DatePickerField(
                value: _selectedFromDate,
                label: AppStrings.datasetWorkspaceFiltersValue.tr(),
                width: metrics.valueWidth,
                errorText: _errorText,
                onTap: () => _pickDateTime(isFirst: true),
              )
            : _FilterValueField(
                controller: _valueController,
                width: metrics.valueWidth,
                label: AppStrings.datasetWorkspaceFiltersValue.tr(),
                errorText: _errorText,
                keyboardType: _keyboardType(selectedColumn.declaredType),
              ),
      if (selectedOperator?.requiresSecondValue ?? false)
        selectedColumn.declaredType == ColumnType.date
            ? _DatePickerField(
                value: _selectedToDate,
                label: AppStrings.datasetWorkspaceFiltersSecondValue.tr(),
                width: metrics.valueWidth,
                onTap: () => _pickDateTime(isFirst: false),
              )
            : _FilterValueField(
                controller: _secondValueController,
                width: metrics.valueWidth,
                label: AppStrings.datasetWorkspaceFiltersSecondValue.tr(),
                keyboardType: _keyboardType(selectedColumn.declaredType),
              ),
    ];
  }

  void _syncSelectionWithColumns() {
    _selectedColumn = widget.columns.isEmpty ? null : widget.columns.first;
    _syncOperatorWithSelectedColumn();
    _clearFilterInputs();
  }

  void _selectColumn(DatasetColumn? column) {
    if (column == null) return;

    setState(() {
      _selectedColumn = column;
      _syncOperatorWithSelectedColumn();
      _clearFilterInputs();
    });
  }

  void _selectOperator(FilterOperator? operator) {
    if (operator == null) return;

    setState(() {
      _selectedOperator = operator;
      _clearFilterInputs();
    });
  }

  void _toggleAdvancedMode(bool value) {
    setState(() {
      _advancedMode = value;
      _syncOperatorWithSelectedColumn();
      _clearFilterInputs();
    });
  }

  void _syncOperatorWithSelectedColumn() {
    final selectedColumn = _selectedColumn;
    if (selectedColumn == null) {
      _selectedOperator = null;
      return;
    }

    final operators = _operatorsForType(selectedColumn.declaredType);
    _selectedOperator = operators.isEmpty ? null : operators.first;
  }

  void _clearFilterInputs() {
    _valueController.clear();
    _secondValueController.clear();
    _selectedRange = null;
    _selectedFromDate = null;
    _selectedToDate = null;
    _errorText = null;
  }

  Future<void> _pickDateTime({required bool isFirst}) async {
    final initial = isFirst ? _selectedFromDate : _selectedToDate;
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial ?? DateTime.now()),
    );
    if (!mounted) return;
    setState(() {
      final combined = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 0,
        time?.minute ?? 0,
      );
      if (isFirst) {
        _selectedFromDate = combined;
      } else {
        _selectedToDate = combined;
      }
      _errorText = null;
    });
  }

  void _applyFilter() {
    final filter =
        _advancedMode ? _buildAdvancedFilter() : _buildSimpleFilter();
    if (filter == null) {
      setState(() {
        _errorText = AppStrings.datasetWorkspaceFiltersInvalidValue.tr();
      });
      return;
    }

    widget.onAddFilter(filter);

    setState(() {
      _clearFilterInputs();
    });
  }

  DatasetFilter? _buildSimpleFilter() {
    final column = _selectedColumn;
    if (column == null) {
      return null;
    }

    return switch (column.declaredType) {
      ColumnType.text => _buildSimpleTextFilter(column),
      ColumnType.integer ||
      ColumnType.real =>
        _buildSimpleNumericFilter(column),
      ColumnType.date => _buildSimpleDateFilter(column),
      ColumnType.boolean => DatasetFilter(
          column: column,
          operator: _selectedBooleanValue
              ? FilterOperator.isTrue
              : FilterOperator.isFalse,
        ),
    };
  }

  DatasetFilter? _buildSimpleTextFilter(DatasetColumn column) {
    final value = _parseValue(column.declaredType, _valueController.text);
    if (value == null) {
      return null;
    }

    return DatasetFilter(
      column: column,
      operator: FilterOperator.contains,
      value: value,
    );
  }

  DatasetFilter? _buildSimpleNumericFilter(DatasetColumn column) {
    final bounds = _numericBounds(column);
    if (bounds == null) {
      return null;
    }

    final range = _selectedRange ?? bounds.asRangeValues;
    return DatasetFilter(
      column: column,
      operator:
          bounds.isSingleValue ? FilterOperator.equals : FilterOperator.between,
      value: _normalizeNumericRangeValue(column.declaredType, range.start),
      secondValue: bounds.isSingleValue
          ? null
          : _normalizeNumericRangeValue(column.declaredType, range.end),
    );
  }

  DatasetFilter? _buildSimpleDateFilter(DatasetColumn column) {
    final from = _selectedFromDate;
    final to = _selectedToDate;
    if (from == null || to == null) return null;

    return DatasetFilter(
      column: column,
      operator: FilterOperator.between,
      value: from,
      secondValue: to,
    );
  }

  DatasetFilter? _buildAdvancedFilter() {
    final column = _selectedColumn;
    final operator = _selectedOperator;
    if (column == null || operator == null) return null;

    final isDate = column.declaredType == ColumnType.date;

    Object? value;
    if (operator.requiresValue) {
      value = isDate
          ? _selectedFromDate
          : _parseValue(column.declaredType, _valueController.text);
      if (value == null) return null;
    }

    Object? secondValue;
    if (operator.requiresSecondValue) {
      secondValue = isDate
          ? _selectedToDate
          : _parseValue(column.declaredType, _secondValueController.text);
      if (secondValue == null) return null;
    }

    return DatasetFilter(
      column: column,
      operator: operator,
      value: value,
      secondValue: secondValue,
    );
  }

  Object? _parseValue(ColumnType type, String rawValue) {
    final value = rawValue.trim();
    if (value.isEmpty) {
      return null;
    }

    return switch (type) {
      ColumnType.text => value,
      ColumnType.integer => int.tryParse(value),
      ColumnType.real => double.tryParse(value.replaceAll(',', '.')),
      ColumnType.date => DateTime.tryParse(value),
      ColumnType.boolean => value,
    };
  }

  Object _normalizeNumericRangeValue(ColumnType type, double value) {
    return type == ColumnType.integer ? value.round() : value;
  }

  _NumericBounds? _numericBounds(DatasetColumn column) {
    final values = <double>[];

    for (final row in widget.rows) {
      final value = row[column.dbName];
      final parsedValue = _parseNumericValue(value);
      if (parsedValue != null) {
        values.add(parsedValue);
      }
    }

    if (values.isEmpty) {
      return null;
    }

    values.sort();
    return _NumericBounds(
      min: values.first,
      max: values.last,
    );
  }

  double? _parseNumericValue(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.'));
    }

    return null;
  }

  String _filterLabel(DatasetFilter filter) {
    final buffer = StringBuffer()
      ..write(filter.column.originalName)
      ..write(' ')
      ..write(_operatorLabel(filter.operator).tr());

    if (filter.operator.requiresValue) {
      buffer
        ..write(' ')
        ..write(_formatFilterValue(filter.value));
    }

    if (filter.operator.requiresSecondValue) {
      buffer
        ..write(' - ')
        ..write(_formatFilterValue(filter.secondValue));
    }

    return buffer.toString();
  }
}

class _ColumnSelector extends StatelessWidget {
  final List<DatasetColumn> columns;
  final DatasetColumn? selectedColumn;
  final double width;
  final ValueChanged<DatasetColumn?> onChanged;

  const _ColumnSelector({
    required this.columns,
    required this.selectedColumn,
    required this.width,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<DatasetColumn>(
        key: ValueKey('filter-column-${selectedColumn?.dbName ?? 'none'}'),
        initialValue: selectedColumn,
        decoration: InputDecoration(
          labelText: AppStrings.datasetWorkspaceFiltersColumn.tr(),
          border: const OutlineInputBorder(),
        ),
        items: [
          for (final column in columns)
            DropdownMenuItem(
              value: column,
              child: Text(
                column.originalName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _FilterValueField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? errorText;
  final TextInputType? keyboardType;
  final double width;

  const _FilterValueField({
    required this.controller,
    required this.label,
    this.errorText,
    this.keyboardType,
    this.width = 220,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final DateTime? value;
  final String label;
  final String? errorText;
  final double width;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.value,
    required this.label,
    required this.width,
    required this.onTap,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: onTap,
        child: InputDecorator(
          isEmpty: value == null,
          decoration: InputDecoration(
            labelText: label,
            errorText: errorText,
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.calendar_today, size: 18),
          ),
          child: Text(
            value != null ? _formatDateTime(value!) : '',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}

class _NumericRangeControl extends StatelessWidget {
  final double width;
  final _NumericBounds? bounds;
  final RangeValues? selectedRange;
  final bool isInteger;
  final String? errorText;
  final ValueChanged<RangeValues> onChanged;

  const _NumericRangeControl({
    required this.width,
    required this.bounds,
    required this.selectedRange,
    required this.isInteger,
    required this.errorText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bounds = this.bounds;
    if (bounds == null) {
      return SizedBox(
        width: width,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: AppStrings.datasetWorkspaceFiltersRange.tr(),
            errorText: errorText,
            border: const OutlineInputBorder(),
          ),
          child: Text(AppStrings.datasetWorkspaceFiltersNoRange.tr()),
        ),
      );
    }

    final range = _clampRange(selectedRange ?? bounds.asRangeValues, bounds);

    return SizedBox(
      width: width,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: AppStrings.datasetWorkspaceFiltersRange.tr(),
          errorText: errorText,
          border: const OutlineInputBorder(),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 52,
                  child: Text(
                    _formatNumber(bounds.min, isInteger),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: bounds.isSingleValue
                      ? Slider(
                          value: bounds.min,
                          min: bounds.min,
                          max: bounds.min + 1,
                          onChanged: null,
                        )
                      : RangeSlider(
                          min: bounds.min,
                          max: bounds.max,
                          values: range,
                          labels: RangeLabels(
                            _formatNumber(range.start, isInteger),
                            _formatNumber(range.end, isInteger),
                          ),
                          divisions: _rangeDivisions(bounds, isInteger),
                          onChanged: onChanged,
                        ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 52,
                  child: Text(
                    _formatNumber(bounds.max, isInteger),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            Text(
              '${_formatNumber(range.start, isInteger)} - '
              '${_formatNumber(range.end, isInteger)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _NumericBounds {
  final double min;
  final double max;

  const _NumericBounds({
    required this.min,
    required this.max,
  });

  bool get isSingleValue => min == max;

  RangeValues get asRangeValues => RangeValues(min, max);
}

class _FilterLayoutMetrics {
  final double columnWidth;
  final double textWidth;
  final double valueWidth;
  final double shortValueWidth;
  final double rangeWidth;
  final double operatorWidth;
  final double buttonWidth;

  const _FilterLayoutMetrics({
    required this.columnWidth,
    required this.textWidth,
    required this.valueWidth,
    required this.shortValueWidth,
    required this.rangeWidth,
    required this.operatorWidth,
    required this.buttonWidth,
  });

  factory _FilterLayoutMetrics.fromWidth(double maxWidth) {
    final width = maxWidth.isFinite && maxWidth > 0 ? maxWidth : 720.0;

    if (width < 520) {
      return _FilterLayoutMetrics(
        columnWidth: width,
        textWidth: width,
        valueWidth: width,
        shortValueWidth: width,
        rangeWidth: width,
        operatorWidth: width,
        buttonWidth: width,
      );
    }

    if (width < 860) {
      final halfWidth = ((width - 12) / 2).clamp(180.0, 300.0).toDouble();

      return _FilterLayoutMetrics(
        columnWidth: halfWidth,
        textWidth: (width - halfWidth - 12).clamp(240.0, 420.0).toDouble(),
        valueWidth: halfWidth,
        shortValueWidth: halfWidth,
        rangeWidth: width,
        operatorWidth: halfWidth,
        buttonWidth: 150,
      );
    }

    const columnWidth = 220.0;
    const operatorWidth = 220.0;
    const buttonWidth = 140.0;
    final simpleAvailableWidth = width - columnWidth - buttonWidth - 24;
    final advancedAvailableWidth =
        width - columnWidth - operatorWidth - buttonWidth - 36;

    return _FilterLayoutMetrics(
      columnWidth: columnWidth,
      textWidth: simpleAvailableWidth.clamp(320.0, 560.0).toDouble(),
      valueWidth: advancedAvailableWidth.clamp(220.0, 380.0).toDouble(),
      shortValueWidth: 180,
      rangeWidth: simpleAvailableWidth.clamp(420.0, 680.0).toDouble(),
      operatorWidth: operatorWidth,
      buttonWidth: buttonWidth,
    );
  }
}

RangeValues _clampRange(RangeValues range, _NumericBounds bounds) {
  return RangeValues(
    range.start.clamp(bounds.min, bounds.max).toDouble(),
    range.end.clamp(bounds.min, bounds.max).toDouble(),
  );
}

int? _rangeDivisions(_NumericBounds bounds, bool isInteger) {
  if (!isInteger || bounds.isSingleValue) {
    return null;
  }

  final distance = bounds.max.round() - bounds.min.round();
  if (distance <= 0 || distance > 1000) {
    return null;
  }

  return distance;
}

List<FilterOperator> _operatorsForType(ColumnType type) {
  return switch (type) {
    ColumnType.text => const [
        FilterOperator.contains,
        FilterOperator.equals,
        FilterOperator.notEquals,
        FilterOperator.startsWith,
        FilterOperator.endsWith,
        FilterOperator.isEmpty,
        FilterOperator.isNotEmpty,
      ],
    ColumnType.integer || ColumnType.real => const [
        FilterOperator.equals,
        FilterOperator.notEquals,
        FilterOperator.greaterThan,
        FilterOperator.greaterOrEqual,
        FilterOperator.lessThan,
        FilterOperator.lessOrEqual,
        FilterOperator.between,
        FilterOperator.isEmpty,
        FilterOperator.isNotEmpty,
      ],
    ColumnType.date => const [
        FilterOperator.on,
        FilterOperator.before,
        FilterOperator.after,
        FilterOperator.between,
        FilterOperator.isEmpty,
        FilterOperator.isNotEmpty,
      ],
    ColumnType.boolean => const [
        FilterOperator.isTrue,
        FilterOperator.isFalse,
        FilterOperator.isEmpty,
        FilterOperator.isNotEmpty,
      ],
  };
}

String _operatorLabel(FilterOperator operator) {
  return switch (operator) {
    FilterOperator.contains => AppStrings.datasetWorkspaceFilterContains,
    FilterOperator.equals => AppStrings.datasetWorkspaceFilterEquals,
    FilterOperator.notEquals => AppStrings.datasetWorkspaceFilterNotEquals,
    FilterOperator.startsWith => AppStrings.datasetWorkspaceFilterStartsWith,
    FilterOperator.endsWith => AppStrings.datasetWorkspaceFilterEndsWith,
    FilterOperator.greaterThan => AppStrings.datasetWorkspaceFilterGreaterThan,
    FilterOperator.greaterOrEqual =>
      AppStrings.datasetWorkspaceFilterGreaterOrEqual,
    FilterOperator.lessThan => AppStrings.datasetWorkspaceFilterLessThan,
    FilterOperator.lessOrEqual => AppStrings.datasetWorkspaceFilterLessOrEqual,
    FilterOperator.between => AppStrings.datasetWorkspaceFilterBetween,
    FilterOperator.on => AppStrings.datasetWorkspaceFilterOn,
    FilterOperator.before => AppStrings.datasetWorkspaceFilterBefore,
    FilterOperator.after => AppStrings.datasetWorkspaceFilterAfter,
    FilterOperator.isEmpty => AppStrings.datasetWorkspaceFilterIsEmpty,
    FilterOperator.isNotEmpty => AppStrings.datasetWorkspaceFilterIsNotEmpty,
    FilterOperator.isTrue => AppStrings.datasetWorkspaceFilterIsTrue,
    FilterOperator.isFalse => AppStrings.datasetWorkspaceFilterIsFalse,
  };
}

String _formatFilterValue(Object? value) {
  if (value == null) return '';
  if (value is DateTime) return _formatDateTime(value);
  return value.toString();
}

String _formatDateTime(DateTime dt) {
  final date = '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
  if (dt.hour == 0 && dt.minute == 0) return date;
  return '$date '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';
}

String _formatNumber(double value, bool isInteger) {
  if (isInteger) {
    return value.round().toString();
  }

  return value.toStringAsFixed(2);
}

TextInputType? _keyboardType(ColumnType? type) {
  return switch (type) {
    ColumnType.integer => TextInputType.number,
    ColumnType.real => const TextInputType.numberWithOptions(
        signed: true,
        decimal: true,
      ),
    ColumnType.date => TextInputType.datetime,
    _ => null,
  };
}
