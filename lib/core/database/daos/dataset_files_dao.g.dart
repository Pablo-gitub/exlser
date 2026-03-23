// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dataset_files_dao.dart';

// ignore_for_file: type=lint
mixin _$DatasetFilesDaoMixin on DatabaseAccessor<AppDatabase> {
  $DatasetsTable get datasets => attachedDatabase.datasets;
  $DatasetFilesTable get datasetFiles => attachedDatabase.datasetFiles;
  DatasetFilesDaoManager get managers => DatasetFilesDaoManager(this);
}

class DatasetFilesDaoManager {
  final _$DatasetFilesDaoMixin _db;
  DatasetFilesDaoManager(this._db);
  $$DatasetsTableTableManager get datasets =>
      $$DatasetsTableTableManager(_db.attachedDatabase, _db.datasets);
  $$DatasetFilesTableTableManager get datasetFiles =>
      $$DatasetFilesTableTableManager(_db.attachedDatabase, _db.datasetFiles);
}
