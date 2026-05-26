import 'package:exlser/domain/entities/dataset_column.dart';

enum SortDirection {
  ascending,
  descending;

  String get sqlKeyword {
    return switch (this) {
      SortDirection.ascending => 'ASC',
      SortDirection.descending => 'DESC',
    };
  }
}

class DatasetSort {
  final DatasetColumn column;
  final SortDirection direction;

  const DatasetSort({
    required this.column,
    required this.direction,
  });

  String get orderBy => '${column.dbName} ${direction.sqlKeyword}';
}
