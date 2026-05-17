import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:flutter/material.dart';

class DatasetTableView extends StatefulWidget {
  static const Key horizontalScrollKey =
      ValueKey('dataset-table-horizontal-scroll');
  static const Key verticalScrollKey =
      ValueKey('dataset-table-vertical-scroll');

  final List<DatasetColumn> columns;
  final List<Map<String, dynamic>> rows;

  const DatasetTableView({
    super.key,
    required this.columns,
    required this.rows,
  });

  @override
  State<DatasetTableView> createState() => _DatasetTableViewState();
}

class _DatasetTableViewState extends State<DatasetTableView> {
  static const double _headingRowHeight = 48;
  static const double _dataRowHeight = 44;
  static const double _minimumTableHeight = 132;
  static const double _maximumViewportFraction = 0.58;
  static const double _maximumTableHeight = 520;

  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.columns.isEmpty || widget.rows.isEmpty) {
      return const SizedBox.shrink();
    }

    final height = _tableHeight(context, widget.rows.length);
    final borderColor = Theme.of(context).dividerColor;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Scrollbar(
          controller: _horizontalController,
          thumbVisibility: true,
          notificationPredicate: (notification) =>
              notification.metrics.axis == Axis.horizontal,
          child: SingleChildScrollView(
            key: DatasetTableView.horizontalScrollKey,
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              height: height,
              child: Scrollbar(
                controller: _verticalController,
                thumbVisibility: true,
                notificationPredicate: (notification) =>
                    notification.metrics.axis == Axis.vertical,
                child: SingleChildScrollView(
                  key: DatasetTableView.verticalScrollKey,
                  controller: _verticalController,
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    headingRowHeight: _headingRowHeight,
                    dataRowMinHeight: _dataRowHeight,
                    dataRowMaxHeight: _dataRowHeight,
                    horizontalMargin: 16,
                    columnSpacing: 24,
                    border: TableBorder(
                      horizontalInside: BorderSide(color: borderColor),
                    ),
                    columns: [
                      for (final column in widget.columns)
                        DataColumn(
                          label: _HeaderCell(label: column.originalName),
                        ),
                    ],
                    rows: [
                      for (final row in widget.rows)
                        DataRow(
                          cells: [
                            for (final column in widget.columns)
                              DataCell(
                                _DataCellText(
                                  value: _formatCellValue(row[column.dbName]),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _tableHeight(BuildContext context, int rowCount) {
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final maxHeight = (viewportHeight * _maximumViewportFraction)
        .clamp(_minimumTableHeight, _maximumTableHeight)
        .toDouble();
    final preferredHeight = _headingRowHeight + (_dataRowHeight * rowCount);

    return preferredHeight.clamp(_minimumTableHeight, maxHeight).toDouble();
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;

  const _HeaderCell({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
      ),
    );
  }
}

class _DataCellText extends StatelessWidget {
  final String value;

  const _DataCellText({
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
      ),
    );
  }
}

String _formatCellValue(dynamic value) {
  if (value == null) return '';
  if (value is String && value.trim().isEmpty) return '';

  return value.toString();
}
