import 'package:exel_category/domain/entities/dataset_column.dart';

class ColumnStatistics {
  final DatasetColumn column;
  final int totalRows;
  final int nullCount;
  final int distinctCount;
  final num? min;
  final num? max;
  final num? avg;
  final num? sum;

  const ColumnStatistics({
    required this.column,
    required this.totalRows,
    required this.nullCount,
    required this.distinctCount,
    this.min,
    this.max,
    this.avg,
    this.sum,
  });

  int get nonNullCount => totalRows - nullCount;
  bool get hasNumericStats => min != null && max != null;
}
