import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/value_objects/column_type.dart';

/// Responsible for generating dynamic SQL table definitions
/// from dataset schema metadata.
///
/// This component converts domain column metadata into
/// SQLite-compatible CREATE TABLE statements.
///
/// Responsibilities:
/// - Translate ColumnType into SQLite types
/// - Generate CREATE TABLE SQL
/// - Generate consistent SQL-safe schema definitions
class DynamicTableBuilder {
  const DynamicTableBuilder();

  /// Builds a CREATE TABLE SQL statement.
  String buildCreateTableSql({
    required String tableName,
    required List<DatasetColumn> columns,
  }) {
    if (columns.isEmpty) {
      throw Exception(
        'Cannot generate table without columns',
      );
    }

    final columnDefinitions = columns.map((column) {
      final sqlType = _mapColumnType(
        column.declaredType,
      );

      final nullable = column.nullable ? '' : ' NOT NULL';

      return '${column.dbName} $sqlType$nullable';
    }).join(', ');

    return '''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnDefinitions
      )
    ''';
  }

  /// Maps domain column types to SQLite types.
  String _mapColumnType(ColumnType type) {
    switch (type) {
      case ColumnType.text:
        return 'TEXT';

      case ColumnType.integer:
        return 'INTEGER';

      case ColumnType.real:
        return 'REAL';

      case ColumnType.boolean:
        return 'INTEGER';

      case ColumnType.date:
        return 'TEXT';
    }
  }
}
