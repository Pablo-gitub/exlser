import 'package:exel_category/domain/entities/column_statistics.dart';
import 'package:exel_category/domain/entities/dataset_column.dart';
import 'package:exel_category/domain/repositories/query_repository.dart';

/// Computes basic statistics for a dataset column.
///
/// For numeric columns: count, nullCount, distinctCount, min, max, avg, sum.
/// For non-numeric columns: count, nullCount, distinctCount only.
///
/// Respects an optional WHERE clause so active filters are reflected.
class GetColumnStatisticsUseCase {
  final QueryRepository repository;

  const GetColumnStatisticsUseCase({required this.repository});

  Future<ColumnStatistics> call({
    required String tableName,
    required DatasetColumn column,
    String? whereClause,
    List<Object?>? whereArguments,
  }) async {
    final col = column.dbName;
    final where = whereClause != null ? 'WHERE $whereClause' : '';

    final statsQuery = '''
      SELECT
        COUNT(*) AS total_count,
        COUNT($col) AS non_null_count,
        COUNT(DISTINCT $col) AS distinct_count,
        MIN(CAST($col AS REAL)) AS min_val,
        MAX(CAST($col AS REAL)) AS max_val,
        AVG(CAST($col AS REAL)) AS avg_val,
        SUM(CAST($col AS REAL)) AS sum_val
      FROM $tableName
      $where
    ''';

    final result = await repository.executeRawQuery(
      statsQuery,
      whereArguments,
    );

    if (result.isEmpty) {
      return ColumnStatistics(
        column: column,
        totalRows: 0,
        nullCount: 0,
        distinctCount: 0,
      );
    }

    final row = result.first;
    final total = _toInt(row['total_count']) ?? 0;
    final nonNull = _toInt(row['non_null_count']) ?? 0;
    final distinct = _toInt(row['distinct_count']) ?? 0;

    final minVal = _toNum(row['min_val']);
    final maxVal = _toNum(row['max_val']);

    return ColumnStatistics(
      column: column,
      totalRows: total,
      nullCount: total - nonNull,
      distinctCount: distinct,
      min: minVal,
      max: maxVal,
      avg: _toNum(row['avg_val']),
      sum: _toNum(row['sum_val']),
    );
  }

  int? _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }

  num? _toNum(dynamic v) {
    if (v is num) return v;
    if (v is String) return num.tryParse(v);
    return null;
  }
}
