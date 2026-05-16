import 'package:exel_category/core/database/app_database.dart';
import 'package:exel_category/core/database/daos/dataset_files_dao.dart';
import 'package:exel_category/core/database/daos/datasets_dao.dart';
import 'package:exel_category/data/datasources/drift_datasource.dart';
import 'package:exel_category/data/datasources/file_datasource.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase.defaults();

  ref.onDispose(database.close);

  return database;
});

final driftDatasourceProvider = Provider<DriftDatasource>((ref) {
  return DriftDatasource(
    ref.watch(appDatabaseProvider),
  );
});

final fileDatasourceProvider = Provider<FileDatasource>((ref) {
  return const FileDatasource();
});

final datasetsDaoProvider = Provider<DatasetsDao>((ref) {
  return DatasetsDao(
    ref.watch(appDatabaseProvider),
  );
});

final datasetFilesDaoProvider = Provider<DatasetFilesDao>((ref) {
  return DatasetFilesDao(
    ref.watch(appDatabaseProvider),
  );
});
