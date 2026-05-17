import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:flutter/material.dart';

class DatasetTableView extends StatefulWidget {
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
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    if (widget.columns.isEmpty || widget.rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Scrollbar(
      thumbVisibility: true,
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            for (final column in widget.columns)
              DataColumn(
                label: Text(column.originalName),
              ),
          ],
          rows: [
            for (final row in widget.rows)
              DataRow(
                cells: [
                  for (final column in widget.columns)
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Text(
                          _formatCellValue(row[column.dbName]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

String _formatCellValue(dynamic value) {
  if (value == null) return '';

  return value.toString();
}
