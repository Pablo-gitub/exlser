// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'datasets_dao.dart';

// ignore_for_file: type=lint
mixin _$DatasetsDaoMixin on DatabaseAccessor<AppDatabase> {
  $DatasetsTable get datasets => attachedDatabase.datasets;
  DatasetsDaoManager get managers => DatasetsDaoManager(this);
}

class DatasetsDaoManager {
  final _$DatasetsDaoMixin _db;
  DatasetsDaoManager(this._db);
  $$DatasetsTableTableManager get datasets =>
      $$DatasetsTableTableManager(_db.attachedDatabase, _db.datasets);
}
