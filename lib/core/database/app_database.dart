import 'package:drift/drift.dart';

import 'tables/datasets.dart';
import 'tables/dataset_tables.dart';
import 'tables/dataset_columns.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Datasets,
    DatasetTables,
    DatasetColumns,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}