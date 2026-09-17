import 'package:exlser/domain/entities/dataset_relationship.dart';
import 'package:exlser/domain/repositories/dataset_relationship_repository.dart';
import 'package:exlser/domain/usecases/multisheet/manage_dataset_relationships_usecases.dart';
import 'package:flutter_test/flutter_test.dart';

/// Counts how often the dataset is listed, which is the point of the batch use
/// case: one listing instead of one per relationship.
class _FakeRelationshipRepository implements DatasetRelationshipRepository {
  final List<DatasetRelationship> stored;
  final Set<String> failingEndpointKeys;
  int listCallCount = 0;
  int nextId = 100;

  _FakeRelationshipRepository({
    List<DatasetRelationship>? stored,
    this.failingEndpointKeys = const {},
  }) : stored = stored ?? [];

  @override
  Future<DatasetRelationship> create(DatasetRelationship relationship) async {
    if (failingEndpointKeys.contains(relationship.endpointKey)) {
      throw Exception('write failed');
    }
    final created = relationship.copyWith(id: nextId++);
    stored.add(created);
    return created;
  }

  @override
  Future<void> deleteForDataset(int datasetId) async {}

  @override
  Future<void> deleteById(int id) async {}

  @override
  Future<DatasetRelationship?> getById(int id) async {
    for (final relationship in stored) {
      if (relationship.id == id) return relationship;
    }
    return null;
  }

  @override
  Future<List<DatasetRelationship>> listForDataset(int datasetId) async {
    listCallCount++;
    return [
      for (final relationship in stored)
        if (relationship.datasetId == datasetId) relationship,
    ];
  }

  @override
  Future<void> update(DatasetRelationship relationship) async {}
}

DatasetRelationship _rel({
  int? id,
  int aTable = 1,
  String aColumn = 'id',
  int bTable = 2,
  String bColumn = 'order_id',
}) {
  return DatasetRelationship(
    id: id,
    datasetId: 7,
    endpointATableId: aTable,
    endpointAColumnDbName: aColumn,
    endpointBTableId: bTable,
    endpointBColumnDbName: bColumn,
  );
}

void main() {
  group('CreateDatasetRelationshipsUseCase', () {
    test('creates every relationship reading the dataset only once', () async {
      final repository = _FakeRelationshipRepository();
      final useCase = CreateDatasetRelationshipsUseCase(repository: repository);

      final result = await useCase(7, [
        _rel(bTable: 2, bColumn: 'order_id'),
        _rel(bTable: 3, bColumn: 'customer_id'),
        _rel(bTable: 4, bColumn: 'product_id'),
      ]);

      expect(result.created.length, 3);
      expect(result.skipped, isEmpty);
      expect(result.failed, isEmpty);
      expect(result.hasFailures, isFalse);
      expect(repository.listCallCount, 1);
      expect(result.created.every((r) => r.id != null), isTrue);
    });

    test('skips relationships that already exist, in any endpoint order',
        () async {
      final repository = _FakeRelationshipRepository(stored: [
        _rel(id: 1, aTable: 2, aColumn: 'order_id', bTable: 1, bColumn: 'id'),
      ]);
      final useCase = CreateDatasetRelationshipsUseCase(repository: repository);

      final result = await useCase(7, [
        _rel(aTable: 1, aColumn: 'id', bTable: 2, bColumn: 'order_id'),
        _rel(bTable: 3, bColumn: 'customer_id'),
      ]);

      expect(result.skipped.length, 1);
      expect(result.created.length, 1);
      expect(result.created.single.endpointBTableId, 3);
    });

    test('deduplicates within the incoming batch', () async {
      final repository = _FakeRelationshipRepository();
      final useCase = CreateDatasetRelationshipsUseCase(repository: repository);

      final result = await useCase(7, [
        _rel(),
        _rel(),
      ]);

      expect(result.created.length, 1);
      expect(result.skipped.length, 1);
      expect(repository.stored.length, 1);
    });

    test('reports a partial save instead of failing the whole batch', () async {
      final failing = _rel(bTable: 3, bColumn: 'customer_id');
      final repository = _FakeRelationshipRepository(
        failingEndpointKeys: {failing.endpointKey},
      );
      final useCase = CreateDatasetRelationshipsUseCase(repository: repository);

      final result = await useCase(7, [
        _rel(),
        failing,
        _rel(bTable: 4, bColumn: 'product_id'),
      ]);

      expect(result.created.length, 2);
      expect(result.failed.length, 1);
      expect(result.hasFailures, isTrue);
      expect(result.requestedCount, 3);
    });

    test('rejects a self relationship without touching the repository',
        () async {
      final repository = _FakeRelationshipRepository();
      final useCase = CreateDatasetRelationshipsUseCase(repository: repository);

      final result = await useCase(7, [
        _rel(aTable: 5, bTable: 5, bColumn: 'other'),
      ]);

      expect(result.failed.length, 1);
      expect(repository.stored, isEmpty);
    });

    test('does not hit the repository for an empty batch', () async {
      final repository = _FakeRelationshipRepository();
      final useCase = CreateDatasetRelationshipsUseCase(repository: repository);

      final result = await useCase(7, const []);

      expect(result.requestedCount, 0);
      expect(repository.listCallCount, 0);
    });
  });
}
