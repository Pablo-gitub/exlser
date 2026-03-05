//lib/domain/entities/dataset.dart

/// Domain entity representing a dataset imported into the system.
///
/// A dataset corresponds to one Excel file import session.
class Dataset {
  final int id;
  final String name;
  final String sourceFileName;
  final String? sourceFileHash;
  final int createdAt;
  final int? lastOpenedAt;

  const Dataset({
    required this.id,
    required this.name,
    required this.sourceFileName,
    this.sourceFileHash,
    required this.createdAt,
    this.lastOpenedAt,
  });

  Dataset copyWith({
    int? id,
    String? name,
    String? sourceFileName,
    String? sourceFileHash,
    int? createdAt,
    int? lastOpenedAt,
  }) {
    return Dataset(
      id: id ?? this.id,
      name: name ?? this.name,
      sourceFileName: sourceFileName ?? this.sourceFileName,
      sourceFileHash: sourceFileHash ?? this.sourceFileHash,
      createdAt: createdAt ?? this.createdAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
    );
  }

  bool get wasOpened => lastOpenedAt != null;
}