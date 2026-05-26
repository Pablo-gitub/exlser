import 'package:exlser/application/dto/chart_data.dart';
import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/repositories/query_repository.dart';
import 'package:exlser/domain/value_objects/aggregation_type.dart';

/// Computes an aggregated time series for a line chart.
///
/// Groups rows by [xColumn] (date) and aggregates [yColumn] (numeric)
/// using [aggregationType]. Returns points sorted ascending by date.
///
/// Supports an optional WHERE clause to respect active filters.
class GetTimeSeriesUseCase {
  final QueryRepository repository;

  const GetTimeSeriesUseCase({required this.repository});

  Future<TimeSeriesChartData> call({
    required String tableName,
    required DatasetColumn xColumn,
    required DatasetColumn yColumn,
    AggregationType aggregationType = AggregationType.sum,
    String? whereClause,
    List<Object?>? whereArguments,
  }) async {
    final x = xColumn.dbName;
    final y = yColumn.dbName;
    final where = whereClause != null ? 'WHERE $whereClause' : '';
    final agg = aggregationType.sqlFunction;

    final sql = '''
      SELECT $x AS x_val, $agg(CAST($y AS REAL)) AS y_val
      FROM $tableName
      $where
      GROUP BY $x
      ORDER BY $x ASC
    ''';

    final rows = await repository.executeRawQuery(sql, whereArguments);

    final points = <TimeSeriesPoint>[];
    for (final row in rows) {
      final xRaw = row['x_val'];
      final yRaw = row['y_val'];
      if (xRaw == null) continue;

      final date = _parseDate(xRaw.toString());
      final value = _toDouble(yRaw) ?? 0.0;
      if (date != null) {
        points.add(TimeSeriesPoint(x: date, y: value));
      }
    }

    return TimeSeriesChartData(
      xLabel: xColumn.originalName,
      yLabel: '${aggregationType.sqlFunction}(${yColumn.originalName})',
      points: points,
    );
  }

  DateTime? _parseDate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return DateTime.tryParse(trimmed);
  }

  double? _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}
