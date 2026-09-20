//lib/domain/usecases/multisheet/manage_dataset_relationships_usecases.dart

import 'package:exlser/domain/entities/dataset_relationship.dart';
import 'package:exlser/core/diagnostics/recovered_error.dart';
import 'package:exlser/domain/repositories/dataset_relationship_repository.dart';

/// Raised when a relationship duplicates an existing one (same endpoints, any order).
class DuplicateRelationshipException implements Exception {
  final int existingId;

  const DuplicateRelationshipException(this.existingId);

  @override
  String toString() => 'DuplicateRelationshipException($existingId)';
}

/// Creates a dataset relationship, rejecting a duplicate of an existing pair.
///
/// Equivalence is by unordered endpoint pair ([DatasetRelationship.endpointKey]),
/// so A↔B swapped counts as the same relationship. Enforced in the domain, never
/// via a SQLite constraint.
class CreateDatasetRelationshipUseCase {
  final DatasetRelationshipRepository repository;
  final DateTime Function() now;

  CreateDatasetRelationshipUseCase({
    required this.repository,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  Future<DatasetRelationship> call(DatasetRelationship relationship) async {
    if (relationship.endpointATableId == relationship.endpointBTableId) {
      throw ArgumentError('A relationship must connect two different sheets');
    }

    final existing = await repository.listForDataset(relationship.datasetId);
    final duplicate = existing
        .where((r) => r.endpointKey == relationship.endpointKey)
        .firstOrNull;
    if (duplicate != null) {
      throw DuplicateRelationshipException(duplicate.id ?? -1);
    }

    return repository.create(relationship);
  }
}

/// The outcome of a batch relationship creation.
///
/// [created] holds the persisted relationships, [skipped] the ones that already
/// existed (same unordered endpoint pair), and [failed] the ones the repository
/// refused — so a caller can report a partial save instead of guessing.
class CreateDatasetRelationshipsResult {
  final List<DatasetRelationship> created;
  final List<DatasetRelationship> skipped;
  final List<DatasetRelationship> failed;

  const CreateDatasetRelationshipsResult({
    this.created = const [],
    this.skipped = const [],
    this.failed = const [],
  });

  int get requestedCount => created.length + skipped.length + failed.length;

  /// True when at least one relationship could not be persisted.
  bool get hasFailures => failed.isNotEmpty;
}

/// Creates several relationships for one dataset, reading the existing ones once.
///
/// [CreateDatasetRelationshipUseCase] re-reads the whole dataset on every call,
/// which turns a batch of N suggestions into N full listings. This use case
/// lists once and deduplicates in memory — against what is already stored and
/// within the incoming batch — then reports exactly what happened instead of
/// failing the whole batch on the first rejected row.
class CreateDatasetRelationshipsUseCase {
  final DatasetRelationshipRepository repository;

  const CreateDatasetRelationshipsUseCase({required this.repository});

  Future<CreateDatasetRelationshipsResult> call(
    int datasetId,
    List<DatasetRelationship> relationships,
  ) async {
    if (relationships.isEmpty) {
      return const CreateDatasetRelationshipsResult();
    }

    final existing = await repository.listForDataset(datasetId);
    final knownKeys = {for (final r in existing) r.endpointKey};

    final created = <DatasetRelationship>[];
    final skipped = <DatasetRelationship>[];
    final failed = <DatasetRelationship>[];

    for (final relationship in relationships) {
      if (relationship.endpointATableId == relationship.endpointBTableId) {
        failed.add(relationship);
        continue;
      }
      if (!knownKeys.add(relationship.endpointKey)) {
        skipped.add(relationship);
        continue;
      }

      try {
        created.add(await repository.create(relationship));
      } catch (error, stackTrace) {
        recordRecoveredError(error, stackTrace,
            context: 'CreateDatasetRelationshipsUseCase');
        knownKeys.remove(relationship.endpointKey);
        failed.add(relationship);
      }
    }

    return CreateDatasetRelationshipsResult(
      created: created,
      skipped: skipped,
      failed: failed,
    );
  }
}

/// Lists a dataset's relationships (oldest first).
class ListDatasetRelationshipsUseCase {
  final DatasetRelationshipRepository repository;

  const ListDatasetRelationshipsUseCase({required this.repository});

  Future<List<DatasetRelationship>> call(int datasetId) =>
      repository.listForDataset(datasetId);
}

/// Loads a single relationship.
class LoadDatasetRelationshipUseCase {
  final DatasetRelationshipRepository repository;

  const LoadDatasetRelationshipUseCase({required this.repository});

  Future<DatasetRelationship?> call(int id) => repository.getById(id);
}

/// Updates a relationship's metadata (cardinality, confidences, confirmation).
///
/// Endpoints are identity: changing them would silently repoint saved queries,
/// so a different pair must be created as a new relationship, not edited here.
class UpdateDatasetRelationshipUseCase {
  final DatasetRelationshipRepository repository;
  final DateTime Function() now;

  UpdateDatasetRelationshipUseCase({
    required this.repository,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  Future<DatasetRelationship> call(DatasetRelationship relationship) async {
    final id = relationship.id;
    if (id == null) {
      throw ArgumentError('Cannot update a relationship without an id');
    }
    final existing = await repository.getById(id);
    if (existing == null) {
      throw StateError('Relationship $id no longer exists');
    }
    if (existing.endpointKey != relationship.endpointKey) {
      throw ArgumentError(
        'Endpoints are immutable; create a new relationship instead',
      );
    }
    await repository.update(relationship);
    return relationship;
  }
}
