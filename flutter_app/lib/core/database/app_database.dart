import 'package:drift/drift.dart';
import 'package:exlser/core/database/connection/connection.dart';
import 'package:exlser/core/database/daos/dataset_columns_dao.dart';
import 'package:exlser/core/database/daos/dataset_tables_dao.dart';
import 'package:exlser/core/database/daos/datasets_dao.dart';
import 'package:exlser/core/database/tables/dataset_files.dart';

import 'tables/datasets.dart';
import 'tables/dataset_tables.dart';
import 'tables/dataset_columns.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Datasets,
    DatasetTables,
    DatasetColumns,
    DatasetFiles,
  ],
  daos: [
    DatasetsDao,
    DatasetTablesDao,
    DatasetColumnsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);
  AppDatabase.defaults() : super(openConnection());

  @override
  int get schemaVersion => 1;
}
