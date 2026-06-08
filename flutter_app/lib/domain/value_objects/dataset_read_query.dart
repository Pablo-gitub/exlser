class DatasetReadQuery {
  static const int defaultLimit = 100;
  static const String defaultQueryText = 'SELECT *\nFROM sheet';

  final String sql;
  final int limit;

  const DatasetReadQuery({
    this.sql = defaultQueryText,
    this.limit = defaultLimit,
  });

  DatasetReadQuery copyWith({
    String? sql,
    int? limit,
  }) {
    return DatasetReadQuery(
      sql: sql ?? this.sql,
      limit: limit ?? this.limit,
    );
  }

  bool get hasSql => sql.trim().isNotEmpty;
}
