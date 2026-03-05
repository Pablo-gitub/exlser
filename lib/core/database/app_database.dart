import 'package:drift/drift.dart';
import 'package:exel_category/core/database/connection/connection.dart';
import 'package:exel_category/core/database/daos/datasets_dao.dart';

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
  daos: [
    DatasetsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);
  AppDatabase.defaults() : super(openConnection());

  @override
  int get schemaVersion => 1;
}