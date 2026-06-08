import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/repositories/query_repository.dart';
import 'package:exlser/domain/value_objects/aggregation_type.dart';

class AggregateColumnUseCase {
  final QueryRepository repository;

  const AggregateColumnUseCase({required this.repository});

  Future<num?> call({
    required String tableName,
    required DatasetColumn column,
    required AggregationType aggregationType,
  }) async {
    final result = await repository.aggregate(
      tableName: tableName,
      column: column,
      function: aggregationType.sqlFunction,
    );

    if (result == null) return null;
    if (result is num) return result;
    return num.tryParse(result.toString());
  }
}
