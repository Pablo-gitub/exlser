// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dataset_tables_dao.dart';

// ignore_for_file: type=lint
mixin _$DatasetTablesDaoMixin on DatabaseAccessor<AppDatabase> {
  $DatasetsTable get datasets => attachedDatabase.datasets;
  $DatasetTablesTable get datasetTables => attachedDatabase.datasetTables;
  DatasetTablesDaoManager get managers => DatasetTablesDaoManager(this);
}

class DatasetTablesDaoManager {
  final _$DatasetTablesDaoMixin _db;
  DatasetTablesDaoManager(this._db);
  $$DatasetsTableTableManager get datasets =>
      $$DatasetsTableTableManager(_db.attachedDatabase, _db.datasets);
  $$DatasetTablesTableTableManager get datasetTables =>
      $$DatasetTablesTableTableManager(_db.attachedDatabase, _db.datasetTables);
}
