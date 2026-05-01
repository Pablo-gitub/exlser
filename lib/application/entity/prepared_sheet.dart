import 'package:exel_category/domain/entities/dataset_column.dart';

/// Represents a sheet ready for user confirmation.
///
/// Contains:
/// - raw parsed rows
/// - inferred schema
class PreparedSheet {
  final String name;
  final List<Map<String, dynamic>> rows;
  final List<DatasetColumn> inferredColumns;

  const PreparedSheet({
    required this.name,
    required this.rows,
    required this.inferredColumns,
  });
}