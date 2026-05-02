import 'package:exel_category/domain/entities/parsed_sheet.dart';
import 'package:exel_category/domain/entities/dataset_column.dart';

/// Represents a parsed sheet enriched with inferred schema.
///
/// This model is used in the import preparation phase,
/// before the dataset is persisted.
class PreparedSheet {
  final ParsedSheet sheet;
  final List<DatasetColumn> inferredColumns;

  const PreparedSheet({
    required this.sheet,
    required this.inferredColumns,
  });
}