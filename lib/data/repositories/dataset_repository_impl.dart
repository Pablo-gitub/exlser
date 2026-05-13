import 'package:exel_category/core/database/daos/datasets_dao.dart';
import 'package:exel_category/core/database/app_database.dart' as db;
import 'package:exel_category/domain/entities/dataset.dart' as domain;
import 'package:exel_category/domain/repositories/datasets_repository.dart';

/// Concrete implementation of [DatasetsRepository].
///
/// This repository persists dataset metadata using the Drift database.
///
/// Responsibilities:
/// - Store dataset metadata
/// - Retrieve dataset metadata
/// - Update dataset information
/// - Delete dataset records
class DatasetsRepositoryImpl implements DatasetsRepository {
  final DatasetsDao dao;

  DatasetsRepositoryImpl({
    required this.dao,
  });

  @override
  Future<List<domain.Dataset>> getAllDatasets() async {
    final rows = await dao.getAllDatasets();

    return rows.map(_mapRow).toList();
  }

  @override
  Future<domain.Dataset?> getDatasetById(int id) async {
    _validateId(id);

    final row = await dao.getDatasetById(id);

    if (row == null) return null;

    return _mapRow(row);
  }

  @override
  Future<domain.Dataset> createDataset(domain.Dataset dataset) async {
    final name = dataset.name.trim();
    final sourceFileName = dataset.sourceFileName.trim();

    if (name.isEmpty) {
      throw ArgumentError('Dataset name cannot be empty');
    }

    if (sourceFileName.isEmpty) {
      throw ArgumentError('Source file name cannot be empty');
    }

    final id = await dao.createDataset(
      name: name,
      sourceFileName: sourceFileName,
      sourceFileHash: dataset.sourceFileHash,
      createdAt: dataset.createdAt,
      lastOpenedAt: dataset.lastOpenedAt,
    );

    return dataset.copyWith(
      id: id,
      name: name,
      sourceFileName: sourceFileName,
    );
  }

  @override
  Future<void> updateDataset(domain.Dataset dataset) async {
    _validateId(dataset.id);

    final name = dataset.name.trim();
    final sourceFileName = dataset.sourceFileName.trim();

    if (name.isEmpty) {
      throw ArgumentError('Dataset name cannot be empty');
    }

    if (sourceFileName.isEmpty) {
      throw ArgumentError('Source file name cannot be empty');
    }

    final updated = await dao.updateDataset(
      id: dataset.id,
      name: name,
      sourceFileName: sourceFileName,
      sourceFileHash: dataset.sourceFileHash,
      createdAt: dataset.createdAt,
      lastOpenedAt: dataset.lastOpenedAt,
    );

    if (!updated) {
      throw StateError('Dataset not found: ${dataset.id}');
    }
  }

  @override
  Future<void> deleteDataset(int id) async {
    _validateId(id);

    await dao.deleteDatasetById(id);
  }

  @override
  Future<void> markDatasetOpened(int datasetId) async {
    _validateId(datasetId);

    final updated = await dao.updateLastOpenedAt(
      datasetId: datasetId,
      lastOpenedAt: DateTime.now().millisecondsSinceEpoch,
    );

    if (!updated) {
      throw StateError('Dataset not found: $datasetId');
    }
  }

  domain.Dataset _mapRow(db.Dataset row) {
    return domain.Dataset(
      id: row.id,
      name: row.name,
      sourceFileName: row.sourceFileName,
      sourceFileHash: row.sourceFileHash,
      createdAt: row.createdAt,
      lastOpenedAt: row.lastOpenedAt,
    );
  }

  void _validateId(int id) {
    if (id <= 0) {
      throw ArgumentError('Dataset id must be greater than 0');
    }
  }
}
