import 'package:exlser/domain/entities/dataset.dart';
import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/entities/dataset_table.dart';

class ExportDatasetData {
  final Dataset dataset;
  final List<ExportTableData> tables;

  const ExportDatasetData({
    required this.dataset,
    required this.tables,
  });

  bool get isEmpty => tables.isEmpty;
}

class ExportTableData {
  final DatasetTable table;
  final List<DatasetColumn> columns;
  final List<Map<String, dynamic>> rows;

  const ExportTableData({
    required this.table,
    required this.columns,
    required this.rows,
  });
}
