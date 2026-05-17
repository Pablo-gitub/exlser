import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:flutter/material.dart';

class DatasetCardView extends StatelessWidget {
  final List<DatasetColumn> columns;
  final List<Map<String, dynamic>> rows;

  const DatasetCardView({
    super.key,
    required this.columns,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    if (columns.isEmpty || rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.separated(
      itemCount: rows.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final row = rows[index];

        return Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final column in columns) ...[
                  Text(
                    column.originalName,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 2),
                  Text(_formatCellValue(row[column.dbName])),
                  if (column != columns.last) const Divider(height: 16),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

String _formatCellValue(dynamic value) {
  if (value == null) return '';

  return value.toString();
}
