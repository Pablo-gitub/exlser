//lib/domain/value_objects/column_type.dart

/// Value object representing supported column data types.
enum ColumnType {
  text,
  integer,
  real,
  boolean,
  date;

  /// Factory method to create a ColumnType from a string representation.
  static ColumnType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'TEXT':
        return ColumnType.text;
      case 'INTEGER':
        return ColumnType.integer;
      case 'REAL':
        return ColumnType.real;
      case 'BOOLEAN':
        return ColumnType.boolean;
      case 'DATE':
        return ColumnType.date;
      default:
        return ColumnType.text;
    }
  }

  /// Converts the ColumnType to its corresponding SQL type as a string.
  String toSqlType() {
    switch (this) {
      case ColumnType.text:
        return 'TEXT';
      case ColumnType.integer:
        return 'INTEGER';
      case ColumnType.real:
        return 'REAL';
      case ColumnType.boolean:
        return 'BOOLEAN';
      case ColumnType.date:
        return 'DATE';
    }
  }
}