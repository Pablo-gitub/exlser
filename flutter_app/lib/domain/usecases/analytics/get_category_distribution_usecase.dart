import 'package:exlser/application/dto/chart_data.dart';
import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/exceptions/invalid_chart_config_exception.dart';
import 'package:exlser/domain/repositories/query_repository.dart';
import 'package:exlser/domain/value_objects/aggregation_type.dart';
import 'package:exlser/domain/value_objects/chart_type.dart';

/// Computes a category distribution (GROUP BY) for bar and pie charts.
///
/// Returns a [CategoryChartData] with one point per distinct category value,
/// ordered by value descending and limited to [limit] entries.
///
/// Supports an optional WHERE clause to respect active filters.
class GetCategoryDistributionUseCase {
  final QueryRepository repository;

  const GetCategoryDistributionUseCase({required this.repository});

  Future<CategoryChartData> call({
    required String tableName,
    required DatasetColumn xColumn,
    DatasetColumn? yColumn,
    AggregationType aggregationType = AggregationType.count,
    ChartType? chartType,
    int limit = 20,
    String? whereClause,
    List<Object?>? whereArguments,
  }) async {
    // Validate: SUM/AVG/MIN/MAX require a Y column
    if (aggregationType != AggregationType.count && yColumn == null) {
      throw InvalidChartConfigException(
        'Cannot use $aggregationType aggregation without a numeric Y column',
      );
    }

    final x = xColumn.dbName;
    final where = whereClause != null ? 'WHERE $whereClause' : '';

    final String valueExpr;
    if (aggregationType == AggregationType.count) {
      valueExpr = 'COUNT(*) AS value';
    } else {
      valueExpr =
          '${aggregationType.sqlFunction}(CAST(${yColumn!.dbName} AS REAL)) AS value';
    }

    final sql = '''
      SELECT $x AS label, $valueExpr
      FROM $tableName
      $where
      GROUP BY $x
      ORDER BY value DESC
      LIMIT $limit
    ''';

    final rows = await repository.executeRawQuery(sql, whereArguments);

    final points = rows.where((r) => r['label'] != null).map((r) {
      final label = _formatLabel(r['label']);
      final value = _toDouble(r['value']) ?? 0.0;
      return CategoryPoint(label: label, value: value);
    }).toList();

    final resolvedChartType =
        chartType ?? (points.length <= 8 ? ChartType.pie : ChartType.bar);

    return CategoryChartData(
      chartType: resolvedChartType,
      xLabel: xColumn.originalName,
      yLabel: yColumn?.originalName ?? aggregationType.sqlFunction,
      points: points,
      aggregationType: aggregationType,
    );
  }

  String _formatLabel(dynamic value) {
    if (value == null) return '';
    if (value is int) {
      return value == 1
          ? 'True'
          : value == 0
              ? 'False'
              : value.toString();
    }
    return value.toString();
  }

  double? _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}
