import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/dataset_tables.dart';

part 'dataset_tables_dao.g.dart';

/// DAO responsible for accessing DatasetTables.
///
/// Each DatasetTable represents one Excel sheet
/// imported into the relational database.
@DriftAccessor(tables: [DatasetTables])
class DatasetTablesDao extends DatabaseAccessor<AppDatabase>
    with _$DatasetTablesDaoMixin {

  DatasetTablesDao(super.db);

  /// Creates a new dataset table entry.
  ///
  /// Returns the generated table id.
  Future<int> createDatasetTable({
    required int datasetId,
    required String sheetNameOriginal,
    required String sqlTableName,
    required int rowCount,
    required int colCount,
  }) {
    return into(datasetTables).insert(
      DatasetTablesCompanion.insert(
        datasetId: datasetId,
        sheetNameOriginal: sheetNameOriginal,
        sqlTableName: sqlTableName,
        rowCount: rowCount,
        colCount: colCount,
      ),
    );
  }

  /// Returns all tables belonging to a dataset.
  Future<List<DatasetTable>> getTablesForDataset(int datasetId) {
    return (select(datasetTables)
          ..where((t) => t.datasetId.equals(datasetId)))
        .get();
  }

  /// Watches tables belonging to a dataset.
  Stream<List<DatasetTable>> watchTablesForDataset(int datasetId) {
    return (select(datasetTables)
          ..where((t) => t.datasetId.equals(datasetId)))
        .watch();
  }

  /// Deletes all tables belonging to a dataset.
  Future<int> deleteTablesForDataset(int datasetId) {
    return (delete(datasetTables)
          ..where((t) => t.datasetId.equals(datasetId)))
        .go();
  }

  /// Deletes a specific table by id.
  Future<int> deleteTableById(int tableId) {
    return (delete(datasetTables)
          ..where((t) => t.id.equals(tableId)))
        .go();
  }
}