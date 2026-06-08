// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dataset_columns_dao.dart';

// ignore_for_file: type=lint
mixin _$DatasetColumnsDaoMixin on DatabaseAccessor<AppDatabase> {
  $DatasetsTable get datasets => attachedDatabase.datasets;
  $DatasetTablesTable get datasetTables => attachedDatabase.datasetTables;
  $DatasetColumnsTable get datasetColumns => attachedDatabase.datasetColumns;
  DatasetColumnsDaoManager get managers => DatasetColumnsDaoManager(this);
}

class DatasetColumnsDaoManager {
  final _$DatasetColumnsDaoMixin _db;
  DatasetColumnsDaoManager(this._db);
  $$DatasetsTableTableManager get datasets =>
      $$DatasetsTableTableManager(_db.attachedDatabase, _db.datasets);
  $$DatasetTablesTableTableManager get datasetTables =>
      $$DatasetTablesTableTableManager(_db.attachedDatabase, _db.datasetTables);
  $$DatasetColumnsTableTableManager get datasetColumns =>
      $$DatasetColumnsTableTableManager(
          _db.attachedDatabase, _db.datasetColumns);
}
